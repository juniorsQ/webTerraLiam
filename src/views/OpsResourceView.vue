<template>
  <main class="section">
    <div class="wrap">
      <header class="head">
        <div>
          <p><router-link to="/ops">&lt;- Dashboard</router-link></p>
          <h1>{{ resourceLabel }}</h1>
          <p class="admin-note">Ultimos registros disponibles para operaciones.</p>
        </div>
        <button class="btn btn-lime" type="button" @click="onSignOut">Salir</button>
      </header>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-else-if="!ready">Cargando...</p>
      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th v-for="column in columns" :key="column">{{ column }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, index) in rows" :key="row.id || index">
              <td v-for="column in columns" :key="column">{{ formatValue(row[column]) }}</td>
            </tr>
            <tr v-if="!rows.length">
              <td :colspan="columns.length" class="empty">Sin registros.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </main>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsTable } from '@/ops/opsApi'
import { useOpsSession } from '@/ops/useOpsSession'

const props = defineProps({
  resource: {
    type: String,
    required: true,
  },
})

const router = useRouter()
const { refresh, session, signOut, hasSupabase, isPlatformAdmin } = useOpsSession()
const rows = ref([])
const ready = ref(false)
const error = ref('')

const labels = {
  users: 'Usuarios',
  worlds: 'Mundos',
  pois: 'Hallazgos',
  captures: 'Capturas',
  'video-spend': 'Gasto de videos',
  'prize-grants': 'Premios',
}

const resourceLabel = computed(() => labels[props.resource] ?? props.resource)
const columns = computed(() => Object.keys(rows.value[0] || {}))

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) {
    router.replace('/ops/login')
    return
  }
  try {
    rows.value = await loadOpsTable(props.resource)
  } catch (err) {
    error.value = err.message ?? 'No se pudo cargar el recurso.'
  } finally {
    ready.value = true
  }
})

function formatValue(value) {
  if (value === null || value === undefined) return '-'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}

async function onSignOut() {
  await signOut()
  router.replace('/ops/login')
}
</script>

<style scoped>
.head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 1.5rem;
}

h1 {
  color: var(--ink);
  font-size: 2.1rem;
}

.table-wrap {
  overflow-x: auto;
  background: var(--white);
  border: 2px solid var(--sky-deep);
  border-radius: var(--radius-card);
}

table {
  width: 100%;
  min-width: 680px;
  border-collapse: collapse;
}

th,
td {
  padding: 0.8rem 0.9rem;
  border-bottom: 1px solid var(--sky-soft);
  text-align: left;
  vertical-align: top;
}

th {
  color: var(--ink);
  background: var(--sky-soft);
  font-size: 0.85rem;
  text-transform: uppercase;
}

td {
  color: var(--muted);
  font-size: 0.9rem;
  max-width: 260px;
  overflow-wrap: anywhere;
}

.empty,
.error {
  text-align: center;
}

.error {
  color: #c2410c;
  font-weight: 800;
}
</style>
