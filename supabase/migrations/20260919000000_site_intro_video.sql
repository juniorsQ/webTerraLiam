-- Fullscreen video intro above the hero on the home page.
-- sort 15 keeps it between nav (10) and hero (20).

insert into public.site_sections (page_id, key, sort, content)
select p.id, 'intro', 15, $json${
  "badge": "Incoming",
  "title": "Terra Liam está por llegar",
  "sub": "Un juego familiar al aire libre con Liam y Buck. Mira el avance y baja para descubrir cómo funciona.",
  "scrollLabel": "Baja para ver más",
  "videoSrc": "/video/intro.mp4",
  "poster": ""
}$json$::jsonb
from public.site_pages p
where p.slug = 'home'
on conflict (page_id, key) do nothing;
