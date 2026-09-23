<template>
  <section class="map-panel">
    <header class="map-head">
      <div>
        <span class="panel-index">Mapa</span>
        <h3>Personajes en campo</h3>
      </div>
      <span>{{ characters.length }} ubicaciones</span>
    </header>
    <p v-if="mapError" class="map-error">{{ mapError }}</p>
    <div class="map-layout">
      <div ref="mapEl" class="map-canvas" role="application" aria-label="Mapa de Google de personajes de TerraLiam" />
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
import { formatNumber, initials, labelRarity } from '@/ops/opsUi'

const props = defineProps({
  characters: { type: Array, default: () => [] },
})

const mapsKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY
const mapEl = ref(null)
const selected = ref(null)
const mapError = ref('')
let map
const markers = []

const capturers = computed(() => {
  const names = selected.value?.captured_by || []
  return names.length ? names.join(', ') : 'Nadie aún'
})
const googleMapsUrl = computed(() => {
  const item = selected.value
  if (!item) return '#'
  return `https://www.google.com/maps/search/?api=1&query=${item.lat},${item.lng}`
})
const points = computed(() => props.characters.filter((item) => Number.isFinite(Number(item.lat)) && Number.isFinite(Number(item.lng))))

onMounted(async () => {
  if (!mapsKey) {
    mapError.value = 'Falta VITE_GOOGLE_MAPS_API_KEY en .env.local. Activa Maps JavaScript API en Google Cloud.'
    return
  }
  try {
    await loadGoogleMaps(mapsKey)
    if (!mapEl.value || !window.google?.maps) return
    map = new window.google.maps.Map(mapEl.value, {
      center: { lat: 10.18, lng: -66.9 },
      zoom: 12,
      mapTypeControl: true,
      streetViewControl: false,
      fullscreenControl: true,
      gestureHandling: 'cooperative',
      styles: mapStyles,
    })
    renderMarkers()
  } catch (err) {
    mapError.value = err.message ?? 'No se pudo cargar Google Maps. Activa Maps JavaScript API y restringe la clave por HTTP referrer.'
  }
})

onBeforeUnmount(() => {
  clearMarkers()
  map = null
})

watch(points, () => renderMarkers(), { deep: true })

function renderMarkers() {
  if (!map || !window.google?.maps) return
  clearMarkers()
  const bounds = new window.google.maps.LatLngBounds()
  for (const item of points.value) {
    const position = { lat: Number(item.lat), lng: Number(item.lng) }
    const marker = new window.google.maps.Marker({
      map,
      position,
      title: item.name,
      icon: item.image
        ? { url: item.image, scaledSize: new window.google.maps.Size(36, 36), anchor: new window.google.maps.Point(18, 18) }
        : undefined,
    })
    marker.addListener('click', () => { selected.value = item })
    markers.push(marker)
    bounds.extend(position)
  }
  if (points.value.length) map.fitBounds(bounds, 36)
  if (!selected.value && points.value[0]) selected.value = points.value[0]
}

function clearMarkers() {
  for (const marker of markers) marker.setMap(null)
  markers.length = 0
}

function loadGoogleMaps(key) {
  if (window.google?.maps) return Promise.resolve()
  if (window.__opsGoogleMaps) return window.__opsGoogleMaps
  window.__opsGoogleMaps = new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}`
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Google Maps no cargó. Revisa la clave y Maps JavaScript API.'))
    document.head.appendChild(script)
  })
  return window.__opsGoogleMaps
}

const mapStyles = [
  { elementType: 'geometry', stylers: [{ color: '#10182b' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#10182b' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#8e9bb7' }] },
  { featureType: 'administrative', elementType: 'geometry', stylers: [{ color: '#2b364f' }] },
  { featureType: 'poi', elementType: 'labels.text.fill', stylers: [{ color: '#8e9bb7' }] },
  { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#152235' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#1c2740' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#0b1020' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#243352' }] },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#0b1020' }] },
]
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
.map-error { margin: 0 0 .85rem; padding: .7rem .85rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); font-size: .78rem; }
@media (max-width: 900px) {
  .map-layout { grid-template-columns: 1fr; }
  .map-canvas { min-height: 280px; height: 58vw; }
}
</style>
