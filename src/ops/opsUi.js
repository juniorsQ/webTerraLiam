export const opsResources = [
  { key: 'users', label: 'Cuentas', mark: '◈', group: 'Operación' },
  { key: 'explorers', label: 'Niños', mark: '△', group: 'Operación' },
  { key: 'worlds', label: 'Mundos', mark: '◎', group: 'Operación' },
  { key: 'pois', label: 'Personajes', mark: '✦', group: 'Operación' },
  { key: 'captures', label: 'Capturas', mark: '▣', group: 'Operación' },
  { key: 'provider-jobs', label: 'Jobs API', mark: '▷', group: 'Economía' },
  { key: 'prize-grants', label: 'Premios', mark: '◇', group: 'Economía' },
  { key: 'progress', label: 'Progreso', mark: '▲', group: 'Economía' },
  { key: 'storage', label: 'Storage', mark: '▤', group: 'Sistema' },
  { key: 'pair-tokens', label: 'Tokens', mark: '⚿', group: 'Sistema' },
  { key: 'missions', label: 'Misiones', mark: '⚑', group: 'Sistema' },
  { key: 'reports', label: 'Reportes', mark: '⚠', group: 'Sistema' },
  { key: 'analytics', label: 'Señales', mark: '◉', group: 'Sistema' },
]

export const opsNavGroups = ['Operación', 'Economía', 'Sistema']

export const columnLabels = {
  nombre: 'Nombre',
  avatar_url: 'Foto',
  created_at: 'Creado',
  mundos_creados: 'Mundos',
  representados: 'Niños',
  ninos_representados: 'Niños',
  rol: 'Rol',
  mundo: 'Mundo',
  visibilidad: 'Visibilidad',
  padre: 'Creador',
  ninos: 'Niños',
  miembros: 'Miembros',
  premios_video: 'Premios video',
  personajes: 'Personajes',
  capturas: 'Capturas',
  nino: 'Niño',
  creado_por: 'Agregado por',
  agregado_por: 'Agregado por',
  hallazgo: 'Personaje',
  personaje: 'Personaje',
  rareza: 'Rareza',
  activo: 'Activo',
  image_url: 'Foto',
  cutout_image_url: 'Recorte',
  stylized_image_url: 'Estilizado',
  premio_video: 'Premio video',
  anim_video_url: 'Video',
  jugador: 'Jugador',
  photo_url: 'Foto',
  captured_at: 'Capturado',
  solicitado_por: 'Solicitado por',
  estado: 'Estado',
  costo_usd: 'Costo USD',
  completed_at: 'Completado',
  error: 'Error',
  nivel: 'Nivel',
  puntos: 'Puntos',
  used_at: 'Usado',
  correo: 'Correo',
  ultimo_acceso: 'Último acceso',
  proveedor: 'Proveedor',
  tipo: 'Tipo',
  creditos: 'Créditos',
  origen: 'Origen',
  archivo: 'Archivo',
  bytes: 'Tamaño',
  expires_at: 'Vence',
  creditos_premio: 'Créditos premio',
  mision: 'Misión',
  activa: 'Activa',
  pasos: 'Pasos',
  reportado_por: 'Reportado por',
  motivo: 'Motivo',
  evento: 'Evento',
  cuenta: 'Cuenta',
}

const rarityLabels = {
  common: 'Común',
  rare: 'Raro',
  epic: 'Épico',
}

const visibilityLabels = {
  private: 'Privado',
  public: 'Público',
}

const statusLabels = {
  pending: 'Pendiente',
  granted: 'Otorgado',
  denied: 'Negado',
  queued: 'En cola',
  processing: 'Procesando',
  completed: 'Completado',
  failed: 'Fallido',
  cancelled: 'Cancelado',
  active: 'Activo',
  used: 'Usado',
  expired: 'Vencido',
  open: 'Abierto',
  new: 'Nuevo',
}

export function labelColumn(column) {
  return columnLabels[column] ?? column.replace(/_/g, ' ')
}

export function labelRarity(value) {
  return rarityLabels[String(value || '').toLowerCase()] ?? value ?? 'Sin rareza'
}

export function labelVisibility(value) {
  return visibilityLabels[String(value || '').toLowerCase()] ?? value ?? 'Sin visibilidad'
}

export function formatNumber(value) {
  return new Intl.NumberFormat('es-CO').format(Number(value || 0))
}

export function formatCurrency(value) {
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'USD' }).format(Number(value || 0))
}

export function formatBytes(value) {
  const bytes = Number(value || 0)
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
}

export function formatDateTime(value) {
  if (!value) return 'Sin fecha'
  return new Intl.DateTimeFormat('es-CO', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
}

export function formatWeekLabel(value) {
  if (!value) return ''
  return new Intl.DateTimeFormat('es-CO', { day: 'numeric', month: 'short' }).format(new Date(`${value}T12:00:00`))
}

export function formatRelative(value) {
  if (!value) return 'sin fecha'
  const minutes = Math.max(0, Math.round((Date.now() - new Date(value).getTime()) / 60000))
  if (minutes < 1) return 'ahora'
  if (minutes < 60) return `hace ${minutes} min`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `hace ${hours} h`
  const days = Math.round(hours / 24)
  if (days < 14) return `hace ${days} d`
  return new Date(value).toLocaleDateString('es-CO', { day: '2-digit', month: 'short' })
}

export function initials(value) {
  return String(value || 'TL').split(/\s+/).filter(Boolean).slice(0, 2).map((word) => word[0]).join('').toUpperCase()
}

export function formatCell(column, value) {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'boolean') return value ? 'Sí' : 'No'
  if (column === 'rareza') return labelRarity(value)
  if (column === 'visibilidad') return labelVisibility(value)
  if (column === 'estado') return statusLabels[String(value).toLowerCase()] ?? value
  if (column === 'costo_usd') return formatCurrency(value)
  if (column === 'bytes') return formatBytes(value)
  if (typeof value === 'object') return Object.entries(value).map(([key, item]) => `${labelColumn(key)}: ${item}`).join(' · ')
  return String(value)
}

export function isImageColumn(column, value) {
  return typeof value === 'string' && /^https?:\/\//i.test(value) && /(image|photo|avatar|cutout|stylized|video|url|imagen)/i.test(column)
}

export function isDateColumn(column, value) {
  return typeof value === 'string' && /(created_at|captured_at|completed_at|updated_at|used_at|ultimo_acceso|expires_at)/i.test(column) && !Number.isNaN(Date.parse(value))
}
