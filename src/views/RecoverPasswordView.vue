<template>
  <main class="section">
    <div class="wrap card box">
      <img src="/brand/buck.svg" width="72" height="80" alt="Buck" />
      <h1>{{ heading }}</h1>
      <p class="admin-note">{{ subtitle }}</p>

      <p v-if="!hasSupabase" class="warn">
        Faltan <code>VITE_SUPABASE_URL</code> y <code>VITE_SUPABASE_ANON_KEY</code>.
      </p>

      <template v-else-if="phase === 'request'">
        <form class="form" @submit.prevent="onRequest">
          <label class="field">
            <span class="field-label">Correo de la cuenta</span>
            <input
              v-model="email"
              class="input"
              type="email"
              autocomplete="email"
              required
            />
          </label>
          <p v-if="error" class="error">{{ error }}</p>
          <p v-if="info" class="ok">{{ info }}</p>
          <button class="btn btn-lime" type="submit" :disabled="busy">
            Enviar enlace
          </button>
        </form>
      </template>

      <template v-else-if="phase === 'update'">
        <form class="form" @submit.prevent="onUpdate">
          <label class="field">
            <span class="field-label">Nueva contraseña</span>
            <input
              v-model="password"
              class="input"
              type="password"
              autocomplete="new-password"
              minlength="8"
              required
            />
          </label>
          <label class="field">
            <span class="field-label">Confirmar contraseña</span>
            <input
              v-model="password2"
              class="input"
              type="password"
              autocomplete="new-password"
              minlength="8"
              required
            />
          </label>
          <p v-if="error" class="error">{{ error }}</p>
          <button class="btn btn-lime" type="submit" :disabled="busy">
            Guardar contraseña
          </button>
        </form>
      </template>

      <template v-else>
        <p class="ok">{{ info }}</p>
        <a class="btn btn-lime link-btn" :href="appLoginUrl">
          Abrir Terra Liam
        </a>
        <p class="back">
          <router-link to="/admin/login">Entrar al CMS (web)</router-link>
        </p>
      </template>

      <p v-if="phase !== 'done'" class="back">
        <a v-if="phase === 'update'" class="app-link" :href="appResetUrl">Abrir en la app</a>
        <span v-if="phase === 'update'"> · </span>
        <router-link to="/admin/login">Volver al login web</router-link>
      </p>
    </div>
  </main>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useAdminSession } from '@/admin/useAdminSession'

const { hasSupabase, requestPasswordReset, updatePassword, watchPasswordRecovery } =
  useAdminSession()

/** @type {import('vue').Ref<'request' | 'update' | 'done'>} */
const phase = ref('request')
const email = ref('')
const password = ref('')
const password2 = ref('')
const error = ref('')
const info = ref('')
const busy = ref(false)

let stopWatch = () => {}

const APP_LOGIN = 'terraliam://login'
const APP_RESET = 'terraliam://reset-password'

const appLoginUrl = APP_LOGIN
const appResetUrl = computed(
  () => `${APP_RESET}${window.location.search || ''}${window.location.hash || ''}`,
)

function openApp(url) {
  window.location.href = url
}

const heading = computed(() => {
  if (phase.value === 'update') return 'Nueva contraseña'
  if (phase.value === 'done') return 'Listo'
  return 'Recuperar contraseña'
})

const subtitle = computed(() => {
  if (phase.value === 'update') {
    return 'Elige una contraseña nueva para tu cuenta de adulto (mínimo 8 caracteres).'
  }
  if (phase.value === 'done') {
    return 'Ya puedes entrar en la app Terra Liam con la contraseña nueva.'
  }
  return 'Te enviamos un enlace al correo. Ábrelo en el teléfono para volver a la app, o continúa aquí.'
})

onMounted(() => {
  stopWatch = watchPasswordRecovery(() => {
    phase.value = 'update'
    error.value = ''
    info.value = ''
  })
})

onUnmounted(() => {
  stopWatch()
})

async function onRequest() {
  error.value = ''
  info.value = ''
  busy.value = true
  try {
    await requestPasswordReset(email.value.trim())
    info.value =
      'Si ese correo tiene cuenta, te llegó un enlace. Revisa también spam.'
  } catch (err) {
    error.value = err.message ?? 'No se pudo enviar el enlace.'
  } finally {
    busy.value = false
  }
}

async function onUpdate() {
  error.value = ''
  if (password.value !== password2.value) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }
  if (password.value.length < 8) {
    error.value = 'Usa al menos 8 caracteres.'
    return
  }
  busy.value = true
  try {
    await updatePassword(password.value)
    phase.value = 'done'
    info.value = 'Contraseña actualizada. Abriendo Terra Liam…'
    openApp(APP_LOGIN)
  } catch (err) {
    error.value = err.message ?? 'No se pudo guardar la contraseña.'
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

.ok {
  color: var(--teal-deep);
  font-weight: 800;
}

.btn {
  width: 100%;
  margin-top: 1rem;
}

.link-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
}

.back {
  margin-top: 1.4rem;
  font-weight: 800;
}

.app-link {
  color: var(--teal-deep);
  font-weight: 800;
}
</style>
