import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabase = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )

    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || userData.user?.app_metadata?.platform_admin !== true) {
      return json({ error: 'Acceso restringido.' }, 401)
    }

    const admin = createAdminClient(supabaseUrl)
    const falKey = await readSecret(admin, ['FAL_KEY'])
    const recraftKey = await readSecret(admin, ['RECRAFT_API_TOKEN', 'RECRAFT_API_KEY'])

    const [fal, recraft] = await Promise.all([
      falKey ? readFal(falKey) : Promise.resolve({ configured: false, available: null }),
      recraftKey ? readRecraft(recraftKey) : Promise.resolve({ configured: false, available: null }),
    ])

    return json({ fal, recraft })
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : 'No se pudieron leer los créditos.' }, 500)
  }
})

function createAdminClient(supabaseUrl: string) {
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (legacy) return createClient(supabaseUrl, legacy)

  const raw = Deno.env.get('SUPABASE_SECRET_KEYS') ?? ''
  if (raw) {
    const parsed = JSON.parse(raw) as Record<string, string>
    const key = parsed.default ?? Object.values(parsed)[0]
    if (key) return createClient(supabaseUrl, key)
  }

  throw new Error('Falta la clave de servicio para leer secretos.')
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

async function readFal(key: string) {
  const response = await fetch('https://api.fal.ai/v1/account/billing?expand=credits', {
    headers: { Authorization: `Key ${key}`, Accept: 'application/json' },
  })
  if (!response.ok) return { configured: true, available: null, error: 'fal' }
  const payload = await response.json()
  return {
    configured: true,
    available: Number(payload?.credits?.current_balance ?? null),
    currency: payload?.credits?.currency ?? 'USD',
  }
}

async function readRecraft(key: string) {
  const response = await fetch('https://external.api.recraft.ai/v1/users/me', {
    headers: { Authorization: `Bearer ${key}`, Accept: 'application/json' },
  })
  if (!response.ok) return { configured: true, available: null, error: 'recraft' }
  const payload = await response.json()
  return {
    configured: true,
    available: Number(payload?.credits ?? null),
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
