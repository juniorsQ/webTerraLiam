<template>
  <main class="login-shell">
    <div class="login-grid" />
    <section class="login-brand">
      <router-link class="brand" to="/ops"><img src="/brand/app_icon.png" alt="" /><span><strong>TerraLiam</strong><small>OPS CONTROL</small></span></router-link>
      <p class="kicker">PLATFORM ACCESS</p>
      <h1>Mission<br /><em>control.</em></h1>
      <p>Supervisa mundos, exploradores y señales de juego desde un solo lugar.</p>
      <div class="login-signal"><i /><i /><i /><i /><i /><i /><i /></div>
    </section>
    <section class="login-panel">
      <div class="panel-top"><span>SECURE GATEWAY</span><span><i /> ONLINE</span></div>
      <h2>Entrar a Ops</h2>
      <p class="subcopy">Usa tu cuenta de administrador de plataforma.</p>
      <p v-if="!hasSupabase" class="error">Falta configurar Supabase.</p>
      <form v-else class="form" @submit.prevent="submit">
        <label class="field"><span>Correo</span><input v-model="email" class="input" type="email" autocomplete="email" required /></label>
        <label class="field"><span>Contraseña</span><input v-model="password" class="input" type="password" autocomplete="current-password" required /></label>
        <p v-if="error" class="error">{{ error }}</p>
        <button class="login-button" :disabled="busy">{{ busy ? 'Verificando...' : 'Entrar a Ops' }} <span>↗</span></button>
      </form>
      <p class="security-note"><span>+</span> Acceso restringido a platform admins</p>
    </section>
  </main>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useOpsSession } from '@/ops/useOpsSession'

const router = useRouter()
const { hasSupabase, refresh, session, isPlatformAdmin, signIn } = useOpsSession()
const email = ref('')
const password = ref('')
const error = ref('')
const busy = ref(false)

onMounted(async () => {
  await refresh()
  if (isPlatformAdmin()) router.replace('/ops')
})

async function submit() {
  busy.value = true
  error.value = ''
  try {
    await signIn(email.value, password.value)
    if (!isPlatformAdmin(session.value)) throw new Error('Esta cuenta no tiene permisos de platform admin.')
    router.replace('/ops')
  } catch (err) {
    error.value = err.message ?? 'No se pudo iniciar sesión.'
  } finally {
    busy.value = false
  }
}
</script>

<style scoped>
.login-shell { --ops-bg: #0b1020; --ops-panel: #121a2d; --ops-line: rgba(151,168,204,.16); --ops-text: #eef3ff; --ops-muted: #8e9bb7; --ops-cyan: #56d7ed; --ops-lime: #b8e85c; --ops-coral: #ff7c78; min-height: 100vh; display: grid; grid-template-columns: 1fr minmax(360px, 460px); gap: clamp(2rem, 10vw, 10rem); align-items: center; padding: clamp(1.5rem, 6vw, 5rem); overflow: hidden; position: relative; background: radial-gradient(circle at 20% 30%, rgba(72,93,174,.28), transparent 34%), var(--ops-bg); color: var(--ops-text); font-family: var(--font-body); }.login-grid { position: absolute; inset: 0; opacity: .16; pointer-events: none; background-image: linear-gradient(rgba(86,215,237,.08) 1px, transparent 1px), linear-gradient(90deg, rgba(86,215,237,.08) 1px, transparent 1px); background-size: 42px 42px; mask-image: linear-gradient(90deg, black, transparent 80%); }.login-brand, .login-panel { position: relative; z-index: 1; }.login-brand { max-width: 560px; padding-left: clamp(0rem, 6vw, 5rem); }.brand { display: flex; align-items: center; gap: .7rem; width: fit-content; margin-bottom: clamp(3rem, 12vh, 8rem); color: var(--ops-text); text-decoration: none; }.brand img { width: 42px; height: 42px; border-radius: 13px; }.brand span { display: grid; gap: .12rem; }.brand strong { font-family: var(--font-display); font-size: 1.2rem; }.brand small { color: var(--ops-muted); font-size: .62rem; letter-spacing: .13em; }.kicker, .panel-top { color: var(--ops-cyan); font-size: .65rem; font-weight: 900; letter-spacing: .14em; }.login-brand h1 { margin: .8rem 0 1.1rem; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(3.8rem, 8vw, 7rem); line-height: .83; }.login-brand h1 em { color: var(--ops-cyan); font-style: normal; }.login-brand > p:last-of-type { max-width: 29rem; color: var(--ops-muted); font-size: 1rem; }.login-signal { display: flex; align-items: center; gap: 4px; margin-top: 2rem; }.login-signal i { width: 5px; height: 9px; border-radius: 4px; background: var(--ops-cyan); }.login-signal i:nth-child(2), .login-signal i:nth-child(6) { height: 16px; }.login-signal i:nth-child(3), .login-signal i:nth-child(5) { height: 12px; }.login-signal i:nth-child(4) { height: 22px; }.login-panel { padding: clamp(1.5rem, 4vw, 2.4rem); border: 1px solid var(--ops-line); border-radius: 14px; background: rgba(18,26,45,.9); box-shadow: 0 24px 80px rgba(0,0,0,.22); }.panel-top { display: flex; justify-content: space-between; gap: 1rem; padding-bottom: 1.2rem; border-bottom: 1px solid var(--ops-line); font-size: .58rem; }.panel-top span:last-child { color: var(--ops-lime); }.panel-top i { display: inline-block; width: 6px; height: 6px; margin-right: .3rem; border-radius: 50%; background: var(--ops-lime); }.login-panel h2 { margin: 2.3rem 0 .35rem; color: var(--ops-text); font-family: var(--font-display); font-size: 2rem; }.subcopy, .security-note { color: var(--ops-muted); font-size: .78rem; }.form { margin-top: 2rem; }.field { display: grid; gap: .45rem; }.field + .field { margin-top: 1rem; }.field span { color: var(--ops-muted); font-size: .7rem; }.input { width: 100%; min-height: 48px; padding: .7rem .85rem; border: 1px solid var(--ops-line); border-radius: 7px; outline: none; background: #0d1527; color: var(--ops-text); font: inherit; }.input:focus { border-color: var(--ops-cyan); box-shadow: 0 0 0 3px rgba(86,215,237,.1); }.login-button { display: flex; align-items: center; justify-content: space-between; width: 100%; min-height: 50px; margin-top: 1.4rem; padding: .7rem 1rem; border: 0; border-radius: 7px; color: #09101d; background: var(--ops-cyan); font: inherit; font-weight: 900; cursor: pointer; }.login-button:disabled { opacity: .6; cursor: wait; }.login-button span { font-size: 1.1rem; }.security-note { display: flex; align-items: center; gap: .45rem; margin: 2.2rem 0 0; padding-top: 1rem; border-top: 1px solid var(--ops-line); }.security-note span { color: var(--ops-cyan); }.error { color: var(--ops-coral); font-size: .78rem; font-weight: 800; }
@media (max-width: 760px) { .login-shell { grid-template-columns: 1fr; gap: 2rem; padding: 1.3rem; }.brand { margin-bottom: 3rem; }.login-brand { padding: 0; }.login-brand h1 { font-size: clamp(3.5rem, 18vw, 6rem); }.login-panel { max-width: 520px; width: 100%; }.login-grid { mask-image: none; } }
</style>
