<template>
  <OpsShell>
    <p class="crumb">
      <router-link to="/ops">Centro de control</router-link><span>/</span>
      <router-link :to="`/ops/${resource}`">{{ config?.label ?? resource }}</router-link><span>/</span>{{ view?.title ?? '…' }}
    </p>

    <p v-if="error" class="ops-error">{{ error }}</p>
    <p v-else-if="!data" class="ops-muted">Cargando…</p>

    <template v-else-if="view">
      <section class="hero ops-panel">
        <div class="hero-media">
          <img v-if="view.image" :src="view.image" :alt="view.title" />
          <span v-else class="hero-fallback">{{ initials(view.title) }}</span>
        </div>
        <div class="hero-body">
          <div class="hero-badges">
            <span v-for="item in view.badges" :key="item" class="ops-badge" :class="`tone-${badge(item).tone}`">{{ badge(item).label }}</span>
            <span v-for="item in view.flags || []" :key="item.label" class="ops-badge" :class="`tone-${item.tone}`">{{ item.label }}</span>
          </div>
          <h1>{{ view.title }}</h1>
          <p v-if="view.subtitle" class="hero-sub">{{ view.subtitle }}</p>
          <dl class="hero-meta">
            <div v-for="item in view.meta" :key="item.label">
              <dt>{{ item.label }}</dt>
              <dd>
                <router-link v-if="item.to" :to="item.to">{{ item.value }}</router-link>
                <a v-else-if="item.href" :href="item.href" target="_blank" rel="noreferrer">{{ item.value }} ↗</a>
                <span v-else>{{ item.value }}</span>
              </dd>
            </div>
          </dl>
        </div>
        <div class="hero-actions">
          <button v-if="editSchemas[resource]" class="ops-btn primary" type="button" :disabled="busy" @click="edit">Editar</button>
          <button v-for="action in view.extraActions || []" :key="action.key" class="ops-btn" :class="action.tone" type="button" :disabled="busy" @click="runExtra(action)">
            {{ action.label }}
          </button>
          <button v-if="view.deletable" class="ops-btn danger" type="button" :disabled="busy" @click="remove">Eliminar</button>
        </div>
      </section>

      <section v-if="view.stats?.length" class="stat-strip">
        <component
          :is="stat.to ? 'router-link' : 'div'"
          v-for="stat in view.stats"
          :key="stat.label"
          :to="stat.to"
          class="stat"
          :class="{ alert: stat.alert }"
        >
          <strong>{{ stat.value }}</strong>
          <span>{{ stat.label }}</span>
        </component>
      </section>

      <section v-if="view.media?.length" class="ops-panel media-panel">
        <header class="ops-panel-head"><h3>Recursos del personaje</h3><p>Original → recorte → estilizado → video</p></header>
        <div class="media-grid">
          <figure v-for="item in view.media" :key="item.label">
            <video v-if="item.video" :src="item.url" controls playsinline preload="metadata" />
            <a v-else :href="item.url" target="_blank" rel="noreferrer"><img :src="item.url" :alt="item.label" loading="lazy" /></a>
            <figcaption>{{ item.label }}</figcaption>
          </figure>
        </div>
      </section>

      <section v-if="view.config?.length" class="ops-panel">
        <header class="ops-panel-head"><h3>Reglas de puntos del mundo</h3><p>world_points_config · editable desde la app</p></header>
        <dl class="config-grid">
          <div v-for="item in view.config" :key="item.label"><dt>{{ item.label }}</dt><dd>{{ item.value }}</dd></div>
        </dl>
      </section>

      <div class="sections">
        <section v-for="section in view.sections" :key="section.title" class="ops-panel related">
          <header class="ops-panel-head">
            <div>
              <h3>{{ section.title }} <small>{{ section.rows.length }}</small></h3>
              <p v-if="section.hint">{{ section.hint }}</p>
            </div>
            <router-link v-if="section.more" :to="section.more" class="ops-panel-link">Ver en lista →</router-link>
          </header>
          <p v-if="!section.rows.length" class="ops-muted empty">{{ section.empty ?? 'Sin registros.' }}</p>
          <div v-else class="related-list">
            <div
              v-for="row in section.rows.slice(0, section.limit ?? 12)"
              :key="row.id"
              class="related-row"
              :class="{ clickable: section.resource && findResource(section.resource)?.detail }"
              @click="openRelated(section, row)"
            >
              <div class="related-cells">
                <div v-for="column in section.columns" :key="column.key" class="related-cell" :class="{ wide: column.type === 'title' }">
                  <small v-if="column.type !== 'title'">{{ column.label }}</small>
                  <OpsCell :column="column" :row="row" />
                </div>
              </div>
              <div v-if="sectionActions(section, row).length" class="related-actions" @click.stop>
                <button
                  v-for="action in sectionActions(section, row)"
                  :key="action.key"
                  type="button"
                  class="ops-btn"
                  :class="action.tone"
                  :disabled="busy"
                  @click="runRowAction(section.actionResource, action, row)"
                >{{ action.label }}</button>
              </div>
            </div>
            <p v-if="section.rows.length > (section.limit ?? 12)" class="ops-muted more-note">
              +{{ section.rows.length - (section.limit ?? 12) }} más
            </p>
          </div>
        </section>
      </div>
    </template>
  </OpsShell>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import OpsCell from '@/ops/OpsCell.vue'
import OpsShell from '@/ops/OpsShell.vue'
import { loadDetail, mutate } from '@/ops/opsApi'
import { confirmAction, editForm, toast } from '@/ops/opsFeedback'
import { useOpsSession } from '@/ops/useOpsSession'
import {
  badge, editSchemas, findResource, formatCurrency, formatDate, formatDateTime, formatNumber,
  formatRelative, initials,
} from '@/ops/opsUi'

const props = defineProps({
  resource: { type: String, required: true },
  id: { type: String, required: true },
})
const router = useRouter()
const { session } = useOpsSession()
const config = computed(() => findResource(props.resource))
const data = ref(null)
const error = ref('')
const busy = ref(false)

watch(() => [props.resource, props.id], load, { immediate: true })

async function load() {
  error.value = ''
  data.value = null
  try {
    data.value = await loadDetail(props.resource, props.id)
  } catch (err) {
    error.value = err.message ?? 'No se pudo cargar el detalle.'
  }
}

async function refresh() {
  try {
    data.value = await loadDetail(props.resource, props.id)
  } catch (err) {
    error.value = err.message ?? 'No se pudo cargar el detalle.'
  }
}

// Column presets reused by related sections.
const col = {
  world: { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
  player: { key: 'jugador', label: 'Jugador', link: { resource: 'users', id: 'user_id' } },
  character: { key: 'personaje', label: 'Personaje', link: { resource: 'pois', id: 'poi_id' } },
  when: (key, label = 'Fecha') => ({ key, label, type: 'relative' }),
  num: (key, label) => ({ key, label, type: 'number' }),
}

const prizeRows = (list, extra = {}) => (list || []).map((g) => ({
  id: g.id, jugador: g.player ?? extra.player, user_id: g.user_id ?? extra.user_id, mundo: g.world ?? extra.world,
  world_id: g.world_id ?? extra.world_id, nivel: g.level, puntos: g.points, estado: g.status, used_at: g.used_at, created_at: g.created_at,
}))
const progressRows = (list, extra = {}) => (list || []).map((p) => ({
  id: p.id, jugador: p.name ?? extra.player, user_id: p.user_id ?? extra.user_id, mundo: p.world ?? extra.world,
  world_id: p.world_id ?? extra.world_id, nivel: p.level, puntos: p.points, capturas: p.captures, creditos_premio: p.prize_credits, updated_at: p.updated_at,
}))
const reportRows = (list, extra = {}) => (list || []).map((r) => ({
  id: r.id, motivo: r.reason, estado: r.status, poi_id: r.poi_id ?? extra.poi_id, personaje: r.character ?? extra.character ?? '—',
  world_id: extra.world_id, mundo: extra.world, created_at: r.created_at,
}))

const view = computed(() => {
  const d = data.value
  if (!d) return null
  const builder = builders[props.resource]
  return builder ? builder(d) : null
})

const builders = {
  users(d) {
    const r = d.record
    const s = d.stats
    const name = r.display_name || (r.email ? r.email.split('@')[0] : 'Sin nombre')
    const ctx = { player: name, user_id: r.id }
    return {
      title: name,
      subtitle: r.kind === 'kid' ? 'Cuenta de niño (asiento sintético creado por el adulto)' : r.email,
      image: r.avatar_url,
      badges: [r.kind],
      flags: r.has_profile ? [] : [{ label: 'Sin perfil', tone: 'warn' }],
      meta: [
        { label: 'Último acceso', value: r.last_sign_in_at ? `${formatRelative(r.last_sign_in_at)} · ${formatDateTime(r.last_sign_in_at)}` : 'Nunca' },
        { label: 'Alta', value: formatDateTime(r.created_at) },
        { label: 'Proveedor', value: r.provider || 'email' },
        { label: 'Correo confirmado', value: r.email_confirmed_at ? formatDate(r.email_confirmed_at) : 'No' },
        { label: 'ID', value: r.id },
      ],
      stats: [
        { label: 'Mundos creados', value: formatNumber(s.worlds_owned) },
        { label: 'Niños en sus mundos', value: formatNumber(s.kids_in_owned_worlds) },
        { label: 'Membresías', value: formatNumber(s.memberships) },
        { label: 'Personajes agregados', value: formatNumber(s.characters_added) },
        { label: 'Capturas', value: formatNumber(s.captures) },
        { label: 'Puntos totales', value: formatNumber(s.points) },
      ],
      deletable: r.kind !== 'admin' && r.id !== session.value?.user?.id,
      deleteMessage: `Se borra la cuenta de acceso de forma permanente${s.worlds_owned ? ` junto con ${s.worlds_owned} mundo(s), sus personajes, niños y capturas` : ''}. Úsalo para solicitudes de "Eliminar cuenta" (Google Play).`,
      typed: 'ELIMINAR',
      sections: [
        {
          title: 'Mundos creados', resource: 'worlds', empty: 'No ha creado mundos.',
          rows: d.worlds_owned.map((w) => ({ id: w.id, mundo: w.name, visibilidad: w.visibility, ninos: w.kids, personajes: w.characters, capturas: w.captures, created_at: w.created_at })),
          columns: [{ key: 'mundo', label: 'Mundo', type: 'title' }, { key: 'visibilidad', label: 'Visibilidad', type: 'badge' }, col.num('ninos', 'Niños'), col.num('personajes', 'Personajes'), col.num('capturas', 'Capturas')],
        },
        {
          title: 'Participa en', resource: 'worlds', empty: 'Sin membresías.',
          rows: d.memberships.map((m) => ({ id: m.world_id, mundo: m.name, rol: m.role, apodo: m.nickname, joined_at: m.joined_at })),
          columns: [{ key: 'mundo', label: 'Mundo', type: 'title' }, { key: 'rol', label: 'Rol', type: 'badge' }, { key: 'apodo', label: 'Apodo' }, col.when('joined_at', 'Se unió')],
        },
        {
          title: 'Progreso por mundo', actionResource: 'progress', empty: 'Sin progreso registrado.',
          rows: progressRows(d.progress, ctx),
          columns: [{ ...col.world, type: 'title' }, col.num('nivel', 'Nivel'), col.num('puntos', 'Puntos'), col.num('creditos_premio', 'Créditos premio')],
        },
        {
          title: 'Capturas', resource: 'captures', actionResource: 'captures', empty: 'Aún no captura personajes.',
          rows: d.captures.map((c) => ({ id: c.id, personaje: c.character ?? 'Personaje eliminado', poi_id: c.poi_id, mundo: c.world, world_id: c.world_id, imagen: c.image, captured_at: c.captured_at, jugador: name })),
          columns: [{ ...col.character, type: 'title', image: 'imagen' }, col.world, col.when('captured_at', 'Capturado')],
        },
        {
          title: 'Solicitudes de premio', actionResource: 'prize-grants', empty: 'Sin solicitudes.',
          rows: prizeRows(d.prizes, ctx),
          columns: [{ ...col.world, type: 'title' }, col.num('nivel', 'Nivel'), { key: 'estado', label: 'Estado', type: 'badge' }, col.when('created_at', 'Pedido')],
        },
      ],
    }
  },

  worlds(d) {
    const r = d.record
    const s = d.stats
    const ctx = { world: r.name, world_id: r.id }
    const cfg = d.points_config
    return {
      title: r.name,
      subtitle: `Mundo de ${d.owner.name}`,
      badges: [r.visibility],
      flags: [r.video_rewards_enabled ? { label: 'Video IA activo', tone: 'info' } : { label: 'Video IA apagado', tone: 'neutral' }],
      meta: [
        { label: 'Adulto creador', value: d.owner.name, to: `/ops/users/${d.owner.id}` },
        { label: 'Correo', value: d.owner.email || '—' },
        { label: 'Código de invitación', value: r.invite_code },
        { label: 'Creado', value: formatDateTime(r.created_at) },
        { label: 'Última captura', value: formatRelative(s.last_capture_at) },
      ],
      stats: [
        { label: 'Niños', value: formatNumber(s.kids) },
        { label: 'Miembros', value: formatNumber(s.members) },
        { label: s.characters_inactive ? `Personajes (+${s.characters_inactive} ocultos)` : 'Personajes', value: formatNumber(s.characters) },
        { label: 'Capturas', value: formatNumber(s.captures) },
        { label: 'Capturas 7 días', value: formatNumber(s.captures_7d) },
        { label: 'Videos este mes', value: `${formatNumber(s.videos_month)} / ${formatNumber(s.video_limit)}`, alert: s.videos_month >= s.video_limit },
        { label: 'Premios pendientes', value: formatNumber(s.pending_prizes), alert: s.pending_prizes > 0 },
        { label: 'Reportes abiertos', value: formatNumber(s.open_reports), alert: s.open_reports > 0 },
      ],
      config: cfg ? [
        { label: 'Capturas por nivel', value: cfg.captures_per_level },
        { label: 'Puntos común', value: cfg.points_common },
        { label: 'Puntos raro', value: cfg.points_rare },
        { label: 'Puntos épico', value: cfg.points_epic },
        { label: 'Premio requiere aprobación', value: cfg.prize_requires_admin_approval ? 'Sí' : 'No' },
      ].filter((item) => item.value !== undefined) : [],
      deletable: true,
      deleteMessage: `Se elimina el mundo con sus ${s.characters + s.characters_inactive} personajes, ${s.kids} niños, ${s.captures} capturas, progreso y premios. No se puede deshacer.`,
      typed: r.name,
      sections: [
        {
          title: 'Niños exploradores', resource: 'explorers', actionResource: 'explorers', empty: 'Este mundo aún no tiene niños.',
          rows: d.kids.map((k) => ({ id: k.id, nino: k.nickname, avatar_url: k.avatar_url, emparejado: Boolean(k.user_id), capturas: k.captures, created_at: k.created_at })),
          columns: [{ key: 'nino', label: 'Niño', type: 'title', image: 'avatar_url' }, { key: 'emparejado', label: 'Emparejado', type: 'bool' }, col.num('capturas', 'Capturas'), col.when('created_at', 'Creado')],
        },
        {
          title: 'Personajes', resource: 'pois', actionResource: 'pois', more: `/ops/pois?q=${encodeURIComponent(r.name)}`, empty: 'Sin personajes: la familia no ha escondido nada aún.', limit: 24,
          rows: d.characters.map((c) => ({ id: c.id, personaje: c.title, imagen: c.image, rareza: c.rarity, activo: c.active, capturas: c.captures, tiene_video: c.has_video })),
          columns: [{ key: 'personaje', label: 'Personaje', type: 'title', image: 'imagen' }, { key: 'rareza', label: 'Rareza', type: 'badge' }, { key: 'activo', label: 'Visible', type: 'bool' }, col.num('capturas', 'Capturas'), { key: 'tiene_video', label: 'Video', type: 'bool' }],
        },
        {
          title: 'Ranking de jugadores', actionResource: 'progress', empty: 'Sin progreso registrado.',
          rows: progressRows(d.leaderboard, ctx),
          columns: [{ ...col.player, type: 'title' }, col.num('nivel', 'Nivel'), col.num('puntos', 'Puntos'), col.num('capturas', 'Capturas'), col.num('creditos_premio', 'Créditos')],
        },
        {
          title: 'Capturas recientes', resource: 'captures', actionResource: 'captures', empty: 'Sin capturas.',
          rows: d.recent_captures.map((c) => ({ id: c.id, personaje: c.character ?? 'Personaje eliminado', poi_id: c.poi_id, imagen: c.image, jugador: c.player, user_id: c.user_id, captured_at: c.captured_at })),
          columns: [{ ...col.character, type: 'title', image: 'imagen' }, col.player, col.when('captured_at', 'Capturado')],
        },
        {
          title: 'Solicitudes de premio', actionResource: 'prize-grants', empty: 'Sin solicitudes.',
          rows: prizeRows(d.prizes, ctx),
          columns: [{ ...col.player, type: 'title' }, col.num('nivel', 'Nivel'), { key: 'estado', label: 'Estado', type: 'badge' }, col.when('created_at', 'Pedido')],
        },
        {
          title: 'Miembros (cuentas)', resource: 'users', empty: 'Sin miembros.',
          rows: d.members.map((m) => ({ id: m.user_id, nombre: m.name, rol: m.role, tipo: m.kind, joined_at: m.joined_at })),
          columns: [{ key: 'nombre', label: 'Cuenta', type: 'title' }, { key: 'rol', label: 'Rol', type: 'badge' }, { key: 'tipo', label: 'Tipo', type: 'badge' }, col.when('joined_at', 'Se unió')],
        },
        {
          title: 'Misiones', actionResource: 'missions', empty: 'Sin misiones.',
          rows: d.missions.map((m) => ({ id: m.id, mision: m.title, activa: m.active, pasos: m.steps, completadas: m.completed })),
          columns: [{ key: 'mision', label: 'Misión', type: 'title' }, { key: 'activa', label: 'Activa', type: 'bool' }, col.num('pasos', 'Pasos'), col.num('completadas', 'Completadas')],
        },
        {
          title: 'Reportes', actionResource: 'reports', empty: 'Sin reportes. 👍',
          rows: reportRows(d.reports, ctx),
          columns: [{ key: 'motivo', label: 'Motivo', type: 'title' }, col.character, { key: 'estado', label: 'Estado', type: 'badge' }, col.when('created_at')],
        },
        {
          title: 'Jobs de video IA', actionResource: 'video-jobs', empty: 'Sin videos solicitados.',
          rows: d.video_jobs.map((j) => ({ id: j.id, personaje: j.character ?? '—', poi_id: j.poi_id, estado: j.status, costo_usd: j.cost_usd, error: j.error, created_at: j.created_at })),
          columns: [{ ...col.character, type: 'title' }, { key: 'estado', label: 'Estado', type: 'badge' }, { key: 'costo_usd', label: 'Costo', type: 'money' }, col.when('created_at')],
        },
      ],
    }
  },

  pois(d) {
    const r = d.record
    const s = d.stats
    const hasCoords = Number.isFinite(Number(r.lat)) && Number.isFinite(Number(r.lng))
    const media = [
      r.image_url && { label: 'Foto original', url: r.image_url },
      r.cutout_image_url && { label: 'Recorte (Recraft)', url: r.cutout_image_url },
      r.stylized_image_url && { label: 'Estilizado (Recraft)', url: r.stylized_image_url },
      r.anim_video_url && { label: 'Video (Fal.ai)', url: r.anim_video_url, video: true },
    ].filter(Boolean)
    return {
      title: r.title,
      subtitle: r.body,
      image: r.cutout_image_url || r.stylized_image_url || r.image_url,
      badges: [r.rarity],
      flags: [
        r.active ? { label: 'Visible', tone: 'good' } : { label: 'Oculto', tone: 'warn' },
        r.video_prize_enabled ? { label: 'Premio de video', tone: 'info' } : null,
        !d.world.video_rewards_enabled && r.video_prize_enabled ? { label: 'Video apagado en el mundo', tone: 'warn' } : null,
      ].filter(Boolean),
      meta: [
        { label: 'Mundo', value: d.world.name, to: `/ops/worlds/${d.world.id}` },
        { label: 'Agregado por', value: d.author.name, to: d.author.id ? `/ops/users/${d.author.id}` : null },
        { label: 'Ubicación', value: hasCoords ? `${Number(r.lat).toFixed(5)}, ${Number(r.lng).toFixed(5)}` : '—', href: hasCoords ? `https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}` : null },
        { label: 'Radio de captura', value: `${r.radius_m} m` },
        { label: 'Identidad IA', value: r.character_identity || '—' },
        { label: 'Creado', value: formatDateTime(r.created_at) },
      ],
      stats: [
        { label: 'Capturas', value: formatNumber(s.captures) },
        { label: 'Reportes', value: formatNumber(s.reports), alert: s.reports > 0 },
        { label: 'En misiones', value: formatNumber(s.missions) },
        { label: 'Costo Fal', value: formatCurrency(s.fal_usd) },
        { label: 'Créditos Recraft', value: formatNumber(s.recraft_credits) },
      ],
      media,
      extraActions: r.anim_video_url ? [{ key: 'clear_video', label: 'Quitar video', tone: 'danger', confirm: 'El personaje queda sin animación. El costo ya pagado no se recupera.' }] : [],
      deletable: true,
      deleteMessage: `Se elimina «${r.title}» con sus ${s.captures} capturas. Si solo quieres retirarlo del mapa, usa Editar → Visible.`,
      sections: [
        {
          title: 'Capturado por', resource: 'captures', actionResource: 'captures', empty: 'Nadie lo ha capturado todavía.',
          rows: d.captures.map((c) => ({ id: c.id, jugador: c.player, user_id: c.user_id, foto: c.photo_url, captured_at: c.captured_at, personaje: r.title })),
          columns: [{ ...col.player, type: 'title', image: 'foto' }, col.when('captured_at', 'Capturado')],
        },
        {
          title: 'Reportes', actionResource: 'reports', empty: 'Sin reportes.',
          rows: reportRows(d.reports, { poi_id: r.id, character: r.title, world_id: d.world.id, world: d.world.name }),
          columns: [{ key: 'motivo', label: 'Motivo', type: 'title' }, { key: 'estado', label: 'Estado', type: 'badge' }, col.when('created_at')],
        },
        {
          title: 'Costos IA (ledger)', empty: 'Sin recursos IA generados.',
          rows: d.jobs.map((j) => ({ id: j.id, proveedor: j.provider, tipo: j.type, costo_usd: j.cost_usd, creditos: j.credits, created_at: j.created_at })),
          columns: [{ key: 'proveedor', label: 'Proveedor', type: 'badge' }, { key: 'tipo', label: 'Tipo', type: 'badge' }, { key: 'costo_usd', label: 'USD', type: 'money' }, col.num('creditos', 'Créditos'), { key: 'created_at', label: 'Fecha', type: 'date' }],
        },
      ],
    }
  },

  captures(d) {
    return {
      title: `${d.character.title ?? 'Personaje'} · ${d.player.name}`,
      subtitle: `Capturado ${formatRelative(d.record.captured_at)}`,
      image: d.record.photo_url || d.character.image,
      badges: [d.character.rarity],
      meta: [
        { label: 'Jugador', value: d.player.name, to: `/ops/users/${d.player.id}` },
        { label: 'Personaje', value: d.character.title ?? '—', to: d.character.id ? `/ops/pois/${d.character.id}` : null },
        { label: 'Mundo', value: d.world.name ?? '—', to: d.world.id ? `/ops/worlds/${d.world.id}` : null },
        { label: 'Fecha', value: formatDateTime(d.record.captured_at) },
        ...Object.entries(d.record.meta || {}).map(([key, value]) => ({ label: key, value: typeof value === 'object' ? JSON.stringify(value) : String(value) })),
      ],
      media: d.record.photo_url ? [{ label: 'Foto de la captura', url: d.record.photo_url }] : [],
      deletable: true,
      deleteMessage: 'Se borra la captura. El jugador podrá volver a capturar este personaje. Los puntos locales de la app no se recalculan.',
      sections: [],
    }
  },

  explorers(d) {
    const r = d.record
    return {
      title: r.nickname,
      subtitle: `Explorador en ${d.world.name}`,
      image: r.avatar_url,
      badges: ['kid'],
      flags: [d.kid_user_id ? { label: 'Emparejado', tone: 'good' } : { label: 'Sin emparejar', tone: 'warn' }],
      meta: [
        { label: 'Mundo', value: d.world.name, to: `/ops/worlds/${d.world.id}` },
        { label: 'Adulto', value: d.owner.name, to: `/ops/users/${d.owner.id}` },
        { label: 'Cuenta del niño', value: d.kid_user_id ? 'Ver cuenta' : 'Aún no entró', to: d.kid_user_id ? `/ops/users/${d.kid_user_id}` : null },
        { label: 'Creado', value: formatDateTime(r.created_at) },
      ],
      stats: [
        { label: 'Capturas', value: formatNumber(d.stats.captures) },
        { label: 'Puntos', value: formatNumber(d.stats.points) },
        { label: 'Nivel', value: formatNumber(d.stats.level) },
      ],
      deletable: true,
      deleteMessage: `Se elimina a «${r.nickname}» de ${d.world.name}. Su cuenta de niño y capturas no se borran (puedes hacerlo desde su cuenta).`,
      sections: [
        {
          title: 'Capturas', resource: 'captures', actionResource: 'captures', empty: 'Sin capturas.',
          rows: d.captures.map((c) => ({ id: c.id, personaje: c.character ?? '—', poi_id: c.poi_id, imagen: c.image, captured_at: c.captured_at, jugador: r.nickname })),
          columns: [{ ...col.character, type: 'title', image: 'imagen' }, col.when('captured_at', 'Capturado')],
        },
        {
          title: 'Códigos de acceso (PIN / QR)', actionResource: 'pair-tokens', empty: 'Nunca se generó un código.',
          rows: d.tokens.map((t) => ({ id: t.id, estado: t.status, created_at: t.created_at, expires_at: t.expires_at, used_at: t.used_at })),
          columns: [{ key: 'estado', label: 'Estado', type: 'badge' }, col.when('created_at', 'Creado'), { key: 'expires_at', label: 'Vence', type: 'relative' }, col.when('used_at', 'Usado')],
        },
      ],
    }
  },
}

function sectionActions(section, row) {
  if (!section.actionResource) return []
  return (findResource(section.actionResource)?.actions ?? []).filter((action) => !action.when || action.when(row))
}

function openRelated(section, row) {
  if (section.resource && findResource(section.resource)?.detail) router.push(`/ops/${section.resource}/${row.id}`)
}

async function run(resource, id, action, payload, success) {
  busy.value = true
  try {
    await mutate(resource, id, action, payload)
    toast(success)
    return true
  } catch (err) {
    toast(err.message ?? 'No se pudo completar la acción.', 'bad')
    return false
  } finally {
    busy.value = false
  }
}

async function runRowAction(resource, action, row) {
  let payload = action.payload ? action.payload(row) : {}
  if (action.fields) {
    const values = Object.fromEntries(action.fields.map((field) => [field.key, row[field.source ?? field.key]]))
    const edited = await editForm({ title: action.label, fields: action.fields, values })
    if (!edited) return
    payload = edited
  } else if (action.confirm) {
    const ok = await confirmAction({ title: action.label, message: action.confirm(row), confirmLabel: action.label, danger: action.tone === 'danger' })
    if (!ok) return
  }
  if (await run(resource, row.id, action.action ?? action.key, payload, `${action.label}: listo.`)) await refresh()
}

async function edit() {
  const fields = editSchemas[props.resource]
  const record = data.value.record
  const values = Object.fromEntries(fields.map((field) => [field.key, record[field.key]]))
  const edited = await editForm({ title: `Editar ${config.value.label.toLowerCase()}`, fields, values })
  if (!edited) return
  if (await run(props.resource, props.id, 'update', edited, 'Cambios guardados.')) await refresh()
}

async function runExtra(action) {
  const ok = await confirmAction({ title: action.label, message: action.confirm, confirmLabel: action.label, danger: action.tone === 'danger' })
  if (!ok) return
  if (await run(props.resource, props.id, action.key, {}, `${action.label}: listo.`)) await refresh()
}

async function remove() {
  const ok = await confirmAction({
    title: `Eliminar «${view.value.title}»`,
    message: view.value.deleteMessage,
    confirmLabel: 'Eliminar definitivamente',
    danger: true,
    typed: view.value.typed ?? '',
  })
  if (!ok) return
  if (await run(props.resource, props.id, 'delete', {}, 'Eliminado.')) router.replace(`/ops/${props.resource}`)
}
</script>

<style scoped>
.hero { display: grid; grid-template-columns: auto minmax(0, 1fr) auto; gap: 1.25rem; align-items: start; margin-bottom: 1rem; }
.hero-media img, .hero-fallback { width: 112px; height: 112px; border-radius: 16px; object-fit: cover; background: #0d1527; }
.hero-fallback { display: grid; place-items: center; color: var(--ops-cyan); font-family: var(--font-display); font-size: 2rem; background: rgba(86,215,237,.1); }
.hero-badges { display: flex; flex-wrap: wrap; gap: .35rem; margin-bottom: .45rem; }
h1 { margin: 0; color: var(--ops-text); font-family: var(--font-display); font-size: clamp(1.6rem, 3.5vw, 2.5rem); overflow-wrap: anywhere; }
.hero-sub { margin: .3rem 0 0; color: var(--ops-muted); font-size: .86rem; }
.hero-meta { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: .7rem 1.2rem; margin: 1rem 0 0; }
.hero-meta dt { color: var(--ops-muted); font-size: .64rem; letter-spacing: .08em; text-transform: uppercase; }
.hero-meta dd { margin: .15rem 0 0; color: var(--ops-text); font-size: .82rem; overflow-wrap: anywhere; }
.hero-meta a { color: var(--ops-cyan); text-decoration: none; }
.hero-meta a:hover { text-decoration: underline; }
.hero-actions { display: flex; flex-direction: column; gap: .45rem; }
.stat-strip { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: .6rem; margin-bottom: 1rem; }
.stat { display: grid; gap: .2rem; padding: .85rem 1rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); color: inherit; text-decoration: none; }
.stat strong { color: var(--ops-text); font-family: var(--font-display); font-size: 1.45rem; font-variant-numeric: tabular-nums; }
.stat span { color: var(--ops-muted); font-size: .72rem; }
.stat.alert { border-color: rgba(255,196,87,.45); }
.stat.alert strong { color: #ffc457; }
.media-panel, .ops-panel + .ops-panel { margin-bottom: 1rem; }
.media-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); gap: .75rem; }
figure { margin: 0; }
figure img, figure video { width: 100%; aspect-ratio: 1; border: 1px solid var(--ops-line); border-radius: 10px; object-fit: contain; background: #0d1527; }
figcaption { margin-top: .35rem; color: var(--ops-muted); font-size: .7rem; }
.config-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: .6rem; margin: 0; }
.config-grid dt { color: var(--ops-muted); font-size: .68rem; }
.config-grid dd { margin: .15rem 0 0; color: var(--ops-text); font-weight: 700; }
.sections { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; }
.related h3 small { margin-left: .35rem; color: var(--ops-muted); font-size: .72rem; font-weight: 600; }
.related-list { display: grid; }
.related-row { display: flex; align-items: center; justify-content: space-between; gap: .75rem; padding: .6rem .4rem; border-top: 1px solid var(--ops-line); border-radius: 6px; }
.related-row:first-child { border-top: 0; }
.related-row.clickable { cursor: pointer; }
.related-row.clickable:hover { background: rgba(86,215,237,.05); }
.related-cells { display: flex; flex-wrap: wrap; align-items: center; gap: .4rem 1.1rem; min-width: 0; flex: 1; font-size: .78rem; color: #c5cee1; }
.related-cell { display: grid; gap: .1rem; min-width: 0; }
.related-cell.wide { flex: 1 1 180px; }
.related-cell small { color: var(--ops-muted); font-size: .6rem; letter-spacing: .06em; text-transform: uppercase; }
.related-actions { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: .3rem; }
.empty { margin: 0; font-size: .8rem; }
.more-note { margin: .5rem 0 0; font-size: .72rem; }
@media (max-width: 1100px) {
  .sections { grid-template-columns: 1fr; }
}
@media (max-width: 760px) {
  .hero { grid-template-columns: 1fr; }
  .hero-actions { flex-direction: row; flex-wrap: wrap; }
  .related-row { flex-direction: column; align-items: stretch; }
  .related-actions { justify-content: flex-start; }
}
</style>
