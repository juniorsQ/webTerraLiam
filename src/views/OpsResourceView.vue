<template>
  <OpsShell>
    <header class="resource-head">
      <div>
        <p class="crumb">TerraLiam <span>/</span> {{ resourceLabel }}</p>
        <h1>{{ resourceLabel }}</h1>
      </div>
      <div class="head-actions">
        <span class="live-state"><i /> {{ rows.length }} registros</span>
        <button class="refresh-button" type="button" :disabled="!ready" @click="loadResource">Actualizar <span>↻</span></button>
      </div>
    </header>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <p v-else-if="!ready" class="loading-state">Cargando registros...</p>
    <template v-else>
      <div class="table-toolbar">
        <router-link to="/ops" class="back-link">← Overview</router-link>
      </div>
      <div class="card-list">
        <article v-for="(row, index) in rows" :key="row.id || `${resource}-${index}`" class="record-card">
          <div v-for="column in columns" :key="column" class="record-field">
            <span>{{ labelColumn(column) }}</span>
            <a v-if="isImageColumn(column, row[column])" class="media-cell" :href="row[column]" target="_blank" rel="noreferrer">
              <img :src="row[column]" :alt="resourceLabel" loading="lazy" />
              Ver imagen
            </a>
            <time v-else-if="isDateColumn(column, row[column])" :datetime="row[column]">{{ formatDateTime(row[column]) }}</time>
            <strong v-else>{{ formatCell(column, row[column]) }}</strong>
          </div>
        </article>
        <p v-if="!rows.length" class="empty">Sin registros para mostrar.</p>
      </div>
      <div class="table-shell">
        <table>
          <thead>
            <tr>
              <th v-for="column in columns" :key="column">{{ labelColumn(column) }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, index) in rows" :key="`table-${row.id || index}`">
              <td v-for="column in columns" :key="column">
                <a v-if="isImageColumn(column, row[column])" class="media-cell" :href="row[column]" target="_blank" rel="noreferrer">
                  <img :src="row[column]" :alt="resourceLabel" loading="lazy" />
                  Ver imagen
                </a>
                <time v-else-if="isDateColumn(column, row[column])" :datetime="row[column]">{{ formatDateTime(row[column]) }}</time>
                <span v-else>{{ formatCell(column, row[column]) }}</span>
              </td>
            </tr>
            <tr v-if="!rows.length">
              <td :colspan="Math.max(columns.length, 1)" class="empty">Sin registros para mostrar.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </OpsShell>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsTable } from '@/ops/opsApi'
import OpsShell from '@/ops/OpsShell.vue'
import { formatCell, formatDateTime, isDateColumn, isImageColumn, labelColumn, opsResources } from '@/ops/opsUi'
import { useOpsSession } from '@/ops/useOpsSession'

const props = defineProps({ resource: { type: String, required: true } })
const router = useRouter()
const { refresh, session, hasSupabase, isPlatformAdmin } = useOpsSession()
const rows = ref([])
const ready = ref(false)
const error = ref('')
const resourceLabel = computed(() => opsResources.find((item) => item.key === props.resource)?.label ?? props.resource)
const columns = computed(() => Object.keys(rows.value[0] || {}))

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) {
    router.replace('/ops/login')
    return
  }
  await loadResource()
})
watch(() => props.resource, () => {
  if (session.value && isPlatformAdmin()) loadResource()
})

async function loadResource() {
  ready.value = false
  error.value = ''
  try {
    rows.value = await loadOpsTable(props.resource)
  } catch (err) {
    error.value = err.message ?? 'No se pudo cargar el recurso.'
  } finally {
    ready.value = true
  }
}
</script>

<style scoped>
.resource-head, .head-actions, .table-toolbar { display: flex; align-items: center; }
.resource-head { justify-content: space-between; gap: 1rem; margin-bottom: 1.5rem; }
.crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }
.crumb span { color: var(--ops-cyan); padding: 0 .35rem; }
h1 { margin: 0; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(1.8rem, 4vw, 3.2rem); }
.head-actions { gap: .7rem; flex-wrap: wrap; }
.live-state, .refresh-button { display: inline-flex; align-items: center; gap: .5rem; padding: .55rem .75rem; border: 1px solid var(--ops-line); border-radius: 7px; color: var(--ops-muted); background: var(--ops-panel); font: inherit; font-size: .68rem; }
.live-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); }
.refresh-button { color: var(--ops-text); cursor: pointer; }
.refresh-button span { color: var(--ops-cyan); }
.table-toolbar { justify-content: flex-end; margin-bottom: .75rem; }
.back-link { color: var(--ops-cyan); text-decoration: none; font-size: .78rem; }
.card-list { display: none; }
.table-shell { overflow: auto; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
table { width: 100%; min-width: 680px; border-collapse: collapse; }
th, td { padding: .8rem .9rem; border-bottom: 1px solid var(--ops-line); text-align: left; vertical-align: top; }
th { color: var(--ops-cyan); background: var(--ops-panel-2); font-size: .64rem; letter-spacing: .1em; text-transform: uppercase; }
td { color: #c5cee1; font-size: .78rem; max-width: 280px; overflow-wrap: anywhere; }
.empty { padding: 2rem; color: var(--ops-muted); text-align: center; }
.error-banner { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }
.loading-state { color: var(--ops-muted); }
.media-cell { display: inline-flex; align-items: center; gap: .55rem; color: var(--ops-cyan); text-decoration: none; }
.media-cell img { width: 42px; height: 42px; border: 1px solid var(--ops-line); border-radius: 7px; object-fit: cover; background: #0d1527; }
@media (max-width: 900px) {
  .resource-head { align-items: flex-start; flex-direction: column; }
  .table-shell { display: none; }
  .card-list { display: grid; gap: .75rem; }
  .record-card { display: grid; gap: .7rem; padding: 1rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
  .record-field { display: grid; gap: .2rem; }
  .record-field span { color: var(--ops-muted); font-size: .64rem; letter-spacing: .08em; text-transform: uppercase; }
  .record-field strong { font-size: .86rem; font-weight: 700; }
}
</style>
