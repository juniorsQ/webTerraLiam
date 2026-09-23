<template>
  <OpsShell>
    <header class="topbar">
      <div>
        <p class="crumb">TerraLiam <span>/</span> Control room</p>
        <h1>Mission control</h1>
      </div>
      <div class="top-actions">
        <span class="system-state"><i /> Sesión activa</span>
        <button class="refresh-button" type="button" :disabled="loading" @click="loadDashboard">
          {{ loading ? 'Actualizando...' : 'Actualizar' }} <span>↻</span>
        </button>
      </div>
    </header>

    <p v-if="error" class="error-banner">{{ error }}</p>
    <p v-else-if="!ready" class="loading-state">Cargando operación...</p>
    <template v-else>
      <section class="command-hero">
        <div>
          <p class="kicker">Operaciones <span>{{ currentTime }}</span></p>
          <h2>El mundo real,<br /><em>en movimiento.</em></h2>
          <p class="hero-copy">
            {{ formatNumber(dashboard.users) }} cuentas · {{ formatNumber(dashboard.worlds) }} mundos ·
            {{ formatNumber(dashboard.explorers) }} niños · {{ formatNumber(dashboard.characters) }} personajes
          </p>
        </div>
        <div class="hero-signal">
          <div class="signal-ring">
            <span>{{ formatNumber(dashboard.captures) }}</span>
            <small>CAPTURAS</small>
          </div>
          <small>{{ formatNumber(dashboard.captures_7d) }} esta semana</small>
        </div>
      </section>

      <section class="metric-grid" aria-label="Métricas principales">
        <article v-for="metric in metrics" :key="metric.key" class="metric-card" :class="`tone-${metric.tone}`">
          <div class="metric-top">
            <span>{{ metric.mark }}</span>
            <span class="metric-trend">{{ metric.context }}</span>
          </div>
          <strong>{{ formatNumber(dashboard[metric.key]) }}</strong>
          <span class="metric-label">{{ metric.label }}</span>
        </article>
      </section>

      <section class="provider-grid">
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">01</span><h3>Fal.ai · video</h3></div>
            <span class="panel-status">{{ fal.status }}</span>
          </header>
          <div class="economy-main">
            <strong>{{ fal.availableLabel }}</strong>
            <span>{{ fal.availableHint }}</span>
          </div>
          <div class="economy-meta">
            <span>Usado {{ formatCurrency(fal.used) }}</span>
            <span>Tope {{ formatCurrency(fal.budget) }}</span>
            <span>{{ formatNumber(fal.videos) }} videos en plataforma</span>
          </div>
        </article>
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">02</span><h3>Recraft · imágenes</h3></div>
            <span class="panel-status">{{ recraft.status }}</span>
          </header>
          <div class="economy-main">
            <strong>{{ recraft.availableLabel }}</strong>
            <span>créditos disponibles</span>
          </div>
          <div class="economy-meta">
            <span>{{ formatNumber(recraft.cutouts) }} recortes</span>
            <span>{{ formatNumber(recraft.stylized) }} estilizados</span>
          </div>
        </article>
      </section>

      <section class="chart-grid">
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">03</span><h3>Capturas por semana</h3></div>
            <span class="panel-status">8 semanas</span>
          </header>
          <div class="week-chart" role="img" :aria-label="weekChartLabel">
            <div v-for="row in weekRows" :key="row.week" class="week-col">
              <small>{{ row.count }}</small>
              <div class="week-track"><i :style="{ height: barHeight(row.count, weekMax) }" /></div>
              <span>{{ formatWeekLabel(row.week) }}</span>
            </div>
          </div>
        </article>
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">04</span><h3>Rareza</h3></div>
            <span class="panel-status">{{ formatNumber(dashboard.characters) }} activos</span>
          </header>
          <div class="h-bars">
            <div v-for="row in rarityRows" :key="row.key" class="h-bar">
              <div class="h-bar-meta">
                <strong>{{ labelRarity(row.key) }}</strong>
                <span>{{ formatNumber(row.count) }}</span>
              </div>
              <div class="h-track"><i :class="`rarity-${row.key}`" :style="{ width: barWidth(row.count, rarityMax) }" /></div>
            </div>
          </div>
        </article>
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">05</span><h3>Actividad por mundo</h3></div>
            <router-link to="/ops/worlds" class="panel-link">Mundos ↗</router-link>
          </header>
          <div class="h-bars compact">
            <div v-for="row in worldRows" :key="row.world" class="h-bar">
              <div class="h-bar-meta">
                <strong>{{ row.world }}</strong>
                <span>{{ formatNumber(row.captures) }} capturas</span>
              </div>
              <div class="h-track"><i class="world-fill" :style="{ width: barWidth(row.captures, worldMax) }" /></div>
              <small>{{ formatNumber(row.characters) }} personajes</small>
            </div>
          </div>
        </article>
      </section>

      <OpsMap :characters="mapCharacters" />

      <section class="family-section">
        <header class="panel-head">
          <div><span class="panel-index">06</span><h3>Creador, mundo y niños</h3></div>
          <span class="panel-status">{{ families.length }} familias</span>
        </header>
        <div class="family-grid">
          <article v-for="family in families" :key="family.id" class="family-card">
            <div class="family-parent">
              <span>{{ initials(family.parent) }}</span>
              <div>
                <strong>{{ family.parent }}</strong>
                <small>{{ formatNumber(family.world_count) }} {{ family.world_count === 1 ? 'mundo' : 'mundos' }}</small>
              </div>
            </div>
            <div class="family-tree">
              <div v-for="world in family.worlds || []" :key="`${family.id}-${world.name}`" class="family-world">
                <div class="world-title">
                  <strong>{{ world.name }}</strong>
                  <em>{{ labelVisibility(world.visibility) }}</em>
                </div>
                <div class="kid-row">
                  <span v-for="kid in world.kids || []" :key="`${world.name}-${kid}`" class="kid-chip">{{ kid }}</span>
                  <span v-if="!(world.kids || []).length" class="kid-empty">Sin niños</span>
                </div>
                <p>{{ formatNumber(world.characters) }} personajes · {{ formatNumber(world.captures) }} capturas</p>
              </div>
            </div>
          </article>
        </div>
      </section>

      <section class="character-section">
        <header class="panel-head">
          <div><span class="panel-index">07</span><h3>Personajes más capturados</h3></div>
          <router-link to="/ops/pois" class="panel-link">Ver todos ↗</router-link>
        </header>
        <div class="character-grid">
          <article v-for="character in topCharacters" :key="`${character.world}-${character.name}`" class="character-card">
            <img v-if="character.image" :src="character.image" :alt="character.name" loading="lazy" />
            <div v-else class="character-fallback">{{ initials(character.name) }}</div>
            <div>
              <strong>{{ character.name }}</strong>
              <small>{{ character.world }}</small>
              <div class="character-meta">
                <em :class="`rarity-${character.rarity}`">{{ labelRarity(character.rarity) }}</em>
                <span>{{ formatNumber(character.captures) }} capturas</span>
              </div>
            </div>
          </article>
        </div>
      </section>

      <section class="dashboard-grid">
        <article class="panel activity-panel">
          <header class="panel-head">
            <div><span class="panel-index">08</span><h3>Capturas recientes</h3></div>
            <router-link to="/ops/captures" class="panel-link">Historial ↗</router-link>
          </header>
          <div class="activity-list">
            <div v-for="item in recentCaptures" :key="`${item.player}-${item.character_name}-${item.captured_at}`" class="activity-row">
              <img v-if="item.image" class="activity-photo" :src="item.image" :alt="item.character_name" loading="lazy" />
              <span v-else class="activity-badge">▣</span>
              <div>
                <strong>{{ item.player }} capturó {{ item.character_name }}</strong>
                <small>en {{ item.world }}</small>
              </div>
              <time>{{ formatRelative(item.captured_at) }}</time>
            </div>
          </div>
        </article>
        <article class="panel">
          <header class="panel-head">
            <div><span class="panel-index">09</span><h3>Mundos recientes</h3></div>
            <router-link to="/ops/worlds" class="panel-link">Ver todos ↗</router-link>
          </header>
          <div class="world-list">
            <div v-for="world in recentWorlds" :key="`${world.name}-${world.created_at}`" class="world-row">
              <span class="world-avatar">{{ initials(world.name) }}</span>
              <div>
                <strong>{{ world.name }}</strong>
                <small>{{ world.parent }} · {{ world.kids }}</small>
              </div>
              <span class="world-state">{{ labelVisibility(world.visibility) }}</span>
            </div>
          </div>
        </article>
      </section>
    </template>
  </OpsShell>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsDashboard, loadProviderCredits } from '@/ops/opsApi'
import { useOpsSession } from '@/ops/useOpsSession'
import OpsMap from '@/ops/OpsMap.vue'
import OpsShell from '@/ops/OpsShell.vue'
import { formatCurrency, formatNumber, formatRelative, formatWeekLabel, initials, labelRarity, labelVisibility } from '@/ops/opsUi'

const router = useRouter()
const { refresh, session, hasSupabase, isPlatformAdmin } = useOpsSession()
const dashboard = ref({})
const credits = ref({})
const ready = ref(false)
const loading = ref(false)
const error = ref('')
const now = ref(new Date())
let clock

const currentTime = computed(() => now.value.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' }))
const metrics = [
  { key: 'users', label: 'Cuentas', mark: '◈', context: 'perfiles', tone: 'cyan' },
  { key: 'worlds', label: 'Mundos', mark: '◎', context: 'universos', tone: 'violet' },
  { key: 'explorers', label: 'Niños', mark: '△', context: 'representados', tone: 'lime' },
  { key: 'characters', label: 'Personajes', mark: '✦', context: 'activos', tone: 'coral' },
  { key: 'captures', label: 'Capturas', mark: '▣', context: 'en campo', tone: 'cyan' },
]
const weekRows = computed(() => dashboard.value.captures_by_week || [])
const rarityRows = computed(() => dashboard.value.rarity || [])
const worldRows = computed(() => dashboard.value.captures_by_world || [])
const families = computed(() => dashboard.value.families || [])
const topCharacters = computed(() => dashboard.value.top_characters || [])
const recentCaptures = computed(() => dashboard.value.recent_captures || [])
const recentWorlds = computed(() => dashboard.value.recent_worlds || [])
const mapCharacters = computed(() => dashboard.value.map_characters || [])
const weekMax = computed(() => Math.max(1, ...weekRows.value.map((row) => Number(row.count || 0))))
const rarityMax = computed(() => Math.max(1, ...rarityRows.value.map((row) => Number(row.count || 0))))
const worldMax = computed(() => Math.max(1, ...worldRows.value.map((row) => Number(row.captures || 0))))
const weekChartLabel = computed(() => weekRows.value.map((row) => `${formatWeekLabel(row.week)}: ${row.count}`).join(', '))
const fal = computed(() => {
  const used = Number(dashboard.value.providers?.fal?.estimated_used_usd || dashboard.value.video_spend_usd || 0)
  const budget = Number(dashboard.value.providers?.fal?.monthly_budget_usd || (dashboard.value.providers?.fal?.unit_cost_usd || 0.28) * 4)
  const available = credits.value.fal?.available
  const configured = Boolean(credits.value.fal?.configured)
  const live = Number.isFinite(available)
  return {
    used,
    budget,
    videos: Number(dashboard.value.providers?.fal?.videos || dashboard.value.videos || 0),
    configured,
    availableLabel: live ? formatCurrency(available) : formatCurrency(budget),
    availableHint: live ? 'crédito disponible' : 'tope mensual configurado',
    status: live ? 'Saldo vivo' : configured ? 'Clave activa' : 'Sin clave',
  }
})
const recraft = computed(() => {
  const available = credits.value.recraft?.available
  const configured = Boolean(credits.value.recraft?.configured)
  return {
    cutouts: Number(dashboard.value.providers?.recraft?.cutouts || 0),
    stylized: Number(dashboard.value.providers?.recraft?.stylized || 0),
    configured,
    availableLabel: Number.isFinite(available) ? formatNumber(available) : '—',
    status: Number.isFinite(available) ? 'Saldo vivo' : configured ? 'Clave activa' : 'Sin clave',
  }
})

onMounted(async () => {
  clock = window.setInterval(() => { now.value = new Date() }, 30000)
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) {
    router.replace('/ops/login')
    return
  }
  await loadDashboard()
})
onUnmounted(() => window.clearInterval(clock))

async function loadDashboard() {
  loading.value = true
  error.value = ''
  try {
    dashboard.value = await loadOpsDashboard()
    try {
      credits.value = await loadProviderCredits()
    } catch {
      credits.value = {}
    }
  } catch (err) {
    error.value = err.message ?? 'No se pudo sincronizar el dashboard.'
  } finally {
    ready.value = true
    loading.value = false
  }
}

function barHeight(value, max) {
  return `${Math.max(6, Math.round((Number(value || 0) / max) * 100))}%`
}

function barWidth(value, max) {
  return `${Math.max(value ? 8 : 0, Math.round((Number(value || 0) / max) * 100))}%`
}
</script>

<style scoped>
.topbar, .top-actions, .panel-head, .metric-top, .economy-meta { display: flex; align-items: center; }
.topbar { justify-content: space-between; gap: 1rem; margin-bottom: 1.6rem; }
.crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }
.crumb span { color: var(--ops-cyan); padding: 0 .35rem; }
h1, h2, h3 { margin: 0; color: var(--ops-text); }
h1 { font-family: var(--font-display); font-size: clamp(1.8rem, 4vw, 3.2rem); }
.top-actions { flex-wrap: wrap; justify-content: flex-end; gap: .7rem; }
.system-state, .refresh-button { display: inline-flex; align-items: center; gap: .5rem; border: 1px solid var(--ops-line); border-radius: 7px; padding: .55rem .75rem; color: var(--ops-muted); background: var(--ops-panel); font: inherit; font-size: .72rem; }
.refresh-button { color: var(--ops-text); cursor: pointer; }
.refresh-button span { color: var(--ops-cyan); font-size: 1rem; }
.system-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); }
.command-hero { display: flex; align-items: center; justify-content: space-between; gap: 1.5rem; margin-bottom: 1.25rem; padding: clamp(1.2rem, 3vw, 2.1rem); border: 1px solid var(--ops-line); border-radius: 14px; background: linear-gradient(105deg,#182442,#111a31 60%,#202348); }
.kicker, .panel-index { color: var(--ops-cyan); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }
.kicker span { margin-left: .8rem; color: var(--ops-muted); }
.command-hero h2 { font-family: var(--font-display); font-size: clamp(1.8rem, 5vw, 3.4rem); line-height: .96; }
.command-hero h2 em { color: var(--ops-cyan); font-style: normal; }
.hero-copy { max-width: 34rem; margin: 1rem 0 0; color: var(--ops-muted); font-size: .9rem; }
.hero-signal { display: grid; justify-items: center; gap: .55rem; color: var(--ops-muted); font-size: .62rem; letter-spacing: .08em; text-transform: uppercase; }
.signal-ring { display: grid; place-items: center; width: 104px; height: 104px; border: 1px solid var(--ops-cyan); border-radius: 50%; }
.signal-ring span { font-family: var(--font-display); font-size: 1.8rem; letter-spacing: 0; }
.signal-ring small { margin-top: -1.6rem; font-size: .52rem; }
.metric-grid, .provider-grid, .chart-grid, .family-grid, .character-grid, .dashboard-grid { display: grid; gap: .75rem; }
.metric-grid { grid-template-columns: repeat(5, minmax(0, 1fr)); margin-bottom: 1.25rem; }
.provider-grid { grid-template-columns: 1fr 1fr; margin-bottom: 1.25rem; }
.chart-grid { grid-template-columns: 1.1fr .8fr .9fr; margin-bottom: 1.25rem; }
.family-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.character-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
.dashboard-grid { grid-template-columns: 1.2fr .8fr; }
.metric-card, .panel, .family-section, .character-section { min-width: 0; padding: clamp(.85rem, 2vw, 1.2rem); border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
.metric-card { border-top: 2px solid var(--metric-color); }
.tone-cyan { --metric-color: var(--ops-cyan); }
.tone-violet { --metric-color: var(--ops-violet); }
.tone-lime { --metric-color: var(--ops-lime); }
.tone-coral { --metric-color: var(--ops-coral); }
.metric-top { justify-content: space-between; color: var(--metric-color); }
.metric-trend, .panel-status, .panel-link, .h-bar span, .h-bar small, .family-world p, .character-card small { color: var(--ops-muted); font-size: .68rem; }
.metric-card strong { display: block; margin-top: .85rem; font-family: var(--font-display); font-size: clamp(1.5rem, 3vw, 2rem); }
.metric-label { color: var(--ops-muted); font-size: .74rem; }
.family-section, .character-section { margin-bottom: 1.25rem; }
.panel-head { justify-content: space-between; gap: .7rem; margin-bottom: 1rem; }
.panel-head > div { display: flex; align-items: center; gap: .65rem; }
.panel h3, .family-section h3, .character-section h3 { font-size: .98rem; }
.panel-link { color: var(--ops-cyan); text-decoration: none; }
.week-chart { display: grid; grid-template-columns: repeat(8, minmax(0, 1fr)); gap: .4rem; align-items: end; min-height: 170px; }
.week-col { display: grid; justify-items: center; gap: .3rem; color: var(--ops-muted); font-size: .6rem; }
.week-col small { color: var(--ops-text); }
.week-track { display: flex; align-items: flex-end; width: 100%; height: 120px; border-radius: 8px; background: rgba(86,215,237,.06); }
.week-track i { display: block; width: 100%; border-radius: 8px 8px 3px 3px; background: linear-gradient(180deg, var(--ops-cyan), #2d8ea3); }
.h-bars { display: grid; gap: .7rem; }
.h-bar-meta, .character-meta { display: flex; justify-content: space-between; gap: .6rem; }
.h-bar strong, .family-world strong, .character-card strong { font-size: .8rem; }
.h-track { overflow: hidden; height: 8px; margin: .35rem 0 .15rem; border-radius: 99px; background: rgba(255,255,255,.06); }
.h-track i { display: block; height: 100%; border-radius: inherit; }
.h-track .rarity-common { background: var(--ops-lime); }
.h-track .rarity-rare { background: var(--ops-cyan); }
.h-track .rarity-epic { background: var(--ops-violet); }
.character-meta .rarity-common { color: var(--ops-lime); }
.character-meta .rarity-rare { color: var(--ops-cyan); }
.character-meta .rarity-epic { color: var(--ops-violet); }
.world-fill { background: var(--ops-coral); }
.family-card { padding: 1rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #10182b; }
.family-parent { display: flex; align-items: center; gap: .7rem; margin-bottom: .85rem; }
.family-parent span, .world-avatar, .character-fallback, .activity-badge { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 8px; background: rgba(86,215,237,.12); color: var(--ops-cyan); font-size: .7rem; font-weight: 900; }
.family-parent small { display: block; margin-top: .15rem; color: var(--ops-muted); font-size: .68rem; }
.family-tree { display: grid; gap: .7rem; padding-left: .85rem; border-left: 1px solid var(--ops-line); }
.world-title { display: flex; justify-content: space-between; gap: .6rem; }
.world-title em, .character-meta em { font-style: normal; font-size: .62rem; letter-spacing: .08em; text-transform: uppercase; }
.kid-row { display: flex; flex-wrap: wrap; gap: .35rem; margin: .4rem 0 .25rem; }
.kid-chip, .kid-empty { display: inline-flex; padding: .2rem .5rem; border-radius: 99px; background: rgba(184,232,92,.12); color: var(--ops-lime); font-size: .68rem; }
.kid-empty { background: rgba(255,255,255,.04); color: var(--ops-muted); }
.character-card { display: grid; grid-template-columns: 72px minmax(0, 1fr); gap: .75rem; align-items: center; padding: .75rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #10182b; }
.character-card img, .activity-photo { width: 72px; height: 72px; border-radius: 10px; object-fit: cover; background: #0d1527; }
.character-fallback { width: 72px; height: 72px; border-radius: 10px; background: rgba(158,140,255,.12); color: var(--ops-violet); }
.character-meta { margin-top: .4rem; }
.activity-panel { grid-row: span 2; }
.activity-row, .world-row { display: grid; grid-template-columns: 32px minmax(0, 1fr) auto; align-items: center; gap: .7rem; padding: .76rem 0; border-top: 1px solid var(--ops-line); }
.activity-row:first-child, .world-row:first-child { border-top: 0; }
.activity-photo { width: 32px; height: 32px; border-radius: 8px; }
.activity-row strong, .world-row strong { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: .8rem; }
.activity-row small, .world-row small { display: block; margin-top: .12rem; color: var(--ops-muted); font-size: .68rem; }
.activity-row time { color: var(--ops-muted); font-size: .66rem; white-space: nowrap; }
.world-avatar { background: rgba(184,232,92,.12); color: var(--ops-lime); }
.world-state { color: var(--ops-lime); font-size: .58rem; font-weight: 900; letter-spacing: .08em; text-transform: uppercase; }
.economy-main { padding: .2rem 0 .9rem; border-bottom: 1px solid var(--ops-line); }
.economy-main strong { display: block; font-family: var(--font-display); font-size: clamp(1.5rem, 3vw, 2rem); }
.economy-main span { color: var(--ops-muted); font-size: .7rem; }
.economy-meta { flex-wrap: wrap; gap: .85rem; padding-top: .9rem; color: var(--ops-muted); font-size: .68rem; }
.error-banner { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }
.loading-state { color: var(--ops-muted); }
@media (max-width: 1200px) {
  .metric-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  .chart-grid, .character-grid { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 900px) {
  .topbar, .command-hero, .panel-head { align-items: flex-start; flex-direction: column; }
  .top-actions { justify-content: flex-start; }
  .hero-signal { align-self: center; }
  .provider-grid, .family-grid, .dashboard-grid, .metric-grid { grid-template-columns: 1fr 1fr; }
  .activity-panel { grid-row: auto; }
  .week-chart { grid-template-columns: repeat(4, minmax(0, 1fr)); }
}
@media (max-width: 640px) {
  .metric-grid, .provider-grid, .chart-grid, .family-grid, .character-grid, .dashboard-grid { grid-template-columns: 1fr; }
  .activity-row, .world-row { grid-template-columns: 32px minmax(0, 1fr); }
  .activity-row time, .world-state { grid-column: 2; }
}
</style>
