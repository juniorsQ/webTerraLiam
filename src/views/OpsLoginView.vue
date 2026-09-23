<template>
  <main class="section">
    <div class="wrap card box">
      <p class="eyebrow">TerraLiam Ops</p>
      <h1>Backoffice del producto</h1>
      <p class="admin-note">Acceso exclusivo para el dueño de la plataforma.</p>
      <p v-if="!hasSupabase" class="error">Falta configurar Supabase.</p>
      <form v-else class="form" @submit.prevent="submit">
        <label class="field"><span class="field-label">Correo</span><input v-model="email" class="input" type="email" required /></label>
        <label class="field"><span class="field-label">Contraseña</span><input v-model="password" class="input" type="password" required /></label>
        <p v-if="error" class="error">{{ error }}</p>
        <button class="btn btn-lime" :disabled="busy">Entrar a Ops</button>
      </form>
    </div>
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
.box { max-width: 480px; margin-inline: auto; padding: 2rem 1.4rem; }
.form { margin-top: 1.2rem; }
.field + .field { margin-top: 1rem; }
.btn { width: 100%; margin-top: 1rem; }
.error { color: #c2410c; font-weight: 800; }
</style>
