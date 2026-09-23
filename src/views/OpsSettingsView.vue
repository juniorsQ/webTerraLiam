<template>
  <OpsShell>
    <header class="resource-head">
      <div>
        <p class="crumb">TerraLiam <span>/</span> Ajustes</p>
        <h1>Política de plataforma</h1>
      </div>
      <span class="live-state"><i /> {{ saved || 'Listo para guardar' }}</span>
    </header>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <p v-else-if="!ready" class="loading-state">Cargando ajustes...</p>
    <form v-else class="settings-grid" @submit.prevent="save">
      <article class="panel">
        <header class="panel-head">
          <div><span class="panel-index">01</span><h3>Fal.ai · video</h3></div>
          <span class="panel-status">video_policy</span>
        </header>
        <label>
          Costo por video (USD)
          <input v-model.number="video.unit_cost_usd" type="number" min="0.01" step="0.01" required />
        </label>
        <label>
          Videos máximos por mundo / mes
          <input v-model.number="video.max_videos_per_world_per_month" type="number" min="1" step="1" required />
        </label>
        <label>
          Tope mensual (USD)
          <input v-model.number="video.monthly_budget_usd" type="number" min="0.01" step="0.01" required />
        </label>
      </article>
      <article class="panel">
        <header class="panel-head">
          <div><span class="panel-index">02</span><h3>Recraft · imágenes</h3></div>
          <span class="panel-status">recraft_policy</span>
        </header>
        <label>
          Créditos por recorte
          <input v-model.number="recraft.cutout_cost_credits" type="number" min="0.1" step="0.1" required />
        </label>
        <label>
          Créditos por estilizado
          <input v-model.number="recraft.stylized_cost_credits" type="number" min="0.1" step="0.1" required />
        </label>
        <label>
          Alerta de umbral
          <input v-model.number="recraft.alert_threshold" type="number" min="1" step="1" required />
        </label>
      </article>
      <div class="form-actions">
        <router-link to="/ops" class="back-link">← Overview</router-link>
        <button class="save-button" type="submit" :disabled="saving">
          {{ saving ? 'Guardando...' : 'Guardar políticas' }}
        </button>
      </div>
    </form>
  </OpsShell>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadOpsDashboard, saveOpsSettings } from '@/ops/opsApi'
import OpsShell from '@/ops/OpsShell.vue'
import { useOpsSession } from '@/ops/useOpsSession'

const router = useRouter()
const { refresh, session, hasSupabase, isPlatformAdmin } = useOpsSession()
const ready = ref(false)
const saving = ref(false)
const error = ref('')
const saved = ref('')
const video = reactive({
  unit_cost_usd: 0.28,
  max_videos_per_world_per_month: 4,
  monthly_budget_usd: 1.12,
})
const recraft = reactive({
  cutout_cost_credits: 1,
  stylized_cost_credits: 2,
  alert_threshold: 200,
})

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value || !isPlatformAdmin()) {
    router.replace('/ops/login')
    return
  }
  try {
    const data = await loadOpsDashboard()
    Object.assign(video, {
      unit_cost_usd: Number(data.video_policy?.unit_cost_usd || data.providers?.fal?.unit_cost_usd || 0.28),
      max_videos_per_world_per_month: Number(data.video_policy?.max_videos_per_world_per_month || 4),
      monthly_budget_usd: Number(data.video_policy?.monthly_budget_usd || data.providers?.fal?.monthly_budget_usd || 1.12),
    })
    Object.assign(recraft, {
      cutout_cost_credits: Number(data.recraft_policy?.cutout_cost_credits || 1),
      stylized_cost_credits: Number(data.recraft_policy?.stylized_cost_credits || 2),
      alert_threshold: Number(data.recraft_policy?.alert_threshold || 200),
    })
  } catch (err) {
    error.value = err.message ?? 'No se pudieron cargar los ajustes.'
  } finally {
    ready.value = true
  }
})

async function save() {
  saving.value = true
  error.value = ''
  saved.value = ''
  try {
    await saveOpsSettings('video_policy', { ...video })
    await saveOpsSettings('recraft_policy', { ...recraft })
    saved.value = 'Políticas actualizadas'
  } catch (err) {
    error.value = err.message ?? 'No se pudieron guardar los ajustes.'
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.resource-head { display: flex; align-items: center; justify-content: space-between; gap: 1rem; margin-bottom: 1.5rem; }
.crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }
.crumb span { color: var(--ops-cyan); padding: 0 .35rem; }
h1, h3 { margin: 0; color: var(--ops-text); }
h1 { font-family: var(--font-display); font-size: clamp(1.8rem, 4vw, 3.2rem); }
.live-state { display: inline-flex; align-items: center; gap: .5rem; padding: .55rem .75rem; border: 1px solid var(--ops-line); border-radius: 7px; color: var(--ops-muted); background: var(--ops-panel); font-size: .68rem; }
.live-state i { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); }
.settings-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .85rem; }
.panel { padding: 1.1rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
.panel-head { display: flex; align-items: center; justify-content: space-between; gap: .7rem; margin-bottom: 1rem; }
.panel-head > div { display: flex; align-items: center; gap: .65rem; }
.panel-index, .panel-status { color: var(--ops-cyan); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }
.panel-status { color: var(--ops-muted); }
label { display: grid; gap: .4rem; margin-bottom: .85rem; color: var(--ops-muted); font-size: .74rem; }
input { min-height: 44px; padding: 0 .8rem; border: 1px solid var(--ops-line); border-radius: 8px; background: #0d1527; color: var(--ops-text); font: inherit; }
.form-actions { grid-column: 1 / -1; display: flex; justify-content: space-between; align-items: center; gap: 1rem; }
.back-link { color: var(--ops-cyan); text-decoration: none; font-size: .78rem; }
.save-button { min-height: 44px; padding: 0 1.1rem; border: 0; border-radius: 8px; background: var(--ops-cyan); color: #081018; font: inherit; font-weight: 800; cursor: pointer; }
.error-banner { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }
.loading-state { color: var(--ops-muted); }
@media (max-width: 800px) {
  .resource-head, .form-actions { flex-direction: column; align-items: flex-start; }
  .settings-grid { grid-template-columns: 1fr; }
}
</style>
