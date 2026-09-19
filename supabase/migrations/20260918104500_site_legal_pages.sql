-- Public legal pages for Google Play (privacy, terms, families, account deletion).
-- Seed copy matches web-oficial/src/data/fallback.json. Public SELECT still uses
-- the published-page policies from 20260918000000_site_cms.sql.

insert into public.site_pages (slug, title, published)
values
  ('privacidad', 'Privacidad — Terra Liam', true),
  ('terminos', 'Términos — Terra Liam', true),
  ('familias', 'Familias — Terra Liam', true),
  ('eliminar-cuenta', 'Eliminar cuenta — Terra Liam', true)
on conflict (slug) do update
set title = excluded.title,
    published = true;

insert into public.site_sections (page_id, key, sort, content)
select p.id, v.key, v.sort, v.content
from public.site_pages p
join (values
  (
    'privacidad',
    'body',
    10,
    $json${
      "title": "Política de privacidad",
      "reviewerNote": "Privacy policy for Terra Liam, a family outdoor game. The parent or guardian is the account holder.",
      "updated": "Última actualización: 18 de septiembre de 2026",
      "intro": "Terra Liam es un juego familiar al aire libre. Esta página explica, en lenguaje claro, qué datos usa la app y para qué. No es asesoría legal.",
      "statements": [],
      "steps": [],
      "blocks": [
        {
          "heading": "Quién es responsable",
          "body": "El responsable de esta app es Terra Liam (el desarrollador).\nContacto: hola@terraliam.app",
          "bullets": []
        },
        {
          "heading": "Qué datos usamos",
          "body": "Solo lo necesario para que la familia juegue:",
          "bullets": [
            "Cuenta del adulto: correo y contraseña para entrar.",
            "Niño: apodo y pertenencia al mundo familiar. En el flujo habitual el niño no usa correo.",
            "Mundo: nombre, código de invitación y quién es admin.",
            "Ubicación mientras se juega: para el mapa y los puntos de interés (hallazgos). No es un feed social público.",
            "Fotos que el adulto sube como hallazgos (POIs) y las capturas del álbum de ese mundo.",
            "Premios de video con IA, solo si el adulto activa y aprueba esa función."
          ]
        },
        {
          "heading": "Permisos del teléfono (Android)",
          "body": "La app pide permisos porque el juego pasa en el mundo real. Si los niegas, esa parte no funciona.",
          "bullets": [
            "Ubicación precisa y aproximada: mostrar el mapa, el radio de un hallazgo y jugar cerca de casa o del barrio.",
            "Cámara: apuntar y capturar encuentros. No es una red pública de cámaras.",
            "Notificaciones: avisos del juego (por ejemplo, un premio listo). Son opcionales.",
            "Internet: cuenta, mundo, mapa y sincronizar la partida.",
            "Brújula: usa el sensor del teléfono; no pide un permiso extra de Android."
          ]
        },
        {
          "heading": "Niños",
          "body": "No ofrecemos una red social abierta para niños. El adulto crea el espacio e invita con un código. El niño entra con apodo; no publica un perfil abierto a extraños.\nNo hay publicidad de terceros dirigida a niños.\nNo vendemos datos de niños.",
          "bullets": []
        },
        {
          "heading": "Dónde se guardan",
          "body": "Usamos Supabase para alojar autenticación, base de datos y archivos. Ellos procesan esos datos para que el juego funcione. No afirmamos que sean un socio publicitario ni un analista de terceros para anuncios.",
          "bullets": []
        },
        {
          "heading": "Cuánto tiempo y cómo borrar",
          "body": "En la app, el adulto puede cerrar sesión en Perfil → Cerrar sesión. Eso no borra la cuenta.\nHoy no hay un botón de autoborrado. Para eliminar la cuenta del padre y los datos de la familia que conservemos, el adulto escribe a hola@terraliam.app (ver también /eliminar-cuenta). Al borrar esa cuenta, quitamos el mundo familiar asociado que tengamos almacenado.",
          "bullets": []
        },
        {
          "heading": "Preguntas",
          "body": "Escríbenos a hola@terraliam.app.",
          "bullets": []
        }
      ],
      "related": [
        {"label": "Términos", "href": "/terminos"},
        {"label": "Familias", "href": "/familias"},
        {"label": "Eliminar cuenta", "href": "/eliminar-cuenta"}
      ]
    }$json$::jsonb
  ),
  (
    'terminos',
    'body',
    10,
    $json${
      "title": "Términos de uso",
      "reviewerNote": "Terms of use. The adult parent/guardian is the account holder and is legally responsible; children play only under that adult's supervision.",
      "updated": "Última actualización: 18 de septiembre de 2026",
      "intro": "Al usar Terra Liam aceptas estas reglas prácticas. La app es un juego para familias, no una niñera ni una red social abierta.",
      "statements": [],
      "steps": [],
      "blocks": [
        {
          "heading": "Para quién es",
          "body": "Terra Liam es para familias. El adulto (padre, madre o tutor) es el titular de la cuenta y el responsable legal del uso que haga el niño.\nEl niño solo debe usar la app bajo supervisión directa de ese adulto.",
          "bullets": []
        },
        {
          "heading": "El adulto está a cargo",
          "body": "El padre, madre o tutor siempre debe estar a cargo. El adulto supervisa al niño. El adulto es el responsable.\nNo uses Terra Liam como niñera, ni para que alguien que no es el tutor vigile o rastree a un menor sin supervisión.",
          "bullets": []
        },
        {
          "heading": "Juego al aire libre",
          "body": "Salir a la calle implica tráfico, desconocidos y riesgos físicos. El adulto decide cuándo, dónde y con quién se juega. La app no sustituye el cuidado de una persona.",
          "bullets": []
        },
        {
          "heading": "Ubicación y cámara",
          "body": "La ubicación y la cámara son para el juego (mapa, hallazgos y capturas). No para un feed público ni para una red de cámaras.",
          "bullets": []
        },
        {
          "heading": "Uso no permitido",
          "body": "No está permitido:",
          "bullets": [
            "Acosar, molestar o humillar a otras personas.",
            "Colocar hallazgos (fotos o textos) inapropiados para niños.",
            "Usar la cuenta de otra persona.",
            "Usar la app para rastrear a un menor si no eres su padre, madre o tutor."
          ]
        },
        {
          "heading": "Premios de video con IA",
          "body": "Son opcionales. Solo se generan si el adulto activa la función y aprueba el premio. Si esa opción está apagada, el juego sigue sin ella.",
          "bullets": []
        },
        {
          "heading": "Tiendas y pagos",
          "body": "Los botones de App Store y Google Play son marcadores de descarga. Hoy Terra Liam no tiene compras dentro de la app. Cuando publiques en una tienda, también aplican las reglas de esa tienda.",
          "bullets": []
        },
        {
          "heading": "Contacto",
          "body": "hola@terraliam.app",
          "bullets": []
        }
      ],
      "related": [
        {"label": "Privacidad", "href": "/privacidad"},
        {"label": "Familias", "href": "/familias"}
      ]
    }$json$::jsonb
  ),
  (
    'familias',
    'body',
    10,
    $json${
      "title": "Familias y responsabilidad",
      "reviewerNote": "",
      "updated": "Para revisores de Play: el adulto siempre está a cargo.",
      "intro": "Terra Liam está pensado para que una familia juegue junta. No es una app social general para niños.",
      "statements": [
        "El padre, madre o tutor **siempre** debe estar a cargo.",
        "El adulto **supervisa** al niño.",
        "El adulto **es el responsable**."
      ],
      "steps": [],
      "blocks": [
        {
          "heading": "Cómo lo apoya la app",
          "body": "La app no reemplaza al adulto. Sí deja claro quién manda el mundo:",
          "bullets": [
            "El padre crea la cuenta y el mundo familiar.",
            "Invita al niño con un código, no con un perfil público abierto.",
            "El niño entra con apodo (en el flujo habitual, sin correo).",
            "No hay chat abierto con desconocidos.",
            "La ubicación y la cámara son para jugar, no para un feed social.",
            "Los premios de video con IA solo existen si el padre los activa y aprueba."
          ]
        },
        {
          "heading": "Diseñado para familias",
          "body": "Un mundo de Terra Liam es el espacio que arma el adulto. Aunque un padre pueda marcar un mundo como visible para otras familias, no es una red social abierta para niños ni un chat con extraños. El adulto sigue siendo quien invita, supervisa y responde.",
          "bullets": []
        }
      ],
      "related": [
        {"label": "Privacidad", "href": "/privacidad"},
        {"label": "Términos", "href": "/terminos"}
      ]
    }$json$::jsonb
  ),
  (
    'eliminar-cuenta',
    'body',
    10,
    $json${
      "title": "Eliminar cuenta y datos",
      "reviewerNote": "",
      "updated": "Última actualización: 18 de septiembre de 2026",
      "intro": "Hoy no hay un botón de autoborrado en la app. El adulto pide el borrado por correo. Cerrar sesión no elimina la cuenta.",
      "statements": [],
      "steps": [
        {
          "n": "1",
          "title": "Entra como padre o tutor",
          "body": "Abre Terra Liam e inicia sesión con el correo de la cuenta de adulto."
        },
        {
          "n": "2",
          "title": "Si solo quieres salir",
          "body": "En Perfil elige Cerrar sesión. Eso cierra el acceso en ese teléfono; no borra el mundo ni los datos."
        },
        {
          "n": "3",
          "title": "Pide el borrado por correo",
          "body": "Escribe a hola@terraliam.app desde el mismo correo de la cuenta. Indica que quieres eliminar la cuenta de Terra Liam y los datos de la familia."
        },
        {
          "n": "4",
          "title": "Confirmación",
          "body": "Cuando borremos la cuenta del padre, quitaremos el mundo familiar y los datos asociados que conservemos. Te confirmaremos por correo."
        }
      ],
      "blocks": [
        {
          "heading": "Qué se borra",
          "body": "La cuenta del adulto, el mundo de la familia, apodos de los niños de ese mundo, hallazgos y capturas que tengamos guardados. El niño no administra la cuenta: el adulto es quien pide el borrado.",
          "bullets": []
        },
        {
          "heading": "Contacto",
          "body": "hola@terraliam.app",
          "bullets": []
        }
      ],
      "related": [
        {"label": "Privacidad", "href": "/privacidad"}
      ]
    }$json$::jsonb
  )
) as v(slug, key, sort, content)
  on p.slug = v.slug
on conflict (page_id, key) do update
set content = excluded.content,
    sort = excluded.sort;

update public.site_sections s
set content = jsonb_set(
  coalesce(s.content, '{}'::jsonb),
  '{legalLinks}',
  $json$[
    {"label": "Privacidad", "href": "/privacidad"},
    {"label": "Términos", "href": "/terminos"},
    {"label": "Familias", "href": "/familias"},
    {"label": "Eliminar cuenta", "href": "/eliminar-cuenta"}
  ]$json$::jsonb
)
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'nav';

update public.site_sections s
set content = s.content
  || jsonb_build_object(
    'supervision',
    'El padre, madre o tutor siempre supervisa al niño y es el responsable.'
  )
  || jsonb_build_object(
    'trust',
    $json$[
      "Hecho para familias",
      "Mundos privados",
      "Sin chat abierto entre desconocidos",
      "El adulto está a cargo"
    ]$json$::jsonb
  )
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'hero';

update public.site_sections s
set content = s.content || $json${
  "items": [
    "El padre, madre o tutor siempre está a cargo: supervisa el juego y es el responsable.",
    "Mundos con código. El niño no usa email.",
    "Premios de video solo si el padre los activa y aprueba.",
    "La ubicación es para el juego, no un feed social público.",
    "No hay chat abierto entre desconocidos."
  ],
  "familyCta": "Responsabilidad de las familias",
  "familyHref": "/familias"
}$json$::jsonb
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'safety';

update public.site_sections s
set content = s.content || $json${
  "links": [
    {"label": "Privacidad", "href": "/privacidad"},
    {"label": "Términos", "href": "/terminos"},
    {"label": "Familias", "href": "/familias"},
    {"label": "Eliminar cuenta", "href": "/eliminar-cuenta"}
  ]
}$json$::jsonb
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'footer';

update public.site_sections s
set content = jsonb_set(
  s.content,
  '{items}',
  $json$[
    "Código de invitación tipo KL785L",
    "El niño entra con apodo, sin correo",
    "Control de hallazgos en el mapa",
    "Aprobación de premios de video",
    "Mundo familiar con código de invitación",
    "Ranking y reportes"
  ]$json$::jsonb
)
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'parents';

update public.site_sections s
set content = jsonb_set(
  s.content,
  '{items}',
  $json$[
    {"q": "¿Hace falta que el niño tenga correo?", "a": "No: entra con apodo y código del mundo."},
    {"q": "¿Funciona en casa?", "a": "Sí, el padre coloca hallazgos en el radio que elija."},
    {"q": "¿Hay compras o chat con extraños?", "a": "No hay chat abierto ni compras dentro de la app. Son mundos familiares."},
    {"q": "¿Quién es el responsable?", "a": "El padre, madre o tutor. El adulto crea el mundo, invita al niño y debe supervisar el juego."},
    {"q": "¿Día y noche?", "a": "La app cambia de paleta según la hora (6h / 19h)."}
  ]$json$::jsonb
)
from public.site_pages p
where s.page_id = p.id and p.slug = 'home' and s.key = 'faq';
