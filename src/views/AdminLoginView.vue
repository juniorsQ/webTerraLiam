<template>
  <main class="section">
    <div class="wrap card box">
      <img src="/brand/buck.svg" width="72" height="80" alt="Buck" />
      <h1>CMS TerraLiam</h1>
      <p class="admin-note">
        Entra con el usuario de Supabase Auth (email y contraseña). El primer admin se crea en el dashboard del proyecto.
      </p>
      <p v-if="!hasSupabase" class="warn">
        Faltan <code>VITE_SUPABASE_URL</code> y <code>VITE_SUPABASE_ANON_KEY</code> en
        <code>.env.local</code>.
      </p>
      <form v-else class="form" @submit.prevent="onSubmit">
        <label class="field">
          <span class="field-label">Correo</span>
          <input v-model="email" class="input" type="email" autocomplete="username" required />
        </label>
        <label class="field">
          <span class="field-label">Contraseña</span>
          <input
            v-model="password"
            class="input"
            type="password"
            autocomplete="current-password"
            required
          />
        </label>
        <p v-if="error" class="error">{{ error }}</p>
        <button class="btn btn-lime" type="submit" :disabled="busy">Entrar</button>
        <p class="forgot">
          <router-link to="/recuperar">¿Olvidaste tu contraseña?</router-link>
        </p>
      </form>
    </div>
  </main>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminSession } from '@/admin/useAdminSession'

const router = useRouter()
const { hasSupabase, refresh, session, signIn } = useAdminSession()
const email = ref('')
const password = ref('')
const error = ref('')
const busy = ref(false)

onMounted(async () => {
  await refresh()
  if (session.value) router.replace('/admin')
})

async function onSubmit() {
  error.value = ''
  busy.value = true
  try {
    await signIn(email.value, password.value)
    router.replace('/admin')
  } catch (err) {
    error.value = err.message ?? 'No se pudo entrar.'
  } finally {
    busy.value = false
  }
}
</script>

<style scoped>
.box {
  max-width: 480px;
  margin-inline: auto;
  padding: 2rem 1.4rem;
  text-align: center;
}

img {
  margin: 0 auto 0.6rem;
}

h1 {
  color: var(--ink);
  font-size: 2rem;
}

.form {
  text-align: left;
  margin-top: 1.2rem;
}

.error,
.warn {
  color: #c2410c;
  font-weight: 800;
}

.btn {
  width: 100%;
  margin-top: 1rem;
}

.forgot {
  margin-top: 1rem;
  text-align: center;
  font-weight: 800;
}
</style>
