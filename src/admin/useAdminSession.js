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

  return { session, ready, hasSupabase, refresh, signIn, signOut }
}
