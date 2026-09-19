-- Presentation copy between hero (20) and how (30).

insert into public.site_sections (page_id, key, sort, content)
select p.id, 'pitch', 25, $json${
  "eyebrow": "Presentación",
  "title": "Aventura Didáctica en Tiempo Real",
  "paragraphs": [
    "Aventura Didáctica en Tiempo Real es una aplicación móvil para Android que combina geolocalización, realidad aumentada e inteligencia artificial en una experiencia interactiva para niños.",
    "En este juego, los niños encarnan a Liam el Explorador y a su fiel compañero Buck, avanzando por un mapa interactivo para descubrir personajes u objetos estratégicamente situados por sus padres o creadores de mundos.",
    "Al encontrarlos, los pequeños utilizan la cámara para capturarlos al estilo Pokémon GO; la app procesa las imágenes eliminando automáticamente el fondo para integrarlas de forma limpia al entorno virtual.",
    "Además, la plataforma ofrece una función premium que transforma las capturas en cortos animados generados por IA, convirtiendo la exploración en un aprendizaje colectivo, interactivo y visualmente fascinante."
  ]
}$json$::jsonb
from public.site_pages p
where p.slug = 'home'
on conflict (page_id, key) do nothing;
