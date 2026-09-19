# Video de intro

Coloca aquí el video del home a pantalla completa:

- `intro.mp4` — H.264 / AAC, recomendado 1920×1080, 8–15 s, en loop y **sin audio** (se reproduce en silencio).
- `intro-poster.jpg` — primer fotograma, para móviles y conexiones lentas.

Luego apunta las rutas en el CMS (`/admin` → **Intro en video**) o en
`src/data/fallback.json` → `intro.videoSrc` / `intro.poster`.

Mientras no exista `intro.mp4`, la sección muestra el fondo de noche de la marca.
Mantén el archivo por debajo de ~8 MB para que el home cargue rápido.
