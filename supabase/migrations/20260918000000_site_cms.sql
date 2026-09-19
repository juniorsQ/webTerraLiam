-- Official marketing site CMS (web-oficial/).
-- Public SELECT of published pages/sections.
-- INSERT/UPDATE/DELETE: any authenticated Supabase Auth user (first admin =
-- create that user in Authentication > Users; no extra role table in v1).

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.site_pages (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.site_sections (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.site_pages (id) on delete cascade,
  key text not null,
  sort integer not null default 0,
  content jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (page_id, key)
);

create index if not exists site_sections_page_sort_idx
  on public.site_sections (page_id, sort);

drop trigger if exists site_pages_set_updated_at on public.site_pages;
create trigger site_pages_set_updated_at
  before update on public.site_pages
  for each row execute procedure public.set_updated_at();

drop trigger if exists site_sections_set_updated_at on public.site_sections;
create trigger site_sections_set_updated_at
  before update on public.site_sections
  for each row execute procedure public.set_updated_at();

alter table public.site_pages enable row level security;
alter table public.site_sections enable row level security;

drop policy if exists site_pages_select on public.site_pages;
create policy site_pages_select
  on public.site_pages
  for select
  to anon, authenticated
  using (published = true or auth.uid() is not null);

drop policy if exists site_pages_write on public.site_pages;
create policy site_pages_write
  on public.site_pages
  for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

drop policy if exists site_sections_select on public.site_sections;
create policy site_sections_select
  on public.site_sections
  for select
  to anon, authenticated
  using (
    auth.uid() is not null
    or exists (
      select 1 from public.site_pages p
      where p.id = site_sections.page_id and p.published = true
    )
  );

drop policy if exists site_sections_write on public.site_sections;
create policy site_sections_write
  on public.site_sections
  for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

grant select on table public.site_pages to anon, authenticated;
grant insert, update, delete on table public.site_pages to authenticated;
grant select on table public.site_sections to anon, authenticated;
grant insert, update, delete on table public.site_sections to authenticated;

insert into public.site_pages (slug, title, published)
values
  ('home', 'Terra Liam', true),
  ('privacidad', 'Privacidad — Terra Liam', true)
on conflict (slug) do nothing;

insert into public.site_sections (page_id, key, sort, content)
select p.id, v.key, v.sort, v.content
from public.site_pages p
join (values
  (
    'home',
    'nav',
    10,
    $json${
      "wordmarkTerra": "Terra",
      "wordmarkLiam": "Liam",
      "cta": "Descargar",
      "ctaHref": "#descargar",
      "links": [
        {"label": "Cómo funciona", "href": "#como-funciona"},
        {"label": "Para familias", "href": "#familias"},
        {"label": "Mini-juegos", "href": "#minijuegos"},
        {"label": "Seguridad", "href": "#seguridad"}
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'hero',
    20,
    $json${
      "eyebrow": "Juego familiar al aire libre",
      "h1": "Sal al mundo real a jugar",
      "sub": "Los padres esconden hallazgos. Liam y Buck te acompañan con mapa, cámara y brújula. Colecciona tarjetas, gana niveles y desbloquea sorpresas.",
      "ctaPrimary": "Descargar la app",
      "ctaPrimaryHref": "#descargar",
      "ctaSecondary": "Ver cómo funciona",
      "ctaSecondaryHref": "#como-funciona",
      "micro": "Gratis para familias · Mundos privados · Pensado para niños",
      "trust": [
        "Hecho para familias",
        "Mundos privados",
        "Sin chat abierto entre desconocidos"
      ],
      "liamAlt": "Liam, niño explorador con traje crema y mangas naranja, junto a Buck el robot de una rueda"
    }$json$::jsonb
  ),
  (
    'home',
    'how',
    30,
    $json${
      "title": "Cómo funciona",
      "subtitle": "Tres pasos para convertir el barrio en un mapa de tesoros.",
      "steps": [
        {"n": 1, "title": "Crear un mundo", "body": "El adulto arma el mapa de la familia y obtiene un código de invitación."},
        {"n": 2, "title": "Esconder hallazgos", "body": "Fotos reales del barrio se vuelven personajes, con rareza, radio y pista de rumbo."},
        {"n": 3, "title": "Salir a explorar", "body": "El niño camina, apunta con la cámara y captura. Buck va de guía."}
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'kids',
    40,
    $json${
      "title": "Para niños",
      "subtitle": "Salir, apuntar y coleccionar.",
      "items": [
        "Mapa con el pin de Liam",
        "Cámara y brújula en el encuentro",
        "Buck como robot guía",
        "Álbum de capturas",
        "Mini-juegos por rareza",
        "Niveles y puntos"
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'parents',
    50,
    $json${
      "title": "Para padres",
      "subtitle": "Tú pones las reglas del mundo.",
      "items": [
        "Código de invitación tipo KL785L",
        "El niño entra con apodo, sin correo",
        "Control de hallazgos en el mapa",
        "Aprobación de premios de video",
        "Mundos privados o públicos",
        "Ranking y reportes"
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'rarities',
    60,
    $json${
      "title": "Colección y rarezas",
      "subtitle": "Cada hallazgo suma puntos y desbloquea un mini-juego.",
      "cards": [
        {"rarity": "common", "label": "Común", "points": "10 puntos", "game": "Caza de estrellas", "body": "Una cacería corta de estrellas junto a Buck."},
        {"rarity": "rare", "label": "Raro", "points": "25 puntos", "game": "Carriles relámpago", "body": "Elige el carril correcto antes de que pase el rayo."},
        {"rarity": "epic", "label": "Épico", "points": "50 puntos", "game": "Batalla de rayos", "body": "Un duelo de rayos juguetón. Buck es compañero, no enemigo."}
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'minigames',
    70,
    $json${
      "title": "Mini-juegos",
      "subtitle": "Tres arenas cortas. Buck es compañero, no un enemigo letal.",
      "games": [
        {"title": "Caza de estrellas", "rarity": "Común", "body": "Atrapa destellos en el cielo del encuentro."},
        {"title": "Carriles relámpago", "rarity": "Raro", "body": "Corre por carriles de luz y llega al otro lado."},
        {"title": "Batalla de rayos", "rarity": "Épico", "body": "Un pulso a pulso con Buck, sin violencia ni armas."}
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'safety',
    80,
    $json${
      "title": "Seguridad familiar",
      "subtitle": "Diseñado para que el adulto mande el mundo.",
      "items": [
        "Mundos con código. El niño no usa email.",
        "Premios de video solo si el padre los activa y aprueba.",
        "La ubicación es para el juego, no un feed social público.",
        "No hay chat abierto entre desconocidos."
      ],
      "privacyCta": "Leer la política de privacidad",
      "privacyHref": "/privacidad"
    }$json$::jsonb
  ),
  (
    'home',
    'faq',
    90,
    $json${
      "title": "Preguntas frecuentes",
      "items": [
        {"q": "¿Hace falta que el niño tenga correo?", "a": "No: entra con apodo y código del mundo."},
        {"q": "¿Funciona en casa?", "a": "Sí, el padre coloca hallazgos en el radio que elija."},
        {"q": "¿Hay compras o chat con extraños?", "a": "No hay chat abierto. Son mundos familiares."},
        {"q": "¿Día y noche?", "a": "La app cambia de paleta según la hora (6h / 19h)."}
      ]
    }$json$::jsonb
  ),
  (
    'home',
    'cta',
    100,
    $json${
      "kicker": "¿Listos para explorar?",
      "title": "Descarga Terra Liam",
      "body": "Próximamente en App Store y Google Play. Crea un mundo, esconde un hallazgo y sal a caminar juntos.",
      "appStore": "App Store",
      "playStore": "Google Play",
      "badge": "Próximamente",
      "bubble": "¡Hola! Soy Buck, tu robot guía"
    }$json$::jsonb
  ),
  (
    'home',
    'footer',
    110,
    $json${
      "blurb": "Descubre el mundo a tu alrededor.",
      "privacy": "Privacidad",
      "privacyHref": "/privacidad",
      "contact": "Contacto",
      "contactHref": "mailto:hola@terraliam.app",
      "copyright": "Terra Liam"
    }$json$::jsonb
  ),
  (
    'privacidad',
    'body',
    10,
    $json${
      "title": "Privacidad",
      "intro": "Terra Liam es un juego familiar al aire libre. Esta página explica, en lenguaje claro, qué datos usa la app y para qué.",
      "paragraphs": [
        "El padre o tutor crea un mundo (privado o público) y obtiene un código de invitación. El niño entra con un apodo y ese código: no necesita correo electrónico.",
        "La ubicación se usa para jugar: mostrar el mapa, avisar cuando entras al radio de un hallazgo y orientar la brújula. No es un feed social público ni un chat entre desconocidos.",
        "Los hallazgos (fotos, título, rareza) los coloca la familia dentro de su mundo. Las capturas quedan en el álbum de ese mundo.",
        "Los premios de video con el personaje capturado son opcionales. Solo se generan si el padre activa la función y aprueba el resultado.",
        "La cuenta de padre usa correo electrónico para iniciar sesión. No hay chat abierto con personas fuera del mundo.",
        "Si tienes preguntas, escríbenos a hola@terraliam.app."
      ]
    }$json$::jsonb
  )
) as v(slug, key, sort, content)
  on p.slug = v.slug
on conflict (page_id, key) do nothing;
