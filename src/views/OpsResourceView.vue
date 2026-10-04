<template>
  <OpsShell>
    <header class="resource-head">
      <div>
        <p class="crumb"><router-link to="/ops">Centro de control</router-link><span>/</span>{{ config?.group }}</p>
        <h1>{{ config?.label ?? resource }}</h1>
        <p v-if="config?.hint" class="hint">{{ config.hint }}</p>
      </div>
      <div class="head-actions">
        <span class="count-pill">{{ formatNumber(total) }} {{ total === 1 ? 'registro' : 'registros' }}</span>
        <button class="ops-btn" type="button" :disabled="loading" @click="reload">{{ loading ? 'Cargando…' : 'Actualizar ↻' }}</button>
      </div>
    </header>

    <p v-if="!config" class="ops-error">Recurso desconocido.</p>
    <template v-else>
      <div class="toolbar">
        <label class="search">
          <span aria-hidden="true">⌕</span>
          <input v-model="searchInput" type="search" :placeholder="`Buscar: ${config.search ?? ''}`" :aria-label="`Buscar en ${config.label}`" />
        </label>
        <div v-if="config.filters?.length" class="chips" role="group" aria-label="Filtros">
          <button type="button" class="chip" :class="{ active: !filter }" @click="setFilter('')">Todos</button>
          <button
            v-for="item in config.filters"
            :key="item.value"
            type="button"
            class="chip"
            :class="{ active: filter === item.value }"
            @click="setFilter(item.value)"
          >{{ item.label }}</button>
        </div>
      </div>

      <p v-if="error" class="ops-error">{{ error }}</p>

      <div class="table-shell" :class="{ busy: loading }">
        <table>
          <thead>
            <tr>
              <th v-for="column in config.columns" :key="column.key">{{ column.label }}</th>
              <th v-if="config.actions?.length || config.detail" class="actions-col"><span class="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in rows"
              :key="row.id"
              :class="{ clickable: config.detail }"
              :tabindex="config.detail ? 0 : undefined"
              @click="openRow(row)"
              @keydown.enter="openRow(row)"
            >
              <td v-for="column in config.columns" :key="column.key" :data-label="column.label">
                <OpsCell :column="column" :row="row" />
              </td>
              <td v-if="config.actions?.length || config.detail" class="actions-col" @click.stop>
                <div class="row-actions">
                  <button
                    v-for="action in visibleActions(row)"
                    :key="action.key"
                    type="button"
                    class="ops-btn"
                    :class="action.tone"
                    :disabled="busyRow === row.id"
                    @click="runAction(action, row)"
                  >{{ action.label }}</button>
                  <router-link v-if="config.detail" :to="`/ops/${resource}/${row.id}`" class="ops-btn" aria-label="Ver detalle">Ver →</router-link>
                </div>
              </td>
            </tr>
            <tr v-if="!rows.length && !loading">
              <td :colspan="config.columns.length + 1" class="empty">
                {{ searchInput || filter ? 'Nada coincide con la búsqueda o el filtro.' : 'Aún no hay registros.' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="rows.length < total" class="more">
        <span class="ops-muted">Mostrando {{ formatNumber(rows.length) }} de {{ formatNumber(total) }}</span>
        <button class="ops-btn" type="button" :disabled="loading" @click="loadMore">Cargar más</button>
      </div>
    </template>
  </OpsShell>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import OpsCell from '@/ops/OpsCell.vue'
import OpsShell from '@/ops/OpsShell.vue'
import { listResource, mutate } from '@/ops/opsApi'
import { confirmAction, editForm, toast } from '@/ops/opsFeedback'
import { findResource, formatNumber } from '@/ops/opsUi'

const PAGE = 50
const props = defineProps({ resource: { type: String, required: true } })
const route = useRoute()
const router = useRouter()

const config = computed(() => findResource(props.resource))
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const error = ref('')
const busyRow = ref(null)
const searchInput = ref(String(route.query.q ?? ''))
const filter = computed(() => String(route.query.filter ?? ''))
let debounce
let requestSeq = 0

watch(searchInput, (value) => {
  window.clearTimeout(debounce)
  debounce = window.setTimeout(() => {
    router.replace({ query: { ...route.query, q: value || undefined } })
  }, 300)
})
onBeforeUnmount(() => window.clearTimeout(debounce))

watch(
  () => [props.resource, route.query.q, route.query.filter],
  ([resource], previous) => {
    if (previous && resource !== previous[0]) searchInput.value = String(route.query.q ?? '')
    reload()
  },
  { immediate: true },
)

function setFilter(value) {
  router.replace({ query: { ...route.query, filter: value || undefined } })
}

async function fetchPage(offset) {
  if (!config.value) return
  const seq = ++requestSeq
  loading.value = true
  error.value = ''
  try {
    const data = await listResource(props.resource, {
      search: String(route.query.q ?? ''),
      filter: filter.value,
      limit: PAGE,
      offset,
    })
    if (seq !== requestSeq) return
    rows.value = offset ? [...rows.value, ...(data?.rows ?? [])] : (data?.rows ?? [])
    total.value = Number(data?.total ?? rows.value.length)
  } catch (err) {
    if (seq === requestSeq) error.value = err.message ?? 'No se pudo cargar el recurso.'
  } finally {
    if (seq === requestSeq) loading.value = false
  }
}

function reload() {
  return fetchPage(0)
}

function loadMore() {
  return fetchPage(rows.value.length)
}

function openRow(row) {
  if (config.value?.detail) router.push(`/ops/${props.resource}/${row.id}`)
}

function visibleActions(row) {
  return (config.value?.actions ?? []).filter((action) => !action.when || action.when(row))
}

async function runAction(action, row) {
  let payload = action.payload ? action.payload(row) : {}
  if (action.fields) {
    const values = Object.fromEntries(action.fields.map((field) => [field.key, row[field.source ?? field.key]]))
    const edited = await editForm({ title: `${action.label}: ${row.jugador ?? row.nombre ?? ''}`, fields: action.fields, values })
    if (!edited) return
    payload = edited
  } else if (action.confirm) {
    const ok = await confirmAction({
      title: action.label,
      message: action.confirm(row),
      confirmLabel: action.label,
      danger: action.tone === 'danger',
    })
    if (!ok) return
  }
  busyRow.value = row.id
  try {
    await mutate(props.resource, row.id, action.action ?? action.key, payload)
    toast(`${action.label}: listo.`)
    await reload()
  } catch (err) {
    toast(err.message ?? 'No se pudo completar la acción.', 'bad')
  } finally {
    busyRow.value = null
  }
}
</script>

<style scoped>
.resource-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 1rem; margin-bottom: 1.25rem; }
h1 { margin: 0; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(1.8rem, 4vw, 2.8rem); }
.hint { max-width: 46rem; margin: .4rem 0 0; color: var(--ops-muted); font-size: .82rem; line-height: 1.45; }
.head-actions { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }
.count-pill { padding: .45rem .7rem; border: 1px solid var(--ops-line); border-radius: 99px; color: var(--ops-muted); font-size: .72rem; }
.toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: .75rem; margin-bottom: .9rem; }
.search { display: flex; align-items: center; gap: .5rem; flex: 1 1 260px; max-width: 420px; padding: 0 .8rem; border: 1px solid var(--ops-line); border-radius: 9px; background: var(--ops-panel); color: var(--ops-muted); }
.search:focus-within { border-color: var(--ops-cyan); }
.search input { flex: 1; min-width: 0; min-height: 40px; border: 0; outline: none; background: transparent; color: var(--ops-text); font: inherit; font-size: .84rem; }
.chips { display: flex; flex-wrap: wrap; gap: .35rem; }
.chip { min-height: 32px; padding: 0 .75rem; border: 1px solid var(--ops-line); border-radius: 99px; background: transparent; color: var(--ops-muted); font: inherit; font-size: .74rem; cursor: pointer; }
.chip:hover { color: var(--ops-text); }
.chip.active { border-color: transparent; background: var(--ops-cyan); color: #081018; font-weight: 800; }
.table-shell { overflow: auto; border: 1px solid var(--ops-line); border-radius: 12px; background: var(--ops-panel); transition: opacity .15s; }
.table-shell.busy { opacity: .6; }
table { width: 100%; min-width: 760px; border-collapse: collapse; }
th, td { padding: .7rem .85rem; border-bottom: 1px solid var(--ops-line); text-align: left; vertical-align: middle; }
th { position: sticky; top: 0; z-index: 1; color: var(--ops-muted); background: var(--ops-panel-2); font-size: .64rem; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; white-space: nowrap; }
td { color: #c5cee1; font-size: .8rem; max-width: 300px; }
tbody tr:last-child td { border-bottom: 0; }
tr.clickable { cursor: pointer; }
tr.clickable:hover td, tr.clickable:focus-visible td { background: rgba(86,215,237,.05); }
tr.clickable:focus-visible { outline: 2px solid var(--ops-cyan); outline-offset: -2px; }
.actions-col { width: 1%; }
.row-actions { display: flex; justify-content: flex-end; gap: .35rem; }
.empty { padding: 2.5rem 1rem; color: var(--ops-muted); text-align: center; }
.more { display: flex; align-items: center; justify-content: space-between; gap: 1rem; margin-top: .85rem; font-size: .76rem; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); }
@media (max-width: 900px) {
  .resource-head { flex-direction: column; }
  .search { max-width: none; }
  table { min-width: 0; }
  thead { display: none; }
  tbody, tr, td { display: block; }
  tr { margin: .6rem; padding: .8rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #10182b; }
  td { display: grid; grid-template-columns: 110px minmax(0, 1fr); gap: .6rem; align-items: center; max-width: none; padding: .35rem 0; border: 0; }
  td::before { content: attr(data-label); color: var(--ops-muted); font-size: .64rem; letter-spacing: .06em; text-transform: uppercase; }
  td.actions-col { display: block; width: auto; padding-top: .6rem; }
  td.actions-col::before { content: none; }
  .row-actions { flex-wrap: wrap; justify-content: flex-start; }
  td.empty { display: block; }
  td.empty::before { content: none; }
}
</style>
