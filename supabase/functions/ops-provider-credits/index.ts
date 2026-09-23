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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )

    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || userData.user?.app_metadata?.platform_admin !== true) {
      return json({ error: 'Acceso restringido.' }, 401)
    }

    const falKey = Deno.env.get('FAL_KEY') ?? ''
    const recraftKey = Deno.env.get('RECRAFT_API_TOKEN') ?? Deno.env.get('RECRAFT_API_KEY') ?? ''

    const [fal, recraft] = await Promise.all([
      falKey ? readFal(falKey) : Promise.resolve({ configured: false, available: null }),
      recraftKey ? readRecraft(recraftKey) : Promise.resolve({ configured: false, available: null }),
    ])

    return json({ fal, recraft })
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : 'No se pudieron leer los créditos.' }, 500)
  }
})

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
