import { ref } from 'vue'
import { hasSupabase, supabase } from '@/lib/supabase'

const session = ref(null)
const ready = ref(false)

export function useOpsSession() {
  async function refresh() {
    if (!hasSupabase) {
      session.value = null
      ready.value = true
      return
    }
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    ready.value = true
  }

  function isPlatformAdmin(next = session.value) {
    return next?.user?.app_metadata?.platform_admin === true
  }

  async function signIn(email, password) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    await refresh()
  }

  async function signOut() {
    await supabase.auth.signOut()
    session.value = null
  }

  return { session, ready, hasSupabase, refresh, isPlatformAdmin, signIn, signOut }
}
