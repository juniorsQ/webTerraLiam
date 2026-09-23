<template>
  <main class="resource-shell">
    <aside class="resource-sidebar">
      <router-link class="brand" to="/ops"><img src="/brand/app_icon.png" alt="" /><span><strong>TerraLiam</strong><small>OPS CONTROL</small></span></router-link>
      <div class="side-label">Control room</div>
      <nav class="side-nav" aria-label="Navegacion Ops">
        <router-link class="side-link" to="/ops"><span>+</span>Overview</router-link>
        <router-link v-for="item in resources" :key="item.key" class="side-link" :class="{ active: item.key === resource }" :to="`/ops/${item.key}`"><span>{{ item.mark }}</span>{{ item.label }}</router-link>
      </nav>
      <div class="sidebar-spacer" /><button class="signout" type="button" @click="onSignOut">Cerrar sesion <span>↗</span></button>
    </aside>

    <section class="resource-content">
      <header class="resource-head"><div><p class="crumb">TerraLiam <span>/</span> {{ resourceLabel }}</p><h1>{{ resourceLabel }}</h1><p class="subcopy">Registros operativos sincronizados desde Supabase.</p></div><div class="head-actions"><span class="live-state"><i /> LIVE DATA</span><button class="refresh-button" type="button" :disabled="!ready" @click="loadResource">Actualizar <span>↻</span></button></div></header>
      <p v-if="error" class="error-banner">{{ error }}</p><p v-else-if="!ready" class="loading-state">Cargando registros...</p>
      <template v-else>
        <div class="table-toolbar"><span><strong>{{ rows.length }}</strong> registros visibles</span><router-link to="/ops" class="back-link">← Volver al overview</router-link></div>
        <div class="table-shell"><table><thead><tr><th v-for="column in columns" :key="column">{{ column }}</th></tr></thead><tbody><tr v-for="(row, index) in rows" :key="row.id || index"><td v-for="column in columns" :key="column"><a v-if="isImageColumn(column, row[column])" class="media-cell" :href="row[column]" target="_blank" rel="noreferrer"><img :src="row[column]" :alt="`Imagen de ${resourceLabel}`" loading="lazy" /><span>Ver imagen ↗</span></a><time v-else-if="isDateColumn(column, row[column])" :datetime="row[column]">{{ formatDate(row[column]) }}</time><span v-else>{{ formatValue(row[column]) }}</span></td></tr><tr v-if="!rows.length"><td :colspan="Math.max(columns.length, 1)" class="empty">Sin registros para mostrar.</td></tr></tbody></table></div>
      </template>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsTable } from '@/ops/opsApi'
import { useOpsSession } from '@/ops/useOpsSession'

const props = defineProps({ resource: { type: String, required: true } })
const router = useRouter()
const { refresh, session, signOut, hasSupabase, isPlatformAdmin } = useOpsSession()
const rows = ref([])
const ready = ref(false)
const error = ref('')
const labels = { users: 'Exploradores', worlds: 'Mundos', pois: 'Hallazgos', captures: 'Capturas', 'video-spend': 'Video spend', 'prize-grants': 'Premios' }
const resources = [{ key: 'users', label: 'Exploradores', mark: '◈' }, { key: 'worlds', label: 'Mundos', mark: '◎' }, { key: 'pois', label: 'Hallazgos', mark: '✦' }, { key: 'captures', label: 'Capturas', mark: '▣' }, { key: 'video-spend', label: 'Video spend', mark: '▷' }, { key: 'prize-grants', label: 'Premios', mark: '◇' }]
const resourceLabel = computed(() => labels[props.resource] ?? props.resource)
const columns = computed(() => Object.keys(rows.value[0] || {}))

onMounted(async () => { await refresh(); if (!hasSupabase || !session.value || !isPlatformAdmin()) { router.replace('/ops/login'); return }; await loadResource() })
async function loadResource() { ready.value = false; error.value = ''; try { rows.value = await loadOpsTable(props.resource) } catch (err) { error.value = err.message ?? 'No se pudo cargar el recurso.' } finally { ready.value = true } }
function formatValue(value) { if (value === null || value === undefined || value === '') return '-'; if (typeof value === 'object') return JSON.stringify(value); return String(value) }
function isImageColumn(column, value) { return typeof value === 'string' && /^https?:\/\//i.test(value) && /(image|photo|avatar|cutout|stylized|video|url)/i.test(column) }
function isDateColumn(column, value) { return typeof value === 'string' && /(created_at|captured_at|completed_at|updated_at)/i.test(column) && !Number.isNaN(Date.parse(value)) }
function formatDate(value) { return new Intl.DateTimeFormat('es-CO', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) }
async function onSignOut() { await signOut(); router.replace('/ops/login') }
</script>

<style scoped>
.resource-shell { --ops-bg: #0b1020; --ops-panel: #121a2d; --ops-panel-2: #17223a; --ops-line: rgba(151,168,204,.16); --ops-text: #eef3ff; --ops-muted: #8e9bb7; --ops-cyan: #56d7ed; --ops-lime: #b8e85c; --ops-coral: #ff7c78; min-height: 100vh; display: flex; background: var(--ops-bg); color: var(--ops-text); font-family: var(--font-body); }.resource-sidebar { width: 244px; display: flex; flex-direction: column; padding: 1.6rem 1rem; border-right: 1px solid var(--ops-line); background: #080c19; }.brand { display: flex; align-items: center; gap: .7rem; padding: 0 .55rem 2.4rem; color: var(--ops-text); text-decoration: none; }.brand img { width: 38px; height: 38px; border-radius: 12px; }.brand span { display: grid; gap: .12rem; }.brand strong { font-family: var(--font-display); font-size: 1.15rem; }.brand small { color: var(--ops-muted); font-size: .62rem; letter-spacing: .13em; }.side-label { padding: 0 .65rem .65rem; color: var(--ops-muted); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }.side-nav { display: grid; gap: .2rem; }.side-link { display: flex; align-items: center; gap: .7rem; min-height: 42px; padding: .55rem .65rem; border-radius: 9px; color: var(--ops-muted); font-size: .9rem; text-decoration: none; }.side-link span { display: inline-grid; place-items: center; width: 23px; color: var(--ops-cyan); }.side-link:hover, .side-link.active { background: var(--ops-panel-2); color: var(--ops-text); text-decoration: none; }.side-link.active { box-shadow: inset 2px 0 var(--ops-cyan); }.sidebar-spacer { flex: 1; }.signout { padding: .65rem; border: 0; background: transparent; color: var(--ops-muted); text-align: left; font: inherit; font-size: .78rem; cursor: pointer; }.signout span { float: right; color: var(--ops-coral); }.resource-content { width: min(100%, 1450px); padding: 2.2rem clamp(1.2rem, 4vw, 3.8rem) 4rem; }.resource-head, .head-actions, .table-toolbar { display: flex; align-items: center; }.resource-head { justify-content: space-between; gap: 1rem; margin-bottom: 2.2rem; }.crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }.crumb span { color: var(--ops-cyan); padding: 0 .35rem; }h1 { margin: 0; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(2rem,4vw,3.2rem); }.subcopy { margin: .55rem 0 0; color: var(--ops-muted); font-size: .85rem; }.head-actions { gap: .7rem; }.live-state, .refresh-button { display: inline-flex; align-items: center; gap: .5rem; padding: .55rem .75rem; border: 1px solid var(--ops-line); border-radius: 7px; color: var(--ops-muted); background: var(--ops-panel); font: inherit; font-size: .68rem; }.live-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); }.refresh-button { color: var(--ops-text); cursor: pointer; }.refresh-button span { color: var(--ops-cyan); font-size: 1rem; }.table-toolbar { justify-content: space-between; gap: 1rem; margin-bottom: .75rem; color: var(--ops-muted); font-size: .75rem; }.table-toolbar strong { color: var(--ops-text); }.back-link { color: var(--ops-cyan); text-decoration: none; }.table-shell { overflow: auto; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }table { width: 100%; min-width: 680px; border-collapse: collapse; }th, td { padding: .8rem .9rem; border-bottom: 1px solid var(--ops-line); text-align: left; vertical-align: top; }th { color: var(--ops-cyan); background: var(--ops-panel-2); font-size: .64rem; letter-spacing: .1em; text-transform: uppercase; }td { color: #c5cee1; font-size: .78rem; max-width: 280px; overflow-wrap: anywhere; }.empty { padding: 2rem; color: var(--ops-muted); text-align: center; }.error-banner { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }.loading-state { color: var(--ops-muted); }
 .media-cell { display: inline-flex; align-items: center; gap: .55rem; color: var(--ops-cyan); text-decoration: none; }.media-cell img { width: 42px; height: 42px; border: 1px solid var(--ops-line); border-radius: 7px; object-fit: cover; background: #0d1527; }.media-cell span { font-size: .68rem; white-space: nowrap; }.media-cell:hover span { text-decoration: underline; }
@media (max-width: 720px) { .resource-shell { display: block; }.resource-sidebar { width: 100%; padding: .9rem 1rem; border-right: 0; border-bottom: 1px solid var(--ops-line); }.brand { padding: 0 0 .8rem; }.side-label, .sidebar-spacer { display: none; }.side-nav { display: flex; overflow-x: auto; }.side-link { flex: 0 0 auto; min-height: 36px; padding: .45rem .55rem; font-size: .75rem; }.side-link.active { box-shadow: inset 0 -2px var(--ops-cyan); }.signout { display: none; }.resource-content { padding: 1.3rem 1rem 2.5rem; }.resource-head { align-items: flex-start; flex-direction: column; }.head-actions { flex-wrap: wrap; }.table-toolbar { align-items: flex-start; flex-direction: column; } }
</style>
