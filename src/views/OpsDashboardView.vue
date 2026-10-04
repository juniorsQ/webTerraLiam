<template>
  <OpsShell>
    <header class="topbar">
      <div>
        <p class="crumb">TerraLiam <span>/</span> Backoffice</p>
        <h1>Centro de control</h1>
      </div>
      <div class="top-actions">
        <span class="sync-state"><i :class="{ busy: loading }" /> {{ syncLabel }}</span>
        <button class="ops-btn" type="button" :disabled="loading" @click="loadDashboard">{{ loading ? 'Actualizando…' : 'Actualizar ↻' }}</button>
      </div>
    </header>

    <p v-if="error" class="ops-error">{{ error }}</p>
    <p v-else-if="!ready" class="ops-muted">Cargando operación…</p>
    <template v-else>
      <!-- 1. What needs a human right now -->
      <section class="attention" aria-label="Requiere atención">
        <header>
          <h2>{{ alerts.length ? 'Requiere atención' : 'Todo en orden' }}</h2>
          <p>{{ alerts.length ? 'Toca una alerta para ir directo a la lista filtrada.' : 'No hay premios pendientes, reportes abiertos ni jobs atascados.' }}</p>
        </header>
        <div v-if="alerts.length" class="alert-grid">
          <router-link v-for="item in alerts" :key="item.key" :to="item.to" class="alert-card" :class="`level-${item.level}`">
            <span class="alert-icon" aria-hidden="true">{{ item.level === 'bad' ? '!' : item.level === 'warn' ? '◆' : 'i' }}</span>
            <span class="alert-text">
              <strong>{{ formatNumber(item.count) }} {{ item.title }}</strong>
              <small>{{ item.detail }}</small>
            </span>
            <span class="alert-go">→</span>
          </router-link>
        </div>
      </section>

      <!-- 2. Headline KPIs with week-over-week -->
      <section class="kpi-grid" aria-label="Indicadores">
        <router-link v-for="kpi in kpis" :key="kpi.key" :to="kpi.to" class="kpi" :title="kpi.help">
          <span class="kpi-label">{{ kpi.label }}</span>
          <strong>{{ formatNumber(kpi.value) }}</strong>
          <span class="kpi-week">
            <template v-if="kpi.d7 !== undefined">+{{ formatNumber(kpi.d7) }} esta semana · <em :class="`tone-text-${kpi.delta.tone}`">{{ kpi.delta.label }}</em></template>
            <template v-else>{{ kpi.note }}</template>
          </span>
        </router-link>
      </section>

      <!-- 3. Activity trend + activation funnel -->
      <section class="row-2">
        <article class="ops-panel">
          <header class="ops-panel-head">
            <div>
              <h3>Actividad diaria · 30 días</h3>
              <p>{{ seriesMeta.help }}</p>
            </div>
            <div class="seg" role="tablist" aria-label="Serie">
              <button v-for="item in seriesOptions" :key="item.key" type="button" role="tab" :aria-selected="series === item.key" :class="{ active: series === item.key }" @click="series = item.key">
                {{ item.label }}
              </button>
            </div>
          </header>
          <div class="trend-total">
            <strong>{{ formatNumber(seriesTotal) }}</strong>
            <span>{{ seriesMeta.label.toLowerCase() }} en 30 días · máx. {{ formatNumber(seriesMax) }}/día</span>
          </div>
          <div class="bars" role="img" :aria-label="trendLabel" @mouseleave="hoverDay = null">
            <div
              v-for="(day, index) in daily"
              :key="day.day"
              class="bar-hit"
              :class="{ hover: hoverDay === index }"
              @mouseenter="hoverDay = index"
              @focus="hoverDay = index"
              tabindex="0"
            >
              <i :style="{ height: barHeight(day[series], seriesMax) }" />
            </div>
            <div v-if="hoverDay !== null" class="bar-tip" :style="tipStyle">
              <strong>{{ formatNumber(daily[hoverDay][series]) }}</strong> {{ seriesMeta.label.toLowerCase() }}
              <small>{{ formatDayLabel(daily[hoverDay].day) }}</small>
            </div>
          </div>
          <div class="bars-axis">
            <span>{{ formatDayLabel(daily[0]?.day) }}</span>
            <span>{{ formatDayLabel(daily[14]?.day) }}</span>
            <span>Hoy</span>
          </div>
        </article>

        <article class="ops-panel">
          <header class="ops-panel-head">
            <div>
              <h3>Activación de familias</h3>
              <p>Adultos que avanzan en cada paso del juego (sin admins).</p>
            </div>
          </header>
          <ol class="funnel">
            <li v-for="(step, index) in funnel" :key="step.key">
              <router-link :to="step.to" class="funnel-row">
                <span class="funnel-meta">
                  <strong>{{ step.label }}</strong>
                  <span>{{ formatNumber(step.count) }} <em v-if="index">{{ formatPercent(step.rate) }} del paso anterior</em></span>
                </span>
                <span class="funnel-track"><i :style="{ width: barWidth(step.count, funnel[0].count) }" /></span>
              </router-link>
            </li>
          </ol>
          <p v-if="funnelLeak" class="funnel-note">Mayor fuga: <strong>{{ funnelLeak }}</strong></p>
        </article>
      </section>

      <!-- 4. AI economy -->
      <section class="row-2">
        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Fal.ai · videos de premio</h3><p>Gasto estimado del mes contra el tope configurado.</p></div>
            <router-link to="/ops/settings" class="ops-panel-link">Ajustar tope →</router-link>
          </header>
          <div class="budget">
            <div class="budget-numbers">
              <strong>{{ formatCurrency(economy.video_spend_month_usd) }}</strong>
              <span>de {{ formatCurrency(economy.monthly_budget_usd) }} este mes</span>
            </div>
            <span class="ops-badge" :class="`tone-${budgetTone}`">{{ formatPercent(budgetRatio) }} usado</span>
          </div>
          <div class="meter" :class="`meter-${budgetTone}`" role="meter" :aria-valuenow="Math.round(budgetRatio * 100)" aria-valuemin="0" aria-valuemax="100" aria-label="Presupuesto Fal usado">
            <i :style="{ width: `${Math.min(100, budgetRatio * 100)}%` }" />
          </div>
          <dl class="econ-grid">
            <div><dt>Videos este mes</dt><dd>{{ formatNumber(economy.videos_month) }}</dd></div>
            <div><dt>Costo por video</dt><dd>{{ formatCurrency(economy.unit_cost_usd) }}</dd></div>
            <div><dt>Límite por mundo</dt><dd>{{ formatNumber(economy.max_videos_per_world_per_month) }}/mes</dd></div>
            <div><dt>Histórico</dt><dd>{{ formatCurrency(economy.video_spend_total_usd) }} · {{ formatNumber(economy.videos_total) }} videos</dd></div>
            <div>
              <dt>Saldo en Fal</dt>
              <dd>{{ falBalance }}</dd>
            </div>
            <div>
              <dt>Fallidos / atascados</dt>
              <dd><router-link to="/ops/video-jobs?filter=failed">{{ formatNumber(economy.jobs_failed_month) }}</router-link> / <router-link to="/ops/video-jobs?filter=processing">{{ formatNumber(economy.jobs_stuck) }}</router-link></dd>
            </div>
          </dl>
        </article>

        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Recraft · recortes y estilizado</h3><p>Créditos consumidos al procesar fotos de personajes.</p></div>
            <router-link to="/ops/provider-jobs?filter=recraft" class="ops-panel-link">Ledger →</router-link>
          </header>
          <div class="budget">
            <div class="budget-numbers">
              <strong>{{ recraftBalance }}</strong>
              <span>{{ recraftBalanceHint }}</span>
            </div>
            <span v-if="recraftLow" class="ops-badge tone-bad">Bajo el umbral</span>
          </div>
          <dl class="econ-grid">
            <div><dt>Créditos este mes</dt><dd>{{ formatNumber(economy.recraft_credits_month) }}</dd></div>
            <div><dt>Créditos históricos</dt><dd>{{ formatNumber(economy.recraft_credits_total) }}</dd></div>
            <div><dt>Recortes</dt><dd>{{ formatNumber(economy.cutouts) }}</dd></div>
            <div><dt>Estilizados</dt><dd>{{ formatNumber(economy.stylized) }}</dd></div>
            <div><dt>Umbral de alerta</dt><dd>{{ formatNumber(economy.recraft_alert_threshold) }}</dd></div>
          </dl>
        </article>
      </section>

      <!-- 5. Worlds ranking + rarity -->
      <section class="row-2 wide-left">
        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Mundos más activos</h3><p>Ordenados por capturas de los últimos 7 días.</p></div>
            <router-link to="/ops/worlds" class="ops-panel-link">Todos →</router-link>
          </header>
          <table class="mini-table">
            <thead><tr><th>Mundo</th><th>Niños</th><th>Personajes</th><th>Capturas</th><th>7d</th><th>Última</th></tr></thead>
            <tbody>
              <tr v-for="world in topWorlds" :key="world.id" tabindex="0" @click="go(`/ops/worlds/${world.id}`)" @keydown.enter="go(`/ops/worlds/${world.id}`)">
                <td>
                  <strong>{{ world.name }}</strong>
                  <router-link :to="`/ops/users/${world.owner_id}`" class="sub-link" @click.stop>{{ world.owner }}</router-link>
                </td>
                <td>{{ formatNumber(world.kids) }}</td>
                <td>{{ formatNumber(world.characters) }}</td>
                <td>{{ formatNumber(world.captures) }}</td>
                <td><span :class="world.captures_7d ? 'tone-text-good' : 'ops-muted'">{{ formatNumber(world.captures_7d) }}</span></td>
                <td class="ops-muted">{{ formatRelative(world.last_capture_at) }}</td>
              </tr>
              <tr v-if="!topWorlds.length"><td colspan="6" class="ops-muted">Aún no hay mundos.</td></tr>
            </tbody>
          </table>
        </article>

        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Rareza</h3><p>Personajes visibles y qué tanto se capturan.</p></div>
          </header>
          <div class="rarity-list">
            <router-link v-for="row in rarityRows" :key="row.key" :to="`/ops/pois?filter=${row.key}`" class="rarity-row">
              <span class="rarity-meta">
                <strong>{{ labelRarity(row.key) }}</strong>
                <span>{{ formatNumber(row.count) }} personajes · {{ formatNumber(row.captures) }} capturas</span>
              </span>
              <span class="h-track"><i :class="`fill-${row.key}`" :style="{ width: barWidth(row.count, rarityMax) }" /></span>
              <small>{{ row.count ? (row.captures / row.count).toFixed(1) : '0' }} capturas por personaje</small>
            </router-link>
            <p v-if="!rarityRows.length" class="ops-muted">Sin personajes activos.</p>
          </div>
        </article>
      </section>

      <OpsMap :characters="mapCharacters" />

      <!-- 6. Characters + live feed -->
      <section class="row-2 wide-left">
        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Personajes más capturados</h3></div>
            <router-link to="/ops/pois" class="ops-panel-link">Todos →</router-link>
          </header>
          <div class="character-grid">
            <router-link v-for="character in topCharacters" :key="character.id" :to="`/ops/pois/${character.id}`" class="character-card">
              <img v-if="character.image" :src="character.image" :alt="character.name" loading="lazy" />
              <span v-else class="character-fallback">{{ initials(character.name) }}</span>
              <span class="character-body">
                <strong>{{ character.name }}</strong>
                <small>{{ character.world }}</small>
                <span class="character-meta">
                  <span class="ops-badge" :class="`tone-${character.rarity}`">{{ labelRarity(character.rarity) }}</span>
                  <span>{{ formatNumber(character.captures) }} capt.</span>
                  <span v-if="character.has_video" title="Tiene video IA">▶</span>
                </span>
              </span>
            </router-link>
            <p v-if="!topCharacters.length" class="ops-muted">Sin personajes.</p>
          </div>
        </article>

        <article class="ops-panel">
          <header class="ops-panel-head">
            <div><h3>Actividad reciente</h3><p>Capturas, mundos, cuentas, premios y reportes.</p></div>
            <router-link to="/ops/captures" class="ops-panel-link">Capturas →</router-link>
          </header>
          <ul class="feed">
            <li v-for="item in activity" :key="`${item.kind}-${item.target_id}`">
              <router-link :to="activityLink(item)" class="feed-row">
                <img v-if="item.image" :src="item.image" alt="" loading="lazy" />
                <span v-else class="feed-icon" :class="`kind-${item.kind}`">{{ kindIcon[item.kind] }}</span>
                <span class="feed-text">
                  <strong>{{ item.title }}</strong>
                  <small>{{ item.detail }}</small>
                </span>
                <time :datetime="item.at" :title="formatDateTime(item.at)">{{ formatRelative(item.at) }}</time>
              </router-link>
            </li>
            <li v-if="!activity.length" class="ops-muted">Sin actividad todavía.</li>
          </ul>
        </article>
      </section>

      <!-- 7. System -->
      <section class="system-grid" aria-label="Sistema">
        <router-link v-for="item in systemCards" :key="item.label" :to="item.to" class="system-card">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
          <small>{{ item.detail }}</small>
        </router-link>
      </section>
    </template>
  </OpsShell>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import OpsMap from '@/ops/OpsMap.vue'
import OpsShell from '@/ops/OpsShell.vue'
import { loadOverview, loadProviderCredits } from '@/ops/opsApi'
import {
  delta, formatBytes, formatCurrency, formatDateTime, formatDayLabel, formatNumber, formatPercent,
  formatRelative, initials, labelRarity,
} from '@/ops/opsUi'

const router = useRouter()
const dashboard = ref({})
const credits = ref({})
const ready = ref(false)
const loading = ref(false)
const error = ref('')
const loadedAt = ref(null)
const now = ref(Date.now())
const series = ref('captures')
const hoverDay = ref(null)
let clock

const seriesOptions = [
  { key: 'captures', label: 'Capturas', help: 'Personajes encontrados por los jugadores cada día.' },
  { key: 'characters', label: 'Personajes', help: 'Personajes nuevos escondidos por los adultos.' },
  { key: 'accounts', label: 'Cuentas', help: 'Altas de cuentas adultas (sin cuentas de niño).' },
]
const kindIcon = { capture: '▣', world: '◎', character: '✦', account: '◈', prize: '◇', report: '⚠' }

const k = computed(() => dashboard.value.kpis || {})
const attention = computed(() => dashboard.value.attention || {})
const economy = computed(() => dashboard.value.economy || {})
const daily = computed(() => dashboard.value.daily || [])
const topWorlds = computed(() => dashboard.value.top_worlds || [])
const topCharacters = computed(() => dashboard.value.top_characters || [])
const rarityRows = computed(() => dashboard.value.rarity || [])
const activity = computed(() => dashboard.value.activity || [])
const mapCharacters = computed(() => dashboard.value.map_characters || [])
const rarityMax = computed(() => Math.max(1, ...rarityRows.value.map((row) => Number(row.count || 0))))

const syncLabel = computed(() => {
  if (loading.value) return 'Sincronizando…'
  if (!loadedAt.value) return 'Sin datos'
  void now.value
  return `Actualizado ${formatRelative(loadedAt.value)}`
})

const kpis = computed(() => [
  kpi('adults', 'Cuentas adultas', '/ops/users?filter=adult', 'Padres, madres o tutores registrados (incluye admins).'),
  kpi('kids', 'Niños exploradores', '/ops/explorers', 'Exploradores creados dentro de los mundos.'),
  kpi('worlds', 'Mundos', '/ops/worlds', 'Mundos (familias) creados.'),
  kpi('characters', 'Personajes visibles', '/ops/pois', 'Personajes activos en el mapa. "Esta semana" cuenta los nuevos.'),
  kpi('captures', 'Capturas', '/ops/captures', 'Personajes encontrados por los jugadores.'),
  {
    key: 'active',
    label: 'Jugadores activos 7d',
    value: k.value.active_7d,
    note: `${formatNumber(k.value.active_30d)} en 30 días`,
    to: '/ops/progress',
    help: 'Cuentas con captura, evento, progreso o inicio de sesión en los últimos 7 días.',
  },
])

function kpi(key, label, to, help) {
  const item = k.value[key] || {}
  return { key, label, to, help, value: item.total, d7: item.d7, delta: delta(item.d7, item.prev7) }
}

const alerts = computed(() => {
  const a = attention.value
  const list = [
    { key: 'prizes', level: 'bad', count: a.pending_prizes, title: ['premio por aprobar', 'premios por aprobar'], detail: 'Niños esperando su recompensa.', to: '/ops/prize-grants?filter=pending' },
    { key: 'reports', level: 'bad', count: a.open_reports, title: ['reporte abierto', 'reportes abiertos'], detail: 'Contenido señalado por familias.', to: '/ops/reports?filter=open' },
    { key: 'stuck', level: 'bad', count: a.stuck_jobs, title: ['video atascado', 'videos atascados'], detail: 'Más de 30 min en cola o procesando.', to: '/ops/video-jobs?filter=processing' },
    { key: 'failed', level: 'warn', count: a.failed_jobs_7d, title: ['video fallido (7d)', 'videos fallidos (7d)'], detail: 'Revisa el error de Fal.', to: '/ops/video-jobs?filter=failed' },
    { key: 'budget', level: budgetRatio.value >= 1 ? 'bad' : 'warn', count: budgetRatio.value >= 0.8 ? Math.round(budgetRatio.value * 100) : 0, title: '% del tope de Fal usado', detail: 'Al llegar al 100% conviene subir el tope o pausar videos.', to: '/ops/settings' },
    { key: 'no_world', level: 'info', count: a.adults_without_world, title: ['adulto sin mundo', 'adultos sin mundo'], detail: 'Se registraron pero no crearon su mundo.', to: '/ops/users?filter=no_world' },
    { key: 'empty', level: 'info', count: a.worlds_without_characters, title: ['mundo sin personajes', 'mundos sin personajes'], detail: 'La familia no escondió nada aún.', to: '/ops/worlds?filter=empty' },
    { key: 'never', level: 'info', count: a.characters_never_captured, title: ['personaje nunca capturado', 'personajes nunca capturados'], detail: 'Posible ubicación difícil o mundo inactivo.', to: '/ops/pois?filter=never_captured' },
    { key: 'dormant', level: 'info', count: a.dormant_worlds, title: ['mundo dormido', 'mundos dormidos'], detail: 'Sin capturas en 30 días.', to: '/ops/worlds?filter=dormant' },
    { key: 'orphan', level: 'info', count: a.orphan_accounts, title: ['cuenta sin perfil', 'cuentas sin perfil'], detail: 'Usuarios de Auth sin fila en profiles.', to: '/ops/users?filter=orphan' },
  ]
  return list
    .filter((item) => Number(item.count) > 0)
    .map((item) => ({ ...item, title: Array.isArray(item.title) ? item.title[Number(item.count) === 1 ? 0 : 1] : item.title }))
})

const funnel = computed(() => {
  const f = dashboard.value.funnel || {}
  const steps = [
    { key: 'accounts', label: 'Se registró', count: f.accounts, to: '/ops/users?filter=adult' },
    { key: 'with_world', label: 'Creó su mundo', count: f.with_world, to: '/ops/worlds' },
    { key: 'with_character', label: 'Escondió un personaje', count: f.with_character, to: '/ops/pois' },
    { key: 'with_kid', label: 'Y agregó un niño', count: f.with_kid, to: '/ops/explorers' },
    { key: 'with_capture', label: 'Y su familia capturó algo', count: f.with_capture, to: '/ops/captures' },
  ]
  return steps.map((step, index) => ({
    ...step,
    count: Number(step.count || 0),
    rate: index && steps[index - 1].count ? Number(step.count || 0) / Number(steps[index - 1].count) : 0,
  }))
})

const funnelLeak = computed(() => {
  const steps = funnel.value.slice(1).filter((step, index) => funnel.value[index].count > 0)
  if (!steps.length) return ''
  const worst = steps.reduce((min, step) => (step.rate < min.rate ? step : min))
  return worst.rate < 1 ? `«${worst.label}» (${formatPercent(worst.rate)})` : ''
})

const seriesMeta = computed(() => seriesOptions.find((item) => item.key === series.value))
const seriesMax = computed(() => Math.max(0, ...daily.value.map((day) => Number(day[series.value] || 0))))
const seriesTotal = computed(() => daily.value.reduce((sum, day) => sum + Number(day[series.value] || 0), 0))
const trendLabel = computed(() => `${seriesMeta.value.label} por día, últimos 30 días: total ${seriesTotal.value}`)
const tipStyle = computed(() => {
  const pct = ((hoverDay.value + 0.5) / Math.max(1, daily.value.length)) * 100
  return { left: `clamp(60px, ${pct}%, calc(100% - 60px))` }
})

const budgetRatio = computed(() => {
  const budget = Number(economy.value.monthly_budget_usd || 0)
  return budget ? Number(economy.value.video_spend_month_usd || 0) / budget : 0
})
const budgetTone = computed(() => (budgetRatio.value >= 1 ? 'bad' : budgetRatio.value >= 0.8 ? 'warn' : 'good'))

const falBalance = computed(() => {
  const fal = credits.value.fal
  if (Number.isFinite(fal?.available)) return formatCurrency(fal.available)
  if (fal?.configured) return 'Clave activa (saldo no disponible)'
  return 'Sin clave en Vault'
})
const recraftBalance = computed(() => {
  const value = credits.value.recraft?.available
  return Number.isFinite(value) ? formatNumber(value) : '—'
})
const recraftBalanceHint = computed(() => {
  if (Number.isFinite(credits.value.recraft?.available)) return 'créditos disponibles en Recraft (en vivo)'
  return credits.value.recraft?.configured ? 'Clave activa, saldo no disponible' : 'Sin clave de Recraft en Vault'
})
const recraftLow = computed(() => {
  const value = credits.value.recraft?.available
  return Number.isFinite(value) && value < Number(economy.value.recraft_alert_threshold || 0)
})

const systemCards = computed(() => {
  const s = dashboard.value.system || {}
  return [
    { label: 'Archivos', value: formatBytes(s.storage_bytes), detail: `${formatNumber(s.storage_files)} en poi-media`, to: '/ops/storage' },
    { label: 'Códigos de acceso', value: formatNumber(s.tokens_active), detail: `vigentes · ${formatNumber(s.tokens_used)} usados`, to: '/ops/pair-tokens?filter=active' },
    { label: 'Misiones', value: formatNumber(s.missions_active), detail: `activas de ${formatNumber(s.missions)}`, to: '/ops/missions' },
    { label: 'Eventos app 7d', value: formatNumber(s.analytics_events_7d), detail: 'analytics_events', to: '/ops/analytics' },
    { label: 'Cuentas de niño', value: formatNumber(k.value.kid_accounts), detail: 'asientos @kid', to: '/ops/users?filter=kid' },
    { label: 'Acciones Ops 7d', value: formatNumber(s.audit_7d), detail: `${formatNumber(s.admins)} admins`, to: '/ops/audit' },
  ]
})

onMounted(() => {
  clock = window.setInterval(() => { now.value = Date.now() }, 30000)
  loadDashboard()
})
onBeforeUnmount(() => window.clearInterval(clock))

async function loadDashboard() {
  loading.value = true
  error.value = ''
  try {
    const [overview, providerCredits] = await Promise.all([
      loadOverview(),
      loadProviderCredits().catch(() => ({})),
    ])
    dashboard.value = overview || {}
    credits.value = providerCredits || {}
    loadedAt.value = new Date().toISOString()
  } catch (err) {
    error.value = err.message ?? 'No se pudo sincronizar el dashboard.'
  } finally {
    ready.value = true
    loading.value = false
  }
}

function activityLink(item) {
  const detail = ['users', 'worlds', 'pois', 'captures'].includes(item.resource)
  return detail ? `/ops/${item.resource}/${item.target_id}` : `/ops/${item.resource}`
}

function go(path) {
  router.push(path)
}

function barHeight(value, max) {
  if (!max) return '0%'
  return `${Math.max(Number(value) ? 4 : 0, Math.round((Number(value || 0) / max) * 100))}%`
}

function barWidth(value, max) {
  if (!max) return '0%'
  return `${Math.max(Number(value) ? 3 : 0, Math.round((Number(value || 0) / max) * 100))}%`
}
</script>

<style scoped>
.topbar { display: flex; align-items: flex-end; justify-content: space-between; gap: 1rem; margin-bottom: 1.4rem; }
h1 { margin: 0; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(1.8rem, 4vw, 2.9rem); }
h2 { margin: 0; color: var(--ops-text); font-size: 1rem; }
.top-actions { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }
.sync-state { display: inline-flex; align-items: center; gap: .45rem; color: var(--ops-muted); font-size: .72rem; }
.sync-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); }
.sync-state i.busy { background: #ffc457; }
.tone-text-good { color: var(--ops-lime); }
.tone-text-bad { color: var(--ops-coral); }
.tone-text-neutral { color: var(--ops-muted); }

.attention { margin-bottom: 1rem; padding: 1rem 1.1rem; border: 1px solid var(--ops-line); border-radius: 12px; background: linear-gradient(100deg, #172341, #121a2d 70%); }
.attention header { display: flex; align-items: baseline; gap: .8rem; flex-wrap: wrap; margin-bottom: .8rem; }
.attention header p { margin: 0; color: var(--ops-muted); font-size: .76rem; }
.attention:has(.alert-grid) header { margin-bottom: .8rem; }
.alert-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: .55rem; }
.alert-card { display: grid; grid-template-columns: 28px minmax(0, 1fr) auto; align-items: center; gap: .65rem; padding: .65rem .75rem; border: 1px solid var(--ops-line); border-radius: 10px; background: rgba(11,16,32,.55); color: inherit; text-decoration: none; }
.alert-card:hover { border-color: rgba(86,215,237,.45); }
.alert-icon { display: grid; place-items: center; width: 28px; height: 28px; border-radius: 8px; font-weight: 900; font-size: .8rem; }
.level-bad .alert-icon { background: rgba(255,124,120,.16); color: var(--ops-coral); }
.level-warn .alert-icon { background: rgba(255,196,87,.16); color: #ffc457; }
.level-info .alert-icon { background: rgba(86,215,237,.12); color: var(--ops-cyan); }
.alert-text { display: grid; min-width: 0; }
.alert-text strong { color: var(--ops-text); font-size: .82rem; }
.alert-text small { color: var(--ops-muted); font-size: .7rem; }
.alert-go { color: var(--ops-muted); }

.kpi-grid { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: .65rem; margin-bottom: 1rem; }
.kpi { display: grid; gap: .3rem; padding: .95rem 1rem; border: 1px solid var(--ops-line); border-radius: 12px; background: var(--ops-panel); color: inherit; text-decoration: none; transition: border-color .15s, transform .15s; }
.kpi:hover { border-color: rgba(86,215,237,.45); transform: translateY(-1px); }
.kpi-label { color: var(--ops-muted); font-size: .72rem; }
.kpi strong { color: var(--ops-text); font-family: var(--font-display); font-size: clamp(1.5rem, 2.6vw, 2rem); font-variant-numeric: tabular-nums; }
.kpi-week { color: var(--ops-muted); font-size: .66rem; line-height: 1.4; }
.kpi-week em { font-style: normal; }

.row-2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; margin-bottom: 1rem; }
.row-2.wide-left { grid-template-columns: minmax(0, 1.35fr) minmax(0, 1fr); }

.seg { display: inline-flex; padding: 3px; border: 1px solid var(--ops-line); border-radius: 9px; background: #0d1527; }
.seg button { min-height: 28px; padding: 0 .6rem; border: 0; border-radius: 6px; background: transparent; color: var(--ops-muted); font: inherit; font-size: .7rem; cursor: pointer; }
.seg button.active { background: var(--ops-panel-2); color: var(--ops-text); font-weight: 800; }
.trend-total { display: flex; align-items: baseline; gap: .55rem; margin-bottom: .7rem; }
.trend-total strong { color: var(--ops-text); font-family: var(--font-display); font-size: 1.6rem; }
.trend-total span { color: var(--ops-muted); font-size: .72rem; }
.bars { position: relative; display: grid; grid-template-columns: repeat(30, minmax(0, 1fr)); align-items: end; height: 150px; border-bottom: 1px solid var(--ops-line); }
.bar-hit { display: flex; align-items: flex-end; justify-content: center; height: 100%; padding: 0 1px; cursor: default; outline: none; }
.bar-hit i { display: block; width: 100%; max-width: 14px; border-radius: 4px 4px 0 0; background: var(--ops-cyan); opacity: .85; }
.bar-hit.hover { background: rgba(86,215,237,.06); }
.bar-hit.hover i { opacity: 1; }
.bar-tip { position: absolute; top: -6px; transform: translate(-50%, -100%); display: grid; padding: .4rem .6rem; border: 1px solid var(--ops-line); border-radius: 8px; background: #0b1020; color: var(--ops-text); font-size: .74rem; white-space: nowrap; pointer-events: none; box-shadow: 0 8px 24px rgba(0,0,0,.35); }
.bar-tip small { color: var(--ops-muted); font-size: .66rem; }
.bars-axis { display: flex; justify-content: space-between; margin-top: .35rem; color: var(--ops-muted); font-size: .64rem; }

.funnel { display: grid; gap: .55rem; margin: 0; padding: 0; list-style: none; }
.funnel-row { display: grid; gap: .3rem; color: inherit; text-decoration: none; }
.funnel-row:hover strong { color: var(--ops-cyan); }
.funnel-meta { display: flex; justify-content: space-between; gap: .6rem; font-size: .78rem; }
.funnel-meta strong { color: var(--ops-text); }
.funnel-meta > span { color: var(--ops-text); font-variant-numeric: tabular-nums; }
.funnel-meta em { margin-left: .35rem; color: var(--ops-muted); font-style: normal; font-size: .68rem; }
.funnel-track, .h-track { display: block; overflow: hidden; height: 10px; border-radius: 99px; background: rgba(255,255,255,.06); }
.funnel-track i, .h-track i { display: block; height: 100%; border-radius: 99px; background: var(--ops-cyan); }
.funnel-note { margin: .9rem 0 0; color: var(--ops-muted); font-size: .74rem; }
.funnel-note strong { color: #ffc457; }

.budget { display: flex; align-items: center; justify-content: space-between; gap: .8rem; margin-bottom: .7rem; }
.budget-numbers strong { display: block; color: var(--ops-text); font-family: var(--font-display); font-size: 1.7rem; }
.budget-numbers span { color: var(--ops-muted); font-size: .74rem; }
.meter { overflow: hidden; height: 10px; margin-bottom: 1rem; border-radius: 99px; background: rgba(255,255,255,.06); }
.meter i { display: block; height: 100%; border-radius: 99px; }
.meter-good i { background: var(--ops-lime); }
.meter-warn i { background: #ffc457; }
.meter-bad i { background: var(--ops-coral); }
.econ-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: .7rem 1rem; margin: 0; padding-top: .8rem; border-top: 1px solid var(--ops-line); }
.econ-grid dt { color: var(--ops-muted); font-size: .66rem; }
.econ-grid dd { margin: .15rem 0 0; color: var(--ops-text); font-size: .84rem; font-weight: 700; }
.econ-grid a { color: var(--ops-cyan); text-decoration: none; }

.mini-table { width: 100%; border-collapse: collapse; font-size: .78rem; }
.mini-table th { padding: 0 .5rem .5rem; color: var(--ops-muted); font-size: .62rem; font-weight: 800; letter-spacing: .06em; text-align: left; text-transform: uppercase; }
.mini-table td { padding: .55rem .5rem; border-top: 1px solid var(--ops-line); color: #c5cee1; font-variant-numeric: tabular-nums; }
.mini-table tbody tr { cursor: pointer; }
.mini-table tbody tr:hover td { background: rgba(86,215,237,.05); }
.mini-table td strong { display: block; color: var(--ops-text); }
.sub-link { color: var(--ops-muted); font-size: .7rem; text-decoration: none; }
.sub-link:hover { color: var(--ops-cyan); }

.rarity-list { display: grid; gap: .85rem; }
.rarity-row { display: grid; gap: .3rem; color: inherit; text-decoration: none; }
.rarity-meta { display: flex; justify-content: space-between; gap: .5rem; font-size: .78rem; }
.rarity-meta strong { color: var(--ops-text); }
.rarity-meta span, .rarity-row small { color: var(--ops-muted); font-size: .68rem; }
.rarity-row:hover strong { color: var(--ops-cyan); }
.h-track i.fill-common { background: #72a02a; }
.h-track i.fill-rare { background: #2a9ec0; }
.h-track i.fill-epic { background: #8f7af0; }

.character-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: .6rem; }
.character-card { display: grid; grid-template-columns: 60px minmax(0, 1fr); gap: .7rem; align-items: center; padding: .6rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #10182b; color: inherit; text-decoration: none; }
.character-card:hover { border-color: rgba(86,215,237,.45); }
.character-card img, .character-fallback { width: 60px; height: 60px; border-radius: 9px; object-fit: cover; background: #0d1527; }
.character-fallback { display: grid; place-items: center; color: var(--ops-violet); font-weight: 900; }
.character-body { display: grid; gap: .1rem; min-width: 0; }
.character-body strong { overflow: hidden; color: var(--ops-text); font-size: .82rem; text-overflow: ellipsis; white-space: nowrap; }
.character-body small { color: var(--ops-muted); font-size: .68rem; }
.character-meta { display: flex; align-items: center; gap: .45rem; margin-top: .25rem; color: var(--ops-muted); font-size: .68rem; }

.feed { display: grid; margin: 0; padding: 0; list-style: none; }
.feed li + li { border-top: 1px solid var(--ops-line); }
.feed-row { display: grid; grid-template-columns: 32px minmax(0, 1fr) auto; align-items: center; gap: .65rem; padding: .6rem .2rem; color: inherit; text-decoration: none; border-radius: 6px; }
.feed-row:hover { background: rgba(86,215,237,.05); }
.feed-row img, .feed-icon { width: 32px; height: 32px; border-radius: 8px; object-fit: cover; }
.feed-icon { display: grid; place-items: center; background: rgba(86,215,237,.1); color: var(--ops-cyan); font-size: .8rem; }
.feed-icon.kind-report { background: rgba(255,124,120,.14); color: var(--ops-coral); }
.feed-icon.kind-prize { background: rgba(255,196,87,.14); color: #ffc457; }
.feed-icon.kind-account { background: rgba(184,232,92,.12); color: var(--ops-lime); }
.feed-text { display: grid; min-width: 0; }
.feed-text strong { overflow: hidden; color: var(--ops-text); font-size: .8rem; text-overflow: ellipsis; white-space: nowrap; }
.feed-text small { overflow: hidden; color: var(--ops-muted); font-size: .68rem; text-overflow: ellipsis; white-space: nowrap; }
.feed time { color: var(--ops-muted); font-size: .66rem; white-space: nowrap; }

.system-grid { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: .6rem; }
.system-card { display: grid; gap: .2rem; padding: .8rem .9rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); color: inherit; text-decoration: none; }
.system-card:hover { border-color: rgba(86,215,237,.45); }
.system-card span, .system-card small { color: var(--ops-muted); font-size: .68rem; }
.system-card strong { color: var(--ops-text); font-size: 1.15rem; font-variant-numeric: tabular-nums; }

@media (max-width: 1250px) {
  .kpi-grid, .system-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
@media (max-width: 1000px) {
  .row-2, .row-2.wide-left { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
  .topbar { flex-direction: column; align-items: flex-start; }
  .kpi-grid, .system-grid, .character-grid { grid-template-columns: 1fr 1fr; }
  .mini-table th:nth-child(3), .mini-table td:nth-child(3), .mini-table th:nth-child(6), .mini-table td:nth-child(6) { display: none; }
  .ops-panel-head { flex-direction: column; align-items: flex-start; }
}
</style>
