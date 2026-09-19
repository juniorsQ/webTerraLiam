import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anon = import.meta.env.VITE_SUPABASE_ANON_KEY

export const hasSupabase = Boolean(url && anon)

export const supabase = hasSupabase
  ? createClient(url, anon, {
      auth: {
        detectSessionInUrl: true,
        // Recovery emails from Supabase often land with #access_token=…&type=recovery
        // (implicit). Do not force PKCE-only or those links will not establish a session.
      },
    })
  : null
