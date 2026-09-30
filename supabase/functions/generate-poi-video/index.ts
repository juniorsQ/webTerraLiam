import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const DEFAULT_MODEL = 'fal-ai/kling-video/v2.1/standard/image-to-video'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const anon = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const authHeader = req.headers.get('Authorization') ?? ''
    const userClient = createClient(supabaseUrl, anon, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: userData, error: userError } = await userClient.auth.getUser()
    if (userError || !userData.user) {
      return json({ error: 'Debes iniciar sesión.' }, 401)
    }

    const body = await req.json() as Record<string, unknown>
    const action = String(body.action ?? 'start')

    if (action === 'poll') {
      return await pollJob(userClient, supabaseUrl, body, userData.user.id)
    }
    return await startJob(userClient, supabaseUrl, body)
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : 'No se pudo generar el video.',
      status: 'error',
    }, 500)
  }
})

async function startJob(
  userClient: ReturnType<typeof createClient>,
  supabaseUrl: string,
  body: Record<string, unknown>,
) {
  const worldId = String(body.world_id ?? '')
  const poiId = String(body.poi_id ?? '')
  const imageUrl = String(body.image_url ?? '')
  const regenerate = Boolean(body.regenerate)
  if (!worldId || !poiId || !imageUrl) {
    return json({ error: 'Faltan world_id, poi_id o image_url.' }, 400)
  }

  const { data: jobRaw, error: jobError } = await userClient.rpc('request_video_generation', {
    p_world_id: worldId,
    p_poi_id: poiId,
    p_regenerate: regenerate,
    p_require_prize_credit: false,
  })
  if (jobError) {
    return json({ error: jobError.message, status: 'blocked' }, 400)
  }
  const job = (Array.isArray(jobRaw) ? jobRaw[0] : jobRaw) as { id: string }
  if (!job?.id) {
    return json({ error: 'No se pudo crear el trabajo de video.', status: 'error' }, 500)
  }

  const admin = createAdminClient(supabaseUrl)
  const falKey = await readSecret(admin, ['FAL_KEY'])
  if (!falKey) {
    await admin.from('video_generation_jobs').update({
      status: 'failed',
      error: 'FAL_KEY no configurada en el servidor.',
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    return json({ error: 'Video IA no configurado en el servidor.', status: 'error' }, 500)
  }

  const model = Deno.env.get('FAL_VIDEO_MODEL') || DEFAULT_MODEL
  const prompt = buildPrompt(body)
  const negative = negativePrompt()

  const submit = await fetch(`https://queue.fal.run/${model}`, {
    method: 'POST',
    headers: {
      Authorization: `Key ${falKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      image_url: imageUrl,
      duration: '5',
      negative_prompt: negative,
      cfg_scale: 0.55,
    }),
  })

  if (!submit.ok) {
    const detail = await submit.text()
    await admin.from('video_generation_jobs').update({
      status: 'failed',
      error: `fal submit ${submit.status}: ${detail.slice(0, 400)}`,
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    return json({ error: 'No se pudo enviar el video a Fal.', status: 'error' }, 502)
  }

  const submitted = await submit.json() as Record<string, unknown>
  const requestId = String(submitted.request_id ?? '')
  const statusUrl = String(submitted.status_url ?? '')
  const responseUrl = String(submitted.response_url ?? '')
  if (!requestId) {
    await admin.from('video_generation_jobs').update({
      status: 'failed',
      error: 'fal: sin request_id',
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    return json({ error: 'Respuesta incompleta de Fal.', status: 'error' }, 502)
  }

  await admin.from('video_generation_jobs').update({
    status: 'processing',
    fal_request_id: requestId,
    fal_status_url: statusUrl || null,
    fal_response_url: responseUrl || null,
  }).eq('id', job.id)

  return json({
    status: 'processing',
    job_id: job.id,
    fal_request_id: requestId,
    message: 'Video en cola. Suele tardar 1–3 minutos.',
  })
}

async function pollJob(
  userClient: ReturnType<typeof createClient>,
  supabaseUrl: string,
  body: Record<string, unknown>,
  userId: string,
) {
  const jobId = String(body.job_id ?? '')
  if (!jobId) return json({ error: 'Falta job_id.' }, 400)

  const { data: job, error } = await userClient
    .from('video_generation_jobs')
    .select('*')
    .eq('id', jobId)
    .maybeSingle()
  if (error || !job) {
    return json({ error: 'Trabajo no encontrado.' }, 404)
  }
  if (job.requested_by !== userId) {
    return json({ error: 'Acceso restringido.' }, 403)
  }

  if (job.status === 'completed' && job.video_url) {
    return json({ status: 'ready', job_id: job.id, video_url: job.video_url })
  }
  if (job.status === 'failed' || job.status === 'cancelled') {
    return json({ status: 'error', job_id: job.id, error: job.error ?? 'Falló la generación.' })
  }

  const admin = createAdminClient(supabaseUrl)
  const falKey = await readSecret(admin, ['FAL_KEY'])
  if (!falKey) {
    return json({ error: 'FAL_KEY no configurada.', status: 'error' }, 500)
  }

  const model = Deno.env.get('FAL_VIDEO_MODEL') || DEFAULT_MODEL
  const statusEndpoint = job.fal_status_url
    || `https://queue.fal.run/${model}/requests/${job.fal_request_id}/status`
  const resultEndpoint = job.fal_response_url
    || `https://queue.fal.run/${model}/requests/${job.fal_request_id}`

  const st = await fetch(statusEndpoint, {
    headers: { Authorization: `Key ${falKey}`, Accept: 'application/json' },
  })
  if (!st.ok) {
    return json({ status: 'processing', job_id: job.id, message: 'Esperando a Fal…' })
  }

  const statusBody = await st.json() as Record<string, unknown>
  const status = String(statusBody.status ?? '').toUpperCase()

  if (status === 'FAILED' || status === 'CANCELLED') {
    await admin.from('video_generation_jobs').update({
      status: 'failed',
      error: JSON.stringify(statusBody).slice(0, 500),
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    return json({ status: 'error', job_id: job.id, error: 'Fal falló al generar el video.' })
  }

  if (status !== 'COMPLETED') {
    return json({
      status: 'processing',
      job_id: job.id,
      fal_status: status,
      queue_position: statusBody.queue_position ?? null,
      message: status === 'IN_PROGRESS' ? 'Buck está animando el personaje…' : 'En cola…',
    })
  }

  const res = await fetch(resultEndpoint, {
    headers: { Authorization: `Key ${falKey}`, Accept: 'application/json' },
  })
  if (!res.ok) {
    return json({ status: 'processing', job_id: job.id, message: 'Descargando resultado…' })
  }
  const data = await res.json() as Record<string, unknown>
  const video = data.video as { url?: string } | undefined
  const videoUrl = video?.url
  if (!videoUrl) {
    await admin.from('video_generation_jobs').update({
      status: 'failed',
      error: 'fal: respuesta sin video.url',
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    return json({ status: 'error', job_id: job.id, error: 'Respuesta incompleta de Fal.' })
  }

  await admin.from('pois').update({ anim_video_url: videoUrl }).eq('id', job.poi_id)
  await admin.from('video_generation_jobs').update({
    status: 'completed',
    video_url: videoUrl,
    completed_at: new Date().toISOString(),
    error: null,
  }).eq('id', job.id)

  return json({
    status: 'ready',
    job_id: job.id,
    video_url: videoUrl,
    message: '¡Tu premio de video está listo!',
  })
}

function buildPrompt(body: Record<string, unknown>) {
  const name = String(body.character_name ?? 'the hero').trim() || 'the hero'
  const identity = String(body.character_identity ?? name).trim() || name
  const motion = String(body.signature_motion ?? '').trim()
    || 'The hero gives a friendly little bounce, then a big happy wave toward the camera, eyes sparkling.'
  const hint = String(body.scene_hint ?? body.description ?? '').trim()
  const env = hint
    ? `Background world inspired by "${hint}" comes alive with soft wind and light sparkles.`
    : 'Background: sunny adventure park world with soft wind in grass and trees.'
  return `${identity} stays identical to the reference image `
    + `(same face, colors, outfit, silhouette). `
    + `${motion} `
    + `Camera: slow push-in, steady, slight parallax. `
    + `${env} `
    + 'Wholesome kids adventure energy for ages 3 to 15, playful and brave, '
    + 'battle poses OK but no blood, no killing, no sadism, no adult themes, '
    + 'smooth natural motion, no text or logos.'
}

function negativePrompt() {
  return 'morphing face, melting face, identity change, different character, '
    + 'warped hands, extra fingers, extra limbs, deformed body, '
    + 'blur, flicker, jitter, low quality, distorted, '
    + 'text, watermark, logo, subtitle, UI, '
    + 'horror, gore, blood, murder, killing, sadism, torture, '
    + 'nsfw, adult, sexy, romance, kissing, drugs, smoking, '
    + 'empty void, white backdrop, green screen, floating in nothing, '
    + 'static freeze frame, shaky cam, dark gritty'
}

function createAdminClient(supabaseUrl: string) {
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (legacy) return createClient(supabaseUrl, legacy)
  const raw = Deno.env.get('SUPABASE_SECRET_KEYS') ?? ''
  if (raw) {
    const parsed = JSON.parse(raw) as Record<string, string>
    const key = parsed.default ?? Object.values(parsed)[0]
    if (key) return createClient(supabaseUrl, key)
  }
  throw new Error('Falta la clave de servicio.')
}

async function readSecret(admin: ReturnType<typeof createClient>, names: string[]) {
  for (const name of names) {
    const fromEnv = Deno.env.get(name)
    if (fromEnv) return fromEnv
    const { data, error } = await admin.rpc('ops_provider_secret', { p_name: name })
    if (!error && typeof data === 'string' && data.length > 0) return data
  }
  return ''
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
