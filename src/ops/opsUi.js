// Ops resource catalogue: what each list shows, how it filters, which entity
// a cell links to, and which audited actions (ops_mutate) an operator can run.

const rarityOptions = [
  { value: 'common', label: 'Común' },
  { value: 'rare', label: 'Raro' },
  { value: 'epic', label: 'Épico' },
]

export const opsResources = [
  {
    key: 'users',
    label: 'Cuentas',
    mark: '◈',
    group: 'Personas',
    detail: true,
    hint: 'Adultos que crean mundos y cuentas de niño (asiento sintético @kid.terraliam.app).',
    search: 'Nombre o correo',
    filters: [
      { value: 'adult', label: 'Adultos' },
      { value: 'kid', label: 'Niños' },
      { value: 'admin', label: 'Admins' },
      { value: 'no_world', label: 'Adultos sin mundo' },
      { value: 'never', label: 'Nunca entró' },
      { value: 'orphan', label: 'Sin perfil' },
    ],
    columns: [
      { key: 'nombre', label: 'Cuenta', type: 'title', image: 'avatar_url', sub: 'correo' },
      { key: 'tipo', label: 'Tipo', type: 'badge' },
      { key: 'mundos_nombres', label: 'Mundos' },
      { key: 'mundos_creados', label: 'Creó', type: 'number' },
      { key: 'capturas', label: 'Capturas', type: 'number' },
      { key: 'ultimo_acceso', label: 'Último acceso', type: 'relative' },
      { key: 'created_at', label: 'Alta', type: 'date' },
    ],
  },
  {
    key: 'explorers',
    label: 'Niños',
    mark: '△',
    group: 'Personas',
    detail: true,
    hint: 'Exploradores creados por el adulto dentro de un mundo. "Emparejado" = ya entró desde un dispositivo.',
    search: 'Apodo, mundo o adulto',
    filters: [
      { value: 'paired', label: 'Emparejados' },
      { value: 'unpaired', label: 'Sin emparejar' },
    ],
    columns: [
      { key: 'nino', label: 'Niño', type: 'title', image: 'avatar_url' },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'padre', label: 'Adulto', link: { resource: 'users', id: 'owner_id' } },
      { key: 'emparejado', label: 'Emparejado', type: 'bool' },
      { key: 'capturas', label: 'Capturas', type: 'number' },
      { key: 'created_at', label: 'Creado', type: 'date' },
    ],
    actions: [
      { key: 'delete', label: 'Eliminar', tone: 'danger', confirm: (row) => `¿Eliminar al explorador «${row.nino}»? Su cuenta de niño queda sin asiento en el mundo.` },
    ],
  },
  {
    key: 'worlds',
    label: 'Mundos',
    mark: '◎',
    group: 'Juego',
    detail: true,
    hint: 'Cada mundo es una familia jugando: un adulto, sus niños y los personajes escondidos.',
    search: 'Mundo, adulto o código',
    filters: [
      { value: 'private', label: 'Privados' },
      { value: 'public', label: 'Públicos' },
      { value: 'video', label: 'Con premios de video' },
      { value: 'empty', label: 'Sin personajes' },
      { value: 'dormant', label: 'Dormidos 30d' },
    ],
    columns: [
      { key: 'mundo', label: 'Mundo', type: 'title', sub: 'codigo' },
      { key: 'padre', label: 'Adulto', link: { resource: 'users', id: 'owner_id' } },
      { key: 'visibilidad', label: 'Visibilidad', type: 'badge' },
      { key: 'ninos', label: 'Niños', type: 'number' },
      { key: 'personajes', label: 'Personajes', type: 'number' },
      { key: 'capturas', label: 'Capturas', type: 'number' },
      { key: 'capturas_7d', label: '7 días', type: 'number' },
      { key: 'premios_video', label: 'Video IA', type: 'bool' },
      { key: 'ultima_captura', label: 'Última captura', type: 'relative' },
    ],
  },
  {
    key: 'pois',
    label: 'Personajes',
    mark: '✦',
    group: 'Juego',
    detail: true,
    hint: 'Hallazgos que el adulto esconde en el mapa para que los niños los capturen.',
    search: 'Personaje o mundo',
    filters: [
      ...rarityOptions,
      { value: 'never_captured', label: 'Nunca capturados' },
      { value: 'video', label: 'Con video' },
      { value: 'inactive', label: 'Ocultos' },
    ],
    columns: [
      { key: 'personaje', label: 'Personaje', type: 'title', image: 'imagen' },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'rareza', label: 'Rareza', type: 'badge' },
      { key: 'activo', label: 'Visible', type: 'bool' },
      { key: 'capturas', label: 'Capturas', type: 'number' },
      { key: 'tiene_video', label: 'Video', type: 'bool' },
      { key: 'agregado_por', label: 'Agregado por', link: { resource: 'users', id: 'author_id' } },
      { key: 'created_at', label: 'Creado', type: 'date' },
    ],
    actions: [
      { key: 'hide', action: 'update', label: 'Ocultar', when: (row) => row.activo, payload: () => ({ active: false }) },
      { key: 'show', action: 'update', label: 'Mostrar', when: (row) => !row.activo, payload: () => ({ active: true }) },
    ],
  },
  {
    key: 'captures',
    label: 'Capturas',
    mark: '▣',
    group: 'Juego',
    detail: true,
    hint: 'Cada vez que un jugador encuentra y fotografía un personaje.',
    search: 'Jugador, personaje o mundo',
    filters: [
      { value: 'today', label: 'Hoy' },
      { value: '7d', label: 'Últimos 7 días' },
    ],
    columns: [
      { key: 'personaje', label: 'Personaje', type: 'title', image: 'foto', link: { resource: 'pois', id: 'poi_id' } },
      { key: 'jugador', label: 'Jugador', link: { resource: 'users', id: 'user_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'rareza', label: 'Rareza', type: 'badge' },
      { key: 'captured_at', label: 'Capturado', type: 'relative' },
    ],
    actions: [
      { key: 'delete', label: 'Eliminar', tone: 'danger', confirm: (row) => `¿Eliminar la captura de «${row.personaje}» de ${row.jugador}? El jugador podrá volver a capturarlo.` },
    ],
  },
  {
    key: 'missions',
    label: 'Misiones',
    mark: '⚑',
    group: 'Juego',
    search: 'Misión o mundo',
    filters: [
      { value: 'active', label: 'Activas' },
      { value: 'inactive', label: 'Pausadas' },
    ],
    columns: [
      { key: 'mision', label: 'Misión', type: 'title' },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'activa', label: 'Activa', type: 'bool' },
      { key: 'pasos', label: 'Pasos', type: 'number' },
      { key: 'completadas', label: 'Completadas', type: 'number' },
      { key: 'created_at', label: 'Creada', type: 'date' },
    ],
    actions: [
      { key: 'pause', action: 'update', label: 'Pausar', when: (row) => row.activa, payload: () => ({ active: false }) },
      { key: 'resume', action: 'update', label: 'Activar', when: (row) => !row.activa, payload: () => ({ active: true }) },
      { key: 'delete', label: 'Eliminar', tone: 'danger', confirm: (row) => `¿Eliminar la misión «${row.mision}» y su progreso?` },
    ],
  },
  {
    key: 'prize-grants',
    label: 'Premios',
    mark: '◇',
    group: 'Recompensas',
    hint: 'Solicitudes de premio al subir de nivel. Aprobar da un crédito de video IA al jugador.',
    search: 'Jugador o mundo',
    filters: [
      { value: 'pending', label: 'Pendientes' },
      { value: 'granted', label: 'Aprobados' },
      { value: 'denied', label: 'Negados' },
    ],
    columns: [
      { key: 'jugador', label: 'Jugador', type: 'title', link: { resource: 'users', id: 'user_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'nivel', label: 'Nivel', type: 'number' },
      { key: 'puntos', label: 'Puntos', type: 'number' },
      { key: 'estado', label: 'Estado', type: 'badge' },
      { key: 'used_at', label: 'Usado', type: 'relative' },
      { key: 'created_at', label: 'Solicitado', type: 'relative' },
    ],
    actions: [
      { key: 'grant', label: 'Aprobar', tone: 'good', when: (row) => row.estado !== 'granted' && !row.used_at },
      { key: 'deny', label: 'Negar', when: (row) => row.estado !== 'denied' && !row.used_at },
    ],
  },
  {
    key: 'progress',
    label: 'Progreso',
    mark: '▲',
    group: 'Recompensas',
    hint: 'Puntos y nivel de cada jugador por mundo. Los créditos premio se gastan al pedir un video IA.',
    search: 'Jugador o mundo',
    filters: [{ value: 'credits', label: 'Con créditos' }],
    columns: [
      { key: 'jugador', label: 'Jugador', type: 'title', link: { resource: 'users', id: 'user_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'nivel', label: 'Nivel', type: 'number' },
      { key: 'puntos', label: 'Puntos', type: 'number' },
      { key: 'capturas', label: 'Capturas', type: 'number' },
      { key: 'creditos_premio', label: 'Créditos premio', type: 'number' },
      { key: 'updated_at', label: 'Actualizado', type: 'relative' },
    ],
    actions: [
      {
        key: 'edit',
        action: 'update',
        label: 'Ajustar',
        fields: [
          { key: 'level', source: 'nivel', label: 'Nivel', type: 'number', min: 0 },
          { key: 'points', source: 'puntos', label: 'Puntos', type: 'number', min: 0 },
          { key: 'prize_credits', source: 'creditos_premio', label: 'Créditos premio', type: 'number', min: 0 },
        ],
      },
    ],
  },
  {
    key: 'videos',
    label: 'Videos IA',
    mark: '▶',
    group: 'Economía IA',
    hint: 'Animaciones generadas con Fal.ai para las tarjetas de personaje.',
    search: 'Personaje o mundo',
    columns: [
      { key: 'video', label: 'Video', type: 'video', poster: 'poster' },
      { key: 'personaje', label: 'Personaje', type: 'title', link: { resource: 'pois', id: 'id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'padre', label: 'Adulto' },
      { key: 'created_at', label: 'Creado', type: 'date' },
    ],
    actions: [
      { key: 'clear_video', label: 'Quitar video', tone: 'danger', confirm: (row) => `¿Quitar el video de «${row.personaje}»? El personaje queda sin animación.` },
    ],
  },
  {
    key: 'video-jobs',
    label: 'Jobs de video',
    mark: '▷',
    group: 'Economía IA',
    hint: 'Cola real de generación (request_video_generation). Atascado = más de 30 min en cola o procesando.',
    search: 'Personaje, mundo o solicitante',
    filters: [
      { value: 'queued', label: 'En cola' },
      { value: 'processing', label: 'Procesando' },
      { value: 'completed', label: 'Completados' },
      { value: 'failed', label: 'Fallidos' },
      { value: 'cancelled', label: 'Cancelados' },
    ],
    columns: [
      { key: 'personaje', label: 'Personaje', type: 'title', link: { resource: 'pois', id: 'poi_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'solicitado_por', label: 'Solicitado por', link: { resource: 'users', id: 'user_id' } },
      { key: 'estado', label: 'Estado', type: 'badge' },
      { key: 'costo_usd', label: 'Costo', type: 'money' },
      { key: 'error', label: 'Error', type: 'clip' },
      { key: 'created_at', label: 'Creado', type: 'relative' },
    ],
    actions: [
      { key: 'cancel', label: 'Cancelar', tone: 'danger', when: (row) => ['queued', 'processing'].includes(row.estado), confirm: () => '¿Cancelar este job? Libera el cupo mensual del mundo.' },
    ],
  },
  {
    key: 'provider-jobs',
    label: 'Ledger de costos',
    mark: '¤',
    group: 'Economía IA',
    hint: 'Registro de cada recurso IA generado (video Fal, recorte/estilizado Recraft) con su costo estimado.',
    search: 'Personaje, mundo o tipo',
    filters: [
      { value: 'fal', label: 'Fal.ai' },
      { value: 'recraft', label: 'Recraft' },
    ],
    columns: [
      { key: 'proveedor', label: 'Proveedor', type: 'badge' },
      { key: 'tipo', label: 'Tipo', type: 'badge' },
      { key: 'personaje', label: 'Personaje', link: { resource: 'pois', id: 'poi_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'costo_usd', label: 'USD', type: 'money' },
      { key: 'creditos', label: 'Créditos', type: 'number' },
      { key: 'origen', label: 'Origen', type: 'badge' },
      { key: 'created_at', label: 'Fecha', type: 'date' },
    ],
  },
  {
    key: 'reports',
    label: 'Reportes',
    mark: '⚠',
    group: 'Moderación',
    hint: 'Contenido reportado por las familias. "Ocultar personaje" lo retira del mapa y marca el reporte como revisado.',
    search: 'Motivo, personaje o mundo',
    filters: [
      { value: 'open', label: 'Abiertos' },
      { value: 'reviewed', label: 'Revisados' },
      { value: 'dismissed', label: 'Descartados' },
    ],
    columns: [
      { key: 'motivo', label: 'Motivo', type: 'title' },
      { key: 'personaje', label: 'Personaje', link: { resource: 'pois', id: 'poi_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'reportado_por', label: 'Reportado por', link: { resource: 'users', id: 'user_id' } },
      { key: 'estado', label: 'Estado', type: 'badge' },
      { key: 'created_at', label: 'Fecha', type: 'relative' },
    ],
    actions: [
      { key: 'hide_character', label: 'Ocultar personaje', tone: 'danger', when: (row) => row.estado === 'open' && row.poi_id, confirm: (row) => `¿Ocultar «${row.personaje}» del mapa y cerrar el reporte?` },
      { key: 'review', label: 'Revisado', tone: 'good', when: (row) => row.estado === 'open' },
      { key: 'dismiss', label: 'Descartar', when: (row) => row.estado === 'open' },
      { key: 'reopen', label: 'Reabrir', when: (row) => row.estado !== 'open' },
    ],
  },
  {
    key: 'pair-tokens',
    label: 'Códigos de acceso',
    mark: '⚿',
    group: 'Sistema',
    hint: 'PIN/QR temporales para que un niño entre a su mundo desde otro dispositivo.',
    search: 'Mundo o niño',
    filters: [
      { value: 'active', label: 'Vigentes' },
      { value: 'used', label: 'Usados' },
      { value: 'expired', label: 'Vencidos' },
    ],
    columns: [
      { key: 'nino', label: 'Niño', type: 'title', link: { resource: 'explorers', id: 'explorer_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'estado', label: 'Estado', type: 'badge' },
      { key: 'created_at', label: 'Creado', type: 'relative' },
      { key: 'expires_at', label: 'Vence', type: 'date' },
      { key: 'used_at', label: 'Usado', type: 'relative' },
    ],
    actions: [
      { key: 'revoke', label: 'Revocar', tone: 'danger', when: (row) => row.estado === 'active', confirm: () => '¿Revocar este código? Dejará de funcionar de inmediato.' },
    ],
  },
  {
    key: 'storage',
    label: 'Archivos',
    mark: '▤',
    group: 'Sistema',
    hint: 'Bucket público poi-media (fotos, recortes y videos de personajes).',
    search: 'Ruta del archivo',
    filters: [
      { value: 'image', label: 'Imágenes' },
      { value: 'video', label: 'Videos' },
    ],
    columns: [
      { key: 'archivo', label: 'Archivo', type: 'file' },
      { key: 'tipo', label: 'Tipo' },
      { key: 'bytes', label: 'Tamaño', type: 'bytes' },
      { key: 'created_at', label: 'Subido', type: 'date' },
    ],
  },
  {
    key: 'analytics',
    label: 'Eventos',
    mark: '◉',
    group: 'Sistema',
    hint: 'analytics_events enviados por la app.',
    search: 'Evento, mundo o cuenta',
    columns: [
      { key: 'evento', label: 'Evento', type: 'title' },
      { key: 'cuenta', label: 'Cuenta', link: { resource: 'users', id: 'user_id' } },
      { key: 'mundo', label: 'Mundo', link: { resource: 'worlds', id: 'world_id' } },
      { key: 'datos', label: 'Datos', type: 'json' },
      { key: 'created_at', label: 'Fecha', type: 'relative' },
    ],
  },
  {
    key: 'audit',
    label: 'Auditoría',
    mark: '☰',
    group: 'Sistema',
    hint: 'Toda acción hecha desde Ops queda registrada con operador y fecha.',
    search: 'Objetivo, operador o acción',
    filters: [
      { value: 'worlds', label: 'Mundos' },
      { value: 'pois', label: 'Personajes' },
      { value: 'users', label: 'Cuentas' },
      { value: 'reports', label: 'Reportes' },
      { value: 'prize-grants', label: 'Premios' },
      { value: 'settings', label: 'Ajustes' },
    ],
    columns: [
      { key: 'accion', label: 'Acción', type: 'badge' },
      { key: 'recurso', label: 'Recurso', type: 'resource' },
      { key: 'objetivo', label: 'Objetivo', type: 'title' },
      { key: 'operador', label: 'Operador' },
      { key: 'datos', label: 'Cambios', type: 'json' },
      { key: 'created_at', label: 'Fecha', type: 'relative' },
    ],
  },
]

export const opsNavGroups = ['Personas', 'Juego', 'Recompensas', 'Economía IA', 'Moderación', 'Sistema']

export function findResource(key) {
  return opsResources.find((item) => item.key === key)
}

// Editable fields for the detail page (payload keys match ops_mutate).
export const editSchemas = {
  users: [{ key: 'display_name', label: 'Nombre visible', type: 'text', minlength: 2 }],
  worlds: [
    { key: 'name', label: 'Nombre del mundo', type: 'text', minlength: 2 },
    { key: 'visibility', label: 'Visibilidad', type: 'select', options: [{ value: 'private', label: 'Privado' }, { value: 'public', label: 'Público' }] },
    { key: 'video_rewards_enabled', label: 'Premios de video IA habilitados', type: 'bool' },
  ],
  pois: [
    { key: 'title', label: 'Nombre', type: 'text', minlength: 1 },
    { key: 'body', label: 'Descripción / pista', type: 'textarea' },
    { key: 'rarity', label: 'Rareza', type: 'select', options: rarityOptions },
    { key: 'radius_m', label: 'Radio de captura (m)', type: 'number', min: 5, max: 200 },
    { key: 'active', label: 'Visible en el mapa', type: 'bool' },
    { key: 'video_prize_enabled', label: 'Elegible para premio de video', type: 'bool' },
  ],
  explorers: [{ key: 'nickname', label: 'Apodo', type: 'text', minlength: 2, maxlength: 20 }],
}

const badgeMap = {
  admin: ['Admin', 'info'],
  adult: ['Adulto', 'neutral'],
  kid: ['Niño', 'good'],
  private: ['Privado', 'neutral'],
  public: ['Público', 'info'],
  common: ['Común', 'common'],
  rare: ['Raro', 'rare'],
  epic: ['Épico', 'epic'],
  pending: ['Pendiente', 'warn'],
  granted: ['Aprobado', 'good'],
  denied: ['Negado', 'neutral'],
  queued: ['En cola', 'warn'],
  processing: ['Procesando', 'info'],
  completed: ['Completado', 'good'],
  failed: ['Fallido', 'bad'],
  cancelled: ['Cancelado', 'neutral'],
  active: ['Vigente', 'good'],
  used: ['Usado', 'neutral'],
  expired: ['Vencido', 'neutral'],
  open: ['Abierto', 'bad'],
  reviewed: ['Revisado', 'good'],
  dismissed: ['Descartado', 'neutral'],
  fal: ['Fal.ai', 'info'],
  recraft: ['Recraft', 'epic'],
  video: ['Video', 'info'],
  cutout: ['Recorte', 'neutral'],
  stylized: ['Estilizado', 'neutral'],
  live: ['En vivo', 'good'],
  backfill: ['Histórico', 'neutral'],
  update: ['Editó', 'info'],
  delete: ['Eliminó', 'bad'],
  grant: ['Aprobó', 'good'],
  deny: ['Negó', 'neutral'],
  review: ['Revisó', 'good'],
  dismiss: ['Descartó', 'neutral'],
  reopen: ['Reabrió', 'warn'],
  hide_character: ['Ocultó', 'warn'],
  revoke: ['Revocó', 'warn'],
  cancel: ['Canceló', 'warn'],
  clear_video: ['Quitó video', 'warn'],
  owner: ['Dueño', 'info'],
  editor: ['Editor', 'neutral'],
  player: ['Jugador', 'good'],
}

export function badge(value) {
  const entry = badgeMap[String(value ?? '').toLowerCase()]
  return entry ? { label: entry[0], tone: entry[1] } : { label: value ?? '—', tone: 'neutral' }
}

export function labelRarity(value) {
  return badge(value || 'common').label
}

export function resourceLabel(key) {
  return findResource(key)?.label ?? (key === 'settings' ? 'Ajustes' : key)
}

export function formatNumber(value) {
  return new Intl.NumberFormat('es-CO').format(Number(value || 0))
}

export function formatCurrency(value) {
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'USD', minimumFractionDigits: 2 }).format(Number(value || 0))
}

export function formatPercent(value) {
  return `${Math.round(Number(value || 0) * 100)}%`
}

export function formatBytes(value) {
  const bytes = Number(value || 0)
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
}

export function formatDateTime(value) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('es-CO', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
}

export function formatDate(value) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('es-CO', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(value))
}

export function formatDayLabel(value) {
  if (!value) return ''
  return new Intl.DateTimeFormat('es-CO', { day: 'numeric', month: 'short' }).format(new Date(`${value}T12:00:00`))
}

export function formatRelative(value) {
  if (!value) return '—'
  const minutes = Math.round((Date.now() - new Date(value).getTime()) / 60000)
  if (minutes < 0) {
    const ahead = Math.abs(minutes)
    if (ahead < 60) return `en ${ahead} min`
    if (ahead < 60 * 24) return `en ${Math.round(ahead / 60)} h`
    return `en ${Math.round(ahead / 1440)} d`
  }
  if (minutes < 1) return 'ahora'
  if (minutes < 60) return `hace ${minutes} min`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `hace ${hours} h`
  const days = Math.round(hours / 24)
  if (days < 30) return `hace ${days} d`
  return formatDate(value)
}

export function initials(value) {
  return String(value || 'TL').split(/\s+/).filter(Boolean).slice(0, 2).map((word) => word[0]).join('').toUpperCase()
}

export function delta(current, previous) {
  const now = Number(current || 0)
  const before = Number(previous || 0)
  if (!before && !now) return { label: 'sin cambios', tone: 'neutral' }
  if (!before) return { label: 'nuevo', tone: 'good' }
  const pct = Math.round(((now - before) / before) * 100)
  if (pct === 0) return { label: '= semana anterior', tone: 'neutral' }
  return { label: `${pct > 0 ? '▲' : '▼'} ${Math.abs(pct)}% vs semana ant.`, tone: pct > 0 ? 'good' : 'bad' }
}
