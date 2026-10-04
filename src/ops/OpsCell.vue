<template>
  <div v-if="column.type === 'title'" class="cell-title">
    <img v-if="column.image && row[column.image]" :src="row[column.image]" alt="" loading="lazy" />
    <span v-else-if="column.image" class="cell-fallback">{{ initials(value) }}</span>
    <span class="cell-title-text">
      <router-link v-if="linkTo" :to="linkTo" class="cell-link" @click.stop>{{ display }}</router-link>
      <strong v-else>{{ display }}</strong>
      <small v-if="column.sub && row[column.sub]">{{ row[column.sub] }}</small>
    </span>
  </div>
  <span v-else-if="column.type === 'badge'" class="ops-badge" :class="`tone-${badge(value).tone}`">{{ badge(value).label }}</span>
  <span v-else-if="column.type === 'bool'" class="cell-bool" :class="value ? 'is-on' : 'is-off'">{{ value ? 'Sí' : 'No' }}</span>
  <span v-else-if="column.type === 'number'" class="cell-num">{{ formatNumber(value) }}</span>
  <span v-else-if="column.type === 'money'" class="cell-num">{{ value == null ? '—' : formatCurrency(value) }}</span>
  <span v-else-if="column.type === 'bytes'" class="cell-num">{{ formatBytes(value) }}</span>
  <time v-else-if="column.type === 'date'" :datetime="value" :title="formatDateTime(value)">{{ formatDate(value) }}</time>
  <time v-else-if="column.type === 'relative'" :datetime="value" :title="formatDateTime(value)">{{ formatRelative(value) }}</time>
  <video v-else-if="column.type === 'video' && value" class="cell-video" :src="value" :poster="row[column.poster] || undefined" controls playsinline preload="none" @click.stop />
  <a v-else-if="column.type === 'file' && value" class="cell-link" :href="storagePublicUrl(value)" target="_blank" rel="noreferrer" @click.stop>{{ value }}</a>
  <span v-else-if="column.type === 'json'" class="cell-json" :title="jsonText">{{ jsonText || '—' }}</span>
  <span v-else-if="column.type === 'clip'" class="cell-clip" :title="value || ''">{{ value || '—' }}</span>
  <router-link v-else-if="column.type === 'resource'" :to="`/ops/${value}`" class="cell-link" @click.stop>{{ resourceLabel(value) }}</router-link>
  <router-link v-else-if="linkTo" :to="linkTo" class="cell-link" @click.stop>{{ display }}</router-link>
  <span v-else>{{ display }}</span>
</template>

<script setup>
import { computed } from 'vue'
import { storagePublicUrl } from '@/ops/opsApi'
import {
  badge, findResource, formatBytes, formatCurrency, formatDate, formatDateTime, formatNumber,
  formatRelative, initials, resourceLabel,
} from '@/ops/opsUi'

const props = defineProps({
  column: { type: Object, required: true },
  row: { type: Object, required: true },
})

const value = computed(() => props.row[props.column.key])
const display = computed(() => (value.value === null || value.value === undefined || value.value === '' ? '—' : String(value.value)))
const linkTo = computed(() => {
  const link = props.column.link
  const id = link && props.row[link.id]
  if (!id || !findResource(link.resource)?.detail) return null
  return `/ops/${link.resource}/${id}`
})
const jsonText = computed(() => {
  const data = value.value
  if (!data || typeof data !== 'object' || !Object.keys(data).length) return ''
  return Object.entries(data).map(([key, item]) => `${key}: ${typeof item === 'object' ? JSON.stringify(item) : item}`).join(' · ')
})
</script>

<style scoped>
.cell-title { display: flex; align-items: center; gap: .65rem; min-width: 0; }
.cell-title img, .cell-fallback { flex: none; width: 36px; height: 36px; border-radius: 9px; object-fit: cover; background: #0d1527; }
.cell-fallback { display: grid; place-items: center; color: var(--ops-cyan); font-size: .66rem; font-weight: 900; background: rgba(86,215,237,.1); }
.cell-title-text { display: grid; min-width: 0; }
.cell-title-text strong, .cell-title-text .cell-link { overflow: hidden; color: var(--ops-text); font-weight: 700; text-overflow: ellipsis; white-space: nowrap; }
.cell-title-text small { overflow: hidden; color: var(--ops-muted); font-size: .7rem; text-overflow: ellipsis; white-space: nowrap; }
.cell-link { color: var(--ops-cyan); text-decoration: none; }
.cell-link:hover { text-decoration: underline; }
.cell-title-text .cell-link:hover { color: var(--ops-cyan); }
.cell-num { font-variant-numeric: tabular-nums; }
.cell-bool { font-size: .74rem; font-weight: 700; }
.cell-bool.is-on { color: var(--ops-lime); }
.cell-bool.is-off { color: var(--ops-muted); }
.cell-video { width: 120px; aspect-ratio: 1; border-radius: 8px; background: #0d1527; object-fit: cover; }
.cell-json, .cell-clip { display: block; max-width: 260px; overflow: hidden; color: var(--ops-muted); font-size: .72rem; text-overflow: ellipsis; white-space: nowrap; }
</style>
