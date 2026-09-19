import { ref } from 'vue'
import { hasSupabase, supabase } from '@/lib/supabase'

const session = ref(null)
const ready = ref(false)
let subscribed = false

export function useAdminSession() {
  async function refresh() {
    if (!hasSupabase) {
      session.value = null
      ready.value = true
      return
    }
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    ready.value = true
    if (!subscribed) {
      subscribed = true
      supabase.auth.onAuthStateChange((_event, next) => {
        session.value = next
      })
    }
  }

  async function signIn(email, password) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  /** Sends the recovery email. redirectTo must be allowlisted in Supabase Auth. */
  async function requestPasswordReset(email) {
    if (!supabase) throw new Error('Supabase no configurado')
    const redirectTo = `${window.location.origin}/recuperar`
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo,
    })
    if (error) throw error
  }

  async function updatePassword(password) {
    if (!supabase) throw new Error('Supabase no configurado')
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw error
  }

  /**
   * Invokes [onRecovery] when the user lands from a recovery email link.
   * Returns an unsubscribe function.
   */
  function watchPasswordRecovery(onRecovery) {
    if (!supabase) return () => {}
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') onRecovery()
    })
    // Hash may already be consumed; check query/hash type=recovery as fallback.
    const hash = window.location.hash || ''
    const search = window.location.search || ''
    if (
      hash.includes('type=recovery') ||
      search.includes('type=recovery')
    ) {
      onRecovery()
    }
    return () => subscription.unsubscribe()
  }

  return {
    session,
    ready,
    hasSupabase,
    refresh,
    signIn,
    signOut,
    requestPasswordReset,
    updatePassword,
    watchPasswordRecovery,
  }
}
