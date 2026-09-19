export function emphasize(text) {
  const escaped = String(text ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
  return escaped.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
}

export function asParagraphs(value) {
  if (Array.isArray(value)) return value.map((item) => String(item).trim()).filter(Boolean)
  return String(value ?? '')
    .split(/\n+/)
    .map((item) => item.trim())
    .filter(Boolean)
}

export function asList(value) {
  return asParagraphs(value).map((item) => item.replace(/^[-•]\s+/, ''))
}

export const LEGAL_SLUGS = {
  privacidad: 'privacy',
  terminos: 'terms',
  familias: 'families',
  'eliminar-cuenta': 'deleteAccount',
}

export const LEGAL_PAGES = [
  { slug: 'privacidad', label: 'Privacidad' },
  { slug: 'terminos', label: 'Términos' },
  { slug: 'familias', label: 'Familias' },
  { slug: 'eliminar-cuenta', label: 'Eliminar cuenta' },
]
