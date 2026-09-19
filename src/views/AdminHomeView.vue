<template>
  <main class="section">
    <div class="wrap">
      <header class="head">
        <div>
          <h1>Secciones de la home</h1>
          <p class="admin-note">
            Cada bloque de la landing es una fila en Postgres. Guarda y recarga el sitio para ver el cambio.
          </p>
        </div>
        <div class="actions">
          <a class="btn btn-sky" href="/" target="_blank" rel="noreferrer">Vista previa</a>
          <button class="btn btn-lime" type="button" @click="onSignOut">Salir</button>
        </div>
      </header>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-else-if="!ready">Cargando…</p>
      <template v-else>
        <ul class="list">
          <li v-for="row in rows" :key="row.id" class="card item">
            <div>
              <strong>{{ labelFor(row.key) }}</strong>
              <p>{{ row.key }} · actualizado {{ formatDate(row.updated_at) }}</p>
            </div>
            <router-link class="btn btn-sky" :to="`/admin/secciones/${row.key}`">Editar</router-link>
          </li>
        </ul>

        <h2>Páginas legales</h2>
        <p class="admin-note">Textos públicos para Google Play. No hace falta enlazarlos desde este panel hacia el sitio.</p>
        <ul class="list">
          <li v-for="page in legalPages" :key="page.slug" class="card item">
            <div>
              <strong>{{ page.label }}</strong>
              <p>/{{ page.slug }}</p>
            </div>
            <router-link class="btn btn-sky" :to="`/admin/paginas/${page.slug}`">Editar</router-link>
          </li>
        </ul>
      </template>
    </div>
  </main>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadAdminHome } from '@/lib/cms'
import { labelFor } from '@/admin/sectionSchemas'
import { LEGAL_PAGES } from '@/lib/legalText'
import { useAdminSession } from '@/admin/useAdminSession'

const router = useRouter()
const { refresh, session, signOut, hasSupabase } = useAdminSession()
const rows = ref([])
const legalPages = LEGAL_PAGES
const ready = ref(false)
const error = ref('')

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value) {
    router.replace('/admin/login')
    return
  }
  try {
    const data = await loadAdminHome()
    rows.value = data.rows
  } catch (err) {
    error.value = err.message ?? 'No se pudieron cargar las secciones.'
  } finally {
    ready.value = true
  }
})

function formatDate(value) {
  if (!value) return '—'
  return new Date(value).toLocaleString('es-CO')
}

async function onSignOut() {
  await signOut()
  router.replace('/admin/login')
}
</script>

<style scoped>
.head {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 1.5rem;
}

h1 {
  color: var(--ink);
  font-size: 2.1rem;
}

h2 {
  margin: 2rem 0 0.6rem;
}

.actions {
  display: flex;
  gap: 0.6rem;
  align-items: flex-start;
}

.list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 0.8rem;
}

.item {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  padding: 1rem 1.1rem;
}

.item p {
  margin: 0.2rem 0 0;
  color: var(--muted);
}

.error {
  color: #c2410c;
  font-weight: 800;
}

.btn {
  min-height: 48px;
}
</style>
