<template>
  <main class="section">
    <div class="wrap">
      <header class="head">
        <div>
          <p class="eyebrow">TerraLiam Ops</p>
          <h1>Backoffice del producto</h1>
          <p class="admin-note">Resumen operativo de usuarios, mundos, hallazgos, capturas, videos y premios.</p>
        </div>
        <div class="actions">
          <button class="btn btn-lime" type="button" @click="onSignOut">Salir</button>
        </div>
      </header>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-else-if="!ready">Cargando...</p>
      <template v-else>
        <section class="metrics" aria-label="Metricas">
          <article v-for="metric in metrics" :key="metric.key" class="card metric">
            <span>{{ metric.label }}</span>
            <strong>{{ formatNumber(dashboard[metric.key]) }}</strong>
          </article>
        </section>

        <section class="grid">
          <article class="card panel">
            <h2>Actividad reciente</h2>
            <p class="admin-note">Usuarios nuevos: {{ formatNumber(dashboard.users_7d) }} en 7 dias, {{ formatNumber(dashboard.users_30d) }} en 30 dias.</p>
            <div class="actions links">
              <router-link v-for="resource in resources" :key="resource.key" class="btn btn-sky" :to="`/ops/${resource.key}`">{{ resource.label }}</router-link>
            </div>
          </article>
          <article class="card panel">
            <h2>Videos y premios</h2>
            <p class="admin-note">Gasto estimado de videos: <strong>{{ formatCurrency(dashboard.video_spend_usd) }}</strong></p>
            <p class="admin-note">Solicitudes de premio pendientes: <strong>{{ formatNumber(dashboard.pending_prizes) }}</strong></p>
          </article>
        </section>

        <section class="grid">
          <article class="card panel">
            <h2>Ultimos usuarios</h2>
            <ul class="compact-list">
              <li v-for="user in dashboard.new_users || []" :key="user.id">
                <strong>{{ user.display_name || 'Sin nombre' }}</strong>
                <span>{{ formatDate(user.created_at) }}</span>
              </li>
              <li v-if="!dashboard.new_users?.length" class="admin-note">Sin usuarios recientes.</li>
            </ul>
          </article>
          <article class="card panel">
            <h2>Ultimos mundos</h2>
            <ul class="compact-list">
              <li v-for="world in dashboard.recent_worlds || []" :key="world.id">
                <strong>{{ world.name || 'Sin nombre' }}</strong>
                <span>{{ formatDate(world.created_at) }}</span>
              </li>
              <li v-if="!dashboard.recent_worlds?.length" class="admin-note">Sin mundos recientes.</li>
            </ul>
          </article>
        </section>
      </template>
    </div>
  </main>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsDashboard } from '@/ops/opsApi'
import { useOpsSession } from '@/ops/useOpsSession'

const router = useRouter()
const { refresh, session, signOut, hasSupabase, isPlatformAdmin } = useOpsSession()
const dashboard = ref({})
const ready = ref(false)
const error = ref('')

const metrics = [
  { key: 'users', label: 'Usuarios' },
  { key: 'worlds', label: 'Mundos' },
  { key: 'pois', label: 'Hallazgos activos' },
  { key: 'captures', label: 'Capturas' },
  { key: 'videos', label: 'Videos completados' },
]

const resources = [
  { key: 'users', label: 'Usuarios' },
  { key: 'worlds', label: 'Mundos' },
  { key: 'pois', label: 'Hallazgos' },
  { key: 'captures', label: 'Capturas' },
  { key: 'video-spend', label: 'Gasto de videos' },
  { key: 'prize-grants', label: 'Premios' },
]

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) {
    router.replace('/ops/login')
    return
  }
  try {
    dashboard.value = await loadOpsDashboard()
  } catch (err) {
    error.value = err.message ?? 'No se pudo cargar el dashboard.'
  } finally {
    ready.value = true
  }
})

function formatNumber(value) {
  return new Intl.NumberFormat('es-CO').format(Number(value || 0))
}

function formatCurrency(value) {
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'USD' }).format(Number(value || 0))
}

function formatDate(value) {
  return value ? new Date(value).toLocaleString('es-CO') : '-'
}

async function onSignOut() {
  await signOut()
  router.replace('/ops/login')
}
</script>

<style scoped>
.eyebrow {
  margin: 0 0 0.3rem;
  color: var(--coral);
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.head,
.actions,
.links {
  display: flex;
  gap: 0.7rem;
}

.head {
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  margin-bottom: 1.5rem;
}

h1 {
  color: var(--ink);
  font-size: 2.1rem;
}

.metrics,
.grid {
  display: grid;
  gap: 0.8rem;
  margin-bottom: 1rem;
}

.metrics {
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
}

.grid {
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
}

.metric,
.panel {
  padding: 1rem 1.1rem;
}

.metric span {
  color: var(--muted);
  display: block;
  font-size: 0.9rem;
}

.metric strong {
  display: block;
  color: var(--ink);
  font-size: 1.8rem;
  margin-top: 0.3rem;
}

h2 {
  margin-top: 0;
}

.links {
  flex-wrap: wrap;
  margin-top: 1rem;
}

.compact-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.compact-list li {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.65rem 0;
  border-bottom: 1px solid var(--sky-soft);
}

.compact-list span {
  color: var(--muted);
  font-size: 0.85rem;
  text-align: right;
}

.error {
  color: #c2410c;
  font-weight: 800;
}
</style>
