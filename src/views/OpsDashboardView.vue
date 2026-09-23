<template>
  <main class="ops-shell">
    <aside class="ops-sidebar">
      <router-link class="brand" to="/ops" aria-label="TerraLiam Ops">
        <img src="/brand/app_icon.png" alt="" />
        <span><strong>TerraLiam</strong><small>OPS CONTROL</small></span>
      </router-link>
      <div class="side-label">Control room</div>
      <nav class="side-nav" aria-label="Navegacion Ops">
        <router-link class="side-link active" to="/ops"><span class="nav-mark">+</span>Overview</router-link>
        <router-link v-for="resource in resources" :key="resource.key" class="side-link" :to="`/ops/${resource.key}`">
          <span class="nav-mark">{{ resource.mark }}</span>{{ resource.label }}
        </router-link>
      </nav>
      <div class="sidebar-spacer" />
      <div class="operator-card"><span class="live-dot" /><div><strong>Platform admin</strong><small>Sesion protegida</small></div></div>
      <button class="signout" type="button" @click="onSignOut">Cerrar sesion <span>↗</span></button>
    </aside>

    <section class="ops-content">
      <header class="topbar">
        <div><p class="crumb">TerraLiam <span>/</span> Control room</p><h1>Mission control</h1></div>
        <div class="top-actions"><span class="system-state"><i /> Todos los sistemas operativos</span><button class="refresh-button" type="button" :disabled="loading" @click="loadDashboard">{{ loading ? 'Actualizando...' : 'Actualizar' }} <span>↻</span></button></div>
      </header>

      <p v-if="error" class="error-banner">{{ error }}</p>
      <p v-else-if="!ready" class="loading-state">Sincronizando telemetria...</p>
      <template v-else>
        <section class="command-hero">
          <div><p class="kicker">LIVE OPERATIONS <span>{{ currentTime }}</span></p><h2>El mundo real,<br /><em>en movimiento.</em></h2><p class="hero-copy">Lectura ejecutiva de la actividad de TerraLiam y sus mundos explorables.</p></div>
          <div class="hero-signal"><div class="signal-ring"><span>{{ formatNumber(dashboard.captures) }}</span><small>CAPTURAS</small></div><div class="signal-line"><i /><i /><i /><i /><i /><i /><i /></div><small>SEÑAL DE JUEGO</small></div>
        </section>

        <section class="metric-grid" aria-label="Metricas principales">
          <article v-for="metric in metrics" :key="metric.key" class="metric-card" :class="`tone-${metric.tone}`"><div class="metric-top"><span class="metric-icon">{{ metric.mark }}</span><span class="metric-trend">{{ metric.context }}</span></div><strong>{{ formatNumber(dashboard[metric.key]) }}</strong><span class="metric-label">{{ metric.label }}</span></article>
        </section>

        <section class="dashboard-grid">
          <article class="panel activity-panel"><header class="panel-head"><div><span class="panel-index">01</span><h3>Actividad reciente</h3></div><span class="panel-status">Ultimas senales</span></header><div class="activity-list"><div v-for="item in activity" :key="item.id" class="activity-row"><span class="activity-badge" :class="`activity-${item.type}`">{{ item.mark }}</span><div><strong>{{ item.title }}</strong><small>{{ item.detail }}</small></div><time>{{ formatRelative(item.date) }}</time></div><p v-if="!activity.length" class="empty-state">Todavia no hay actividad para mostrar.</p></div></article>
          <article class="panel signal-panel"><header class="panel-head"><div><span class="panel-index">02</span><h3>Ultima ubicacion</h3></div><span class="panel-status amber">En preparacion</span></header><div class="map-placeholder"><div class="map-grid" /><span class="map-pin">+</span><div class="map-copy"><strong>Senal GPS no disponible</strong><small>La base registra capturas, no coordenadas del jugador todavia.</small></div></div><p class="panel-footnote">Cuando la app envie latitud, longitud y timestamp, este panel mostrara la ultima posicion por jugador.</p></article>
          <article class="panel worlds-panel"><header class="panel-head"><div><span class="panel-index">03</span><h3>Mundos activos</h3></div><router-link to="/ops/worlds" class="panel-link">Ver todos ↗</router-link></header><div class="world-list"><div v-for="world in dashboard.recent_worlds || []" :key="world.id" class="world-row"><span class="world-avatar">{{ initials(world.name) }}</span><div><strong>{{ world.name || 'Mundo sin nombre' }}</strong><small>{{ world.visibility || 'Privado' }} · creado {{ formatRelative(world.created_at) }}</small></div><span class="world-state">LIVE</span></div><p v-if="!dashboard.recent_worlds?.length" class="empty-state">No hay mundos recientes.</p></div></article>
          <article class="panel economy-panel"><header class="panel-head"><div><span class="panel-index">04</span><h3>Economia de video</h3></div><router-link to="/ops/video-spend" class="panel-link">Auditar ↗</router-link></header><div class="economy-main"><strong>{{ formatCurrency(dashboard.video_spend_usd) }}</strong><span>gasto comprometido</span></div><div class="economy-meta"><span><i class="bar lime" /><b>{{ formatNumber(dashboard.videos) }}</b> completados</span><span><i class="bar coral" /><b>{{ formatNumber(dashboard.pending_prizes) }}</b> premios pendientes</span></div></article>
        </section>
      </template>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsDashboard } from '@/ops/opsApi'
import { useOpsSession } from '@/ops/useOpsSession'

const router = useRouter()
const { refresh, session, signOut, hasSupabase, isPlatformAdmin } = useOpsSession()
const dashboard = ref({})
const ready = ref(false)
const loading = ref(false)
const error = ref('')
const now = ref(new Date())
let clock

const currentTime = computed(() => now.value.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' }))
const metrics = [
  { key: 'users', label: 'Exploradores', mark: '◈', context: 'total', tone: 'cyan' },
  { key: 'worlds', label: 'Mundos creados', mark: '◎', context: 'universos', tone: 'violet' },
  { key: 'pois', label: 'Hallazgos activos', mark: '✦', context: 'disponibles', tone: 'lime' },
  { key: 'videos', label: 'Videos completados', mark: '▷', context: 'procesados', tone: 'coral' },
]
const resources = [
  { key: 'users', label: 'Exploradores', mark: '◈' }, { key: 'worlds', label: 'Mundos', mark: '◎' }, { key: 'pois', label: 'Hallazgos', mark: '✦' },
  { key: 'captures', label: 'Capturas', mark: '▣' }, { key: 'video-spend', label: 'Video spend', mark: '▷' }, { key: 'prize-grants', label: 'Premios', mark: '◇' },
]
const activity = computed(() => [
  ...(dashboard.value.new_users || []).map((user) => ({ id: `user-${user.id}`, type: 'user', mark: '◈', title: user.display_name || 'Nuevo explorador', detail: 'Se unio a TerraLiam', date: user.created_at })),
  ...(dashboard.value.recent_worlds || []).map((world) => ({ id: `world-${world.id}`, type: 'world', mark: '◎', title: world.name || 'Mundo nuevo', detail: 'Mundo creado', date: world.created_at })),
].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 6))

onMounted(async () => {
  clock = window.setInterval(() => { now.value = new Date() }, 30000)
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) { router.replace('/ops/login'); return }
  await loadDashboard()
})
onUnmounted(() => window.clearInterval(clock))

async function loadDashboard() {
  loading.value = true; error.value = ''
  try { dashboard.value = await loadOpsDashboard() } catch (err) { error.value = err.message ?? 'No se pudo sincronizar el dashboard.' } finally { ready.value = true; loading.value = false }
}
function formatNumber(value) { return new Intl.NumberFormat('es-CO').format(Number(value || 0)) }
function formatCurrency(value) { return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'USD' }).format(Number(value || 0)) }
function formatRelative(value) { if (!value) return 'sin fecha'; const minutes = Math.max(0, Math.round((Date.now() - new Date(value).getTime()) / 60000)); if (minutes < 1) return 'ahora'; if (minutes < 60) return `hace ${minutes} min`; const hours = Math.round(minutes / 60); if (hours < 24) return `hace ${hours} h`; return new Date(value).toLocaleDateString('es-CO', { day: '2-digit', month: 'short' }) }
function initials(value) { return String(value || 'TL').split(/\s+/).slice(0, 2).map((word) => word[0]).join('').toUpperCase() }
async function onSignOut() { await signOut(); router.replace('/ops/login') }
</script>

<style scoped>
.ops-shell { --ops-bg: #0b1020; --ops-panel: #121a2d; --ops-panel-2: #17223a; --ops-line: rgba(151,168,204,.16); --ops-text: #eef3ff; --ops-muted: #8e9bb7; --ops-cyan: #56d7ed; --ops-violet: #9e8cff; --ops-lime: #b8e85c; --ops-coral: #ff7c78; min-height: 100vh; display: flex; background: radial-gradient(circle at 75% 0%, rgba(72,93,174,.2), transparent 35%), var(--ops-bg); color: var(--ops-text); font-family: var(--font-body); }
.ops-sidebar { width: 244px; display: flex; flex-direction: column; padding: 1.6rem 1rem; border-right: 1px solid var(--ops-line); background: rgba(8,12,25,.74); }.brand { display: flex; align-items: center; gap: .7rem; padding: 0 .55rem 2.4rem; color: var(--ops-text); text-decoration: none; }.brand img { width: 38px; height: 38px; border-radius: 12px; object-fit: cover; }.brand span { display: grid; gap: .12rem; }.brand strong { font-family: var(--font-display); font-size: 1.15rem; }.brand small, .operator-card small { color: var(--ops-muted); font-size: .62rem; letter-spacing: .13em; }.side-label, .panel-index, .kicker { color: var(--ops-muted); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }.side-label { padding: 0 .65rem .65rem; }.side-nav { display: grid; gap: .2rem; }.side-link { display: flex; align-items: center; gap: .7rem; min-height: 42px; padding: .55rem .65rem; border-radius: 9px; color: var(--ops-muted); font-size: .9rem; text-decoration: none; }.side-link:hover, .side-link.active { background: var(--ops-panel-2); color: var(--ops-text); text-decoration: none; }.side-link.active { box-shadow: inset 2px 0 var(--ops-cyan); }.nav-mark { display: inline-grid; place-items: center; width: 23px; color: var(--ops-cyan); }.sidebar-spacer { flex: 1; }.operator-card { display: flex; align-items: center; gap: .65rem; padding: .8rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }.operator-card div { display: grid; gap: .15rem; }.operator-card strong { font-size: .78rem; }.live-dot, .system-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); box-shadow: 0 0 0 4px rgba(184,232,92,.12); }.signout { margin-top: .65rem; padding: .65rem; border: 0; background: transparent; color: var(--ops-muted); text-align: left; font: inherit; font-size: .78rem; cursor: pointer; }.signout span { float: right; color: var(--ops-coral); }
.ops-content { width: min(100%, 1450px); padding: 2.2rem clamp(1.2rem, 4vw, 3.8rem) 4rem; }.topbar, .top-actions, .panel-head, .metric-top, .economy-meta { display: flex; align-items: center; }.topbar { justify-content: space-between; gap: 1rem; margin-bottom: 2.2rem; }.crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }.crumb span { color: var(--ops-cyan); padding: 0 .35rem; }h1, h2, h3 { margin: 0; color: var(--ops-text); }h1 { font-family: var(--font-display); font-size: clamp(2rem,4vw,3.2rem); }.top-actions { flex-wrap: wrap; justify-content: flex-end; gap: .7rem; }.system-state, .refresh-button { display: inline-flex; align-items: center; gap: .5rem; border: 1px solid var(--ops-line); border-radius: 7px; padding: .55rem .75rem; color: var(--ops-muted); background: var(--ops-panel); font: inherit; font-size: .72rem; }.refresh-button { color: var(--ops-text); cursor: pointer; }.refresh-button span { color: var(--ops-cyan); font-size: 1rem; }
.command-hero { display: flex; align-items: center; justify-content: space-between; gap: 2rem; min-height: 220px; margin-bottom: 1.25rem; padding: 2.1rem 2.2rem; overflow: hidden; border: 1px solid var(--ops-line); border-radius: 14px; background: linear-gradient(105deg,#182442,#111a31 60%,#202348); position: relative; }.command-hero::after { content: ''; position: absolute; right: 16%; bottom: -105px; width: 360px; height: 180px; border-radius: 50%; background: rgba(86,215,237,.13); filter: blur(16px); }.kicker { margin: 0 0 .85rem; color: var(--ops-cyan); }.kicker span { margin-left: 1rem; color: var(--ops-muted); }.command-hero h2 { font-family: var(--font-display); font-size: clamp(2rem,4vw,3.5rem); line-height: .96; }.command-hero h2 em { color: var(--ops-cyan); font-style: normal; }.hero-copy { max-width: 31rem; margin: 1rem 0 0; color: var(--ops-muted); font-size: .9rem; }.hero-signal { position: relative; z-index: 1; display: grid; justify-items: center; gap: .6rem; min-width: 220px; color: var(--ops-muted); font-size: .6rem; letter-spacing: .13em; }.signal-ring { display: grid; place-items: center; width: 116px; height: 116px; border: 1px solid var(--ops-cyan); border-radius: 50%; box-shadow: 0 0 0 12px rgba(86,215,237,.05), inset 0 0 24px rgba(86,215,237,.12); }.signal-ring span { font-family: var(--font-display); font-size: 2rem; letter-spacing: 0; }.signal-ring small { margin-top: -1.8rem; font-size: .54rem; letter-spacing: .12em; }.signal-line { display: flex; align-items: center; gap: 3px; height: 18px; }.signal-line i { width: 4px; height: 8px; border-radius: 3px; background: var(--ops-cyan); animation: signal 1.2s ease-in-out infinite alternate; }.signal-line i:nth-child(2), .signal-line i:nth-child(6) { height: 15px; animation-delay: 120ms; }.signal-line i:nth-child(3), .signal-line i:nth-child(5) { height: 11px; animation-delay: 240ms; }.signal-line i:nth-child(4) { height: 18px; animation-delay: 360ms; }@keyframes signal { to { opacity: .38; transform: scaleY(.55); } }
.metric-grid { display: grid; grid-template-columns: repeat(4,minmax(0,1fr)); gap: .75rem; margin-bottom: 1.25rem; }.metric-card { min-height: 140px; padding: 1rem 1.15rem; border: 1px solid var(--ops-line); border-top: 2px solid var(--metric-color); border-radius: 10px; background: var(--ops-panel); }.tone-cyan { --metric-color: var(--ops-cyan); }.tone-violet { --metric-color: var(--ops-violet); }.tone-lime { --metric-color: var(--ops-lime); }.tone-coral { --metric-color: var(--ops-coral); }.metric-top { justify-content: space-between; color: var(--metric-color); }.metric-trend { color: var(--ops-muted); font-size: .65rem; text-transform: uppercase; letter-spacing: .1em; }.metric-card strong { display: block; margin-top: 1rem; font-family: var(--font-display); font-size: 2rem; }.metric-label { color: var(--ops-muted); font-size: .74rem; }
.dashboard-grid { display: grid; grid-template-columns: 1.2fr .8fr; gap: .75rem; }.panel { min-width: 0; padding: 1.2rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }.activity-panel { grid-row: span 2; }.panel-head { justify-content: space-between; gap: 1rem; margin-bottom: 1.1rem; }.panel-head > div { display: flex; align-items: center; gap: .65rem; }.panel-index { color: var(--ops-cyan); }.panel h3 { font-size: .98rem; }.panel-status, .panel-link { color: var(--ops-muted); font-size: .68rem; }.panel-link { color: var(--ops-cyan); text-decoration: none; }.panel-status.amber { color: #f5bd67; }.activity-list, .world-list { display: grid; }.activity-row, .world-row { display: grid; grid-template-columns: 32px minmax(0,1fr) auto; align-items: center; gap: .7rem; padding: .76rem 0; border-top: 1px solid var(--ops-line); }.activity-row:first-child, .world-row:first-child { border-top: 0; }.activity-badge, .world-avatar { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 8px; background: rgba(86,215,237,.12); color: var(--ops-cyan); }.activity-world { background: rgba(158,140,255,.12); color: var(--ops-violet); }.activity-row strong, .world-row strong { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: .8rem; }.activity-row small, .world-row small { display: block; margin-top: .12rem; color: var(--ops-muted); font-size: .68rem; }.activity-row time { color: var(--ops-muted); font-size: .66rem; white-space: nowrap; }.empty-state { margin: 1rem 0; color: var(--ops-muted); font-size: .8rem; }
.map-placeholder { position: relative; min-height: 190px; overflow: hidden; border: 1px solid var(--ops-line); border-radius: 8px; background: #111d32; }.map-grid { position: absolute; inset: 0; opacity: .38; background-image: linear-gradient(rgba(86,215,237,.1) 1px,transparent 1px),linear-gradient(90deg,rgba(86,215,237,.1) 1px,transparent 1px); background-size: 26px 26px; transform: perspective(300px) rotateX(48deg) scale(1.4); transform-origin: bottom; }.map-pin { position: absolute; left: 50%; top: 40%; display: grid; place-items: center; width: 34px; height: 34px; border: 1px solid var(--ops-cyan); border-radius: 50%; color: var(--ops-cyan); box-shadow: 0 0 0 9px rgba(86,215,237,.1),0 0 25px rgba(86,215,237,.55); }.map-copy { position: absolute; right: 1rem; bottom: .85rem; left: 1rem; display: grid; gap: .15rem; }.map-copy strong { font-size: .75rem; }.map-copy small, .panel-footnote { color: var(--ops-muted); font-size: .67rem; }.panel-footnote { margin: .75rem 0 0; line-height: 1.5; }.world-avatar { background: rgba(184,232,92,.12); color: var(--ops-lime); font-size: .66rem; font-weight: 900; }.world-state { color: var(--ops-lime); font-size: .58rem; font-weight: 900; letter-spacing: .1em; }.economy-main { padding: .45rem 0 1rem; border-bottom: 1px solid var(--ops-line); }.economy-main strong { display: block; font-family: var(--font-display); font-size: 2rem; }.economy-main span { color: var(--ops-muted); font-size: .7rem; }.economy-meta { flex-wrap: wrap; gap: 1rem; padding-top: 1rem; color: var(--ops-muted); font-size: .68rem; }.economy-meta span { display: inline-flex; align-items: center; gap: .35rem; }.economy-meta b { color: var(--ops-text); }.bar { width: 7px; height: 7px; border-radius: 50%; }.bar.lime { background: var(--ops-lime); }.bar.coral { background: var(--ops-coral); }.error-banner { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }.loading-state { color: var(--ops-muted); }
@media (max-width: 950px) { .ops-sidebar { width: 205px; }.metric-grid { grid-template-columns: repeat(2,1fr); } }@media (max-width: 720px) { .ops-shell { display: block; }.ops-sidebar { width: 100%; padding: .9rem 1rem; border-right: 0; border-bottom: 1px solid var(--ops-line); }.brand { padding: 0 0 .8rem; }.side-label, .sidebar-spacer, .operator-card { display: none; }.side-nav { display: flex; overflow-x: auto; gap: .25rem; }.side-link { flex: 0 0 auto; min-height: 36px; padding: .45rem .55rem; font-size: .75rem; }.side-link.active { box-shadow: inset 0 -2px var(--ops-cyan); }.signout { display: none; }.ops-content { padding: 1.3rem 1rem 2.5rem; }.topbar, .command-hero { align-items: flex-start; flex-direction: column; }.top-actions { justify-content: flex-start; }.command-hero { padding: 1.5rem; }.hero-signal { align-self: center; }.dashboard-grid { grid-template-columns: 1fr; }.activity-panel { grid-row: auto; }}@media (max-width: 450px) { .metric-grid { grid-template-columns: 1fr 1fr; gap: .5rem; }.metric-card { min-height: 120px; padding: .8rem; }.metric-card strong { margin-top: .7rem; font-size: 1.55rem; }.system-state { display: none; }.panel { padding: 1rem; } }
</style>
