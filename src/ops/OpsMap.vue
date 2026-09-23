<template>
  <section class="map-panel">
    <header class="map-head">
      <div>
        <span class="panel-index">Mapa</span>
        <h3>Personajes en campo</h3>
      </div>
      <span>{{ characters.length }} ubicaciones</span>
    </header>
    <div class="map-layout">
      <div ref="mapEl" class="map-canvas" role="application" aria-label="Mapa de personajes de TerraLiam" />
      <aside v-if="selected" class="map-detail">
        <img v-if="selected.image" :src="selected.image" :alt="selected.name" />
        <div v-else class="detail-fallback">{{ initials(selected.name) }}</div>
        <strong>{{ selected.name }}</strong>
        <p>{{ selected.world }}</p>
        <dl>
          <div><dt>Agregado por</dt><dd>{{ selected.creator }}</dd></div>
          <div><dt>Rareza</dt><dd>{{ labelRarity(selected.rarity) }}</dd></div>
          <div><dt>Capturas</dt><dd>{{ formatNumber(selected.captures) }}</dd></div>
          <div>
            <dt>Quiénes capturaron</dt>
            <dd>{{ capturers }}</dd>
          </div>
        </dl>
        <a class="maps-link" :href="googleMapsUrl" target="_blank" rel="noreferrer">Abrir en Google Maps ↗</a>
      </aside>
      <p v-else class="map-empty">Selecciona un personaje en el mapa para ver mundo, creador y capturas.</p>
    </div>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { formatNumber, initials, labelRarity } from '@/ops/opsUi'

const props = defineProps({
  characters: { type: Array, default: () => [] },
})

const mapEl = ref(null)
const selected = ref(null)
let map
let layer

const capturers = computed(() => {
  const names = selected.value?.captured_by || []
  return names.length ? names.join(', ') : 'Nadie aún'
})
const googleMapsUrl = computed(() => {
  const item = selected.value
  if (!item) return '#'
  return `https://www.google.com/maps/search/?api=1&query=${item.lat},${item.lng}`
})

onMounted(() => {
  if (!mapEl.value) return
  map = L.map(mapEl.value, { scrollWheelZoom: false, zoomControl: true })
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap &copy; CARTO',
    maxZoom: 19,
  }).addTo(map)
  renderMarkers()
})

onBeforeUnmount(() => {
  map?.remove()
})

watch(() => props.characters, () => renderMarkers(), { deep: true })

function renderMarkers() {
  if (!map) return
  layer?.remove()
  layer = L.layerGroup().addTo(map)
  const points = props.characters.filter((item) => Number.isFinite(Number(item.lat)) && Number.isFinite(Number(item.lng)))
  const bounds = []
  for (const item of points) {
    const latlng = [Number(item.lat), Number(item.lng)]
    bounds.push(latlng)
    const marker = L.marker(latlng, {
      icon: L.divIcon({
        className: 'ops-pin',
        html: item.image
          ? `<img src="${item.image}" alt="">`
          : `<span>${initials(item.name)}</span>`,
        iconSize: [36, 36],
        iconAnchor: [18, 18],
      }),
      title: item.name,
    })
    marker.on('click', () => { selected.value = item })
    marker.addTo(layer)
  }
  if (bounds.length) map.fitBounds(bounds, { padding: [28, 28], maxZoom: 15 })
  else map.setView([10.18, -66.9], 12)
  if (!selected.value && points[0]) selected.value = points[0]
}
</script>

<style scoped>
.map-panel { min-width: 0; margin-bottom: 1.25rem; padding: 1.2rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
.map-head, .map-head > div { display: flex; align-items: center; justify-content: space-between; gap: .75rem; }
.map-head { margin-bottom: 1rem; }
.map-head h3 { margin: 0; font-size: .98rem; }
.map-head span:last-child { color: var(--ops-muted); font-size: .68rem; }
.panel-index { color: var(--ops-cyan); font-size: .64rem; font-weight: 900; letter-spacing: .13em; }
.map-layout { display: grid; grid-template-columns: minmax(0, 1.6fr) minmax(240px, .7fr); gap: .85rem; }
.map-canvas { min-height: 360px; height: min(58vh, 480px); overflow: hidden; border: 1px solid var(--ops-line); border-radius: 10px; background: #0d1527; }
.map-detail { display: grid; align-content: start; gap: .45rem; padding: 1rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #10182b; }
.map-detail img, .detail-fallback { width: 88px; height: 88px; border-radius: 10px; object-fit: cover; background: #0d1527; }
.detail-fallback { display: grid; place-items: center; color: var(--ops-cyan); font-weight: 900; }
.map-detail strong { font-size: .95rem; }
.map-detail p, .map-empty, dt { color: var(--ops-muted); font-size: .74rem; }
dl { display: grid; gap: .55rem; margin: .55rem 0 0; }
dl div { display: grid; gap: .15rem; }
dd { margin: 0; font-size: .82rem; }
.maps-link { margin-top: .4rem; color: var(--ops-cyan); font-size: .75rem; text-decoration: none; }
.map-empty { display: grid; place-items: center; min-height: 160px; padding: 1rem; border: 1px dashed var(--ops-line); border-radius: 10px; text-align: center; }
@media (max-width: 900px) {
  .map-layout { grid-template-columns: 1fr; }
  .map-canvas { min-height: 280px; height: 58vw; }
}
</style>

<style>
.ops-pin { display: grid; place-items: center; }
.ops-pin img, .ops-pin span {
  width: 36px;
  height: 36px;
  border: 2px solid #56d7ed;
  border-radius: 50%;
  object-fit: cover;
  background: #121a2d;
  box-shadow: 0 0 0 3px rgba(86,215,237,.18);
}
.ops-pin span { display: grid; place-items: center; color: #56d7ed; font-size: 10px; font-weight: 800; }
.leaflet-container { background: #0d1527; font-family: inherit; }
</style>
