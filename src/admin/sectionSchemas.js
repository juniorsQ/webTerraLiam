export const SECTION_META = [
  { key: 'nav', label: 'Navegación' },
  { key: 'hero', label: 'Hero' },
  { key: 'how', label: 'Cómo funciona' },
  { key: 'kids', label: 'Para niños' },
  { key: 'parents', label: 'Para padres' },
  { key: 'rarities', label: 'Rarezas' },
  { key: 'minigames', label: 'Mini-juegos' },
  { key: 'safety', label: 'Seguridad' },
  { key: 'faq', label: 'FAQ' },
  { key: 'cta', label: 'CTA noche / tiendas' },
  { key: 'footer', label: 'Pie' },
]

export function labelFor(key) {
  return SECTION_META.find((item) => item.key === key)?.label ?? key
}

function text(key, label) {
  return { key, label, type: 'text' }
}

function area(key, label) {
  return { key, label, type: 'textarea' }
}

function lines(key, label) {
  return { key, label, type: 'lines' }
}

export const SECTION_FIELDS = {
  nav: [
    text('wordmarkTerra', 'Wordmark (Terra)'),
    text('wordmarkLiam', 'Wordmark (Liam)'),
    text('cta', 'Texto del CTA'),
    text('ctaHref', 'Enlace del CTA'),
    {
      key: 'links',
      label: 'Enlaces',
      type: 'objects',
      itemLabel: 'Enlace',
      fields: [text('label', 'Texto'), text('href', 'Ancla o ruta')],
    },
    {
      key: 'legalLinks',
      label: 'Enlaces legales',
      type: 'objects',
      itemLabel: 'Enlace legal',
      fields: [text('label', 'Texto'), text('href', 'Ruta')],
    },
  ],
  hero: [
    text('eyebrow', 'Eyebrow'),
    text('h1', 'Título'),
    area('sub', 'Subtítulo'),
    text('ctaPrimary', 'CTA lima'),
    text('ctaPrimaryHref', 'Enlace CTA lima'),
    text('ctaSecondary', 'CTA outline'),
    text('ctaSecondaryHref', 'Enlace CTA outline'),
    text('micro', 'Microcopy'),
    text('supervision', 'Línea de supervisión (adulto a cargo)'),
    lines('trust', 'Fila de confianza (una por línea)'),
    text('liamAlt', 'Texto alternativo de Liam + Buck'),
  ],
  how: [
    text('title', 'Título'),
    area('subtitle', 'Subtítulo'),
    {
      key: 'steps',
      label: 'Pasos',
      type: 'objects',
      itemLabel: 'Paso',
      fields: [text('n', 'Número'), text('title', 'Título'), area('body', 'Texto')],
    },
  ],
  kids: [
    text('title', 'Título'),
    text('subtitle', 'Subtítulo'),
    lines('items', 'Lista (una por línea)'),
  ],
  parents: [
    text('title', 'Título'),
    text('subtitle', 'Subtítulo'),
    lines('items', 'Lista (una por línea)'),
  ],
  rarities: [
    text('title', 'Título'),
    area('subtitle', 'Subtítulo'),
    {
      key: 'cards',
      label: 'Rarezas',
      type: 'objects',
      itemLabel: 'Card',
      fields: [
        text('rarity', 'Clave (common / rare / epic)'),
        text('label', 'Etiqueta'),
        text('points', 'Puntos'),
        text('game', 'Mini-juego'),
        area('body', 'Texto'),
      ],
    },
  ],
  minigames: [
    text('title', 'Título'),
    area('subtitle', 'Subtítulo'),
    {
      key: 'games',
      label: 'Juegos',
      type: 'objects',
      itemLabel: 'Juego',
      fields: [text('title', 'Título'), text('rarity', 'Rareza'), area('body', 'Texto')],
    },
  ],
  safety: [
    text('title', 'Título'),
    area('subtitle', 'Subtítulo'),
    lines('items', 'Puntos (una por línea)'),
    text('privacyCta', 'Texto del enlace de privacidad'),
    text('privacyHref', 'Ruta de privacidad'),
    text('familyCta', 'Texto del enlace de familias'),
    text('familyHref', 'Ruta de familias'),
  ],
  faq: [
    text('title', 'Título'),
    {
      key: 'items',
      label: 'Preguntas',
      type: 'objects',
      itemLabel: 'Pregunta',
      fields: [text('q', 'Pregunta'), area('a', 'Respuesta')],
    },
  ],
  cta: [
    text('kicker', 'Kicker'),
    text('title', 'Título'),
    area('body', 'Texto'),
    text('appStore', 'App Store'),
    text('playStore', 'Google Play'),
    text('badge', 'Badge'),
    text('bubble', 'Burbuja de Buck'),
  ],
  footer: [
    text('blurb', 'Tagline'),
    {
      key: 'links',
      label: 'Enlaces legales',
      type: 'objects',
      itemLabel: 'Enlace',
      fields: [text('label', 'Texto'), text('href', 'Ruta')],
    },
    text('contact', 'Texto contacto'),
    text('contactHref', 'Enlace contacto'),
    text('copyright', 'Nombre de copyright'),
  ],
}

export const LEGAL_FIELDS = [
  text('title', 'Título'),
  text('reviewerNote', 'Nota en inglés (revisores Play, opcional)'),
  text('updated', 'Fecha / kicker'),
  area('intro', 'Introducción'),
  lines('statements', 'Frases destacadas (usa **negrita**)'),
  {
    key: 'steps',
    label: 'Pasos numerados',
    type: 'objects',
    itemLabel: 'Paso',
    fields: [text('n', 'Número'), text('title', 'Título'), area('body', 'Texto')],
  },
  {
    key: 'blocks',
    label: 'Bloques',
    type: 'objects',
    itemLabel: 'Bloque',
    fields: [
      text('heading', 'Encabezado'),
      area('body', 'Párrafos (un salto de línea = párrafo)'),
      area('bullets', 'Viñetas (una por línea)'),
    ],
  },
  {
    key: 'related',
    label: 'Enlaces relacionados',
    type: 'objects',
    itemLabel: 'Enlace',
    fields: [text('label', 'Texto'), text('href', 'Ruta')],
  },
]
