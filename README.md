# Terra Liam — web oficial

Landing de marketing en **Vue 3 + Vite**. El CMS usa el mismo proyecto Supabase que la app Flutter.

Este repositorio es solo el sitio (raíz = `package.json`). No incluye la app Flutter.

## Local

```bash
npm install
cp .env.example .env.local
npm run dev
```

Abre http://localhost:5173

Sin `VITE_SUPABASE_ANON_KEY` el sitio igual se ve (`src/data/fallback.json`). El admin (`/admin`) sí necesita Supabase.

```bash
npm run build
npm run preview
```

## Vercel

1. **Import** este repo (`webTerraLiam`). Deja **Root Directory** vacío.
2. Framework Preset: **Vite** (build `npm run build`, output `dist`).
3. Variables de entorno:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY` (anon / publishable. Nunca `service_role`)

`vercel.json` reescribe todas las rutas a `/index.html` para que `/privacidad`, `/terminos`, `/familias`, `/eliminar-cuenta` y `/admin` funcionen al recargar.

## URLs legales (Play Console)

Sustituye el dominio por el de Vercel:

| Campo | URL |
| --- | --- |
| Política de privacidad | `https://<dominio>/privacidad` |
| Términos de uso | `https://<dominio>/terminos` |
| Familias | `https://<dominio>/familias` |
| Eliminar cuenta | `https://<dominio>/eliminar-cuenta` |

## CMS (Postgres)

Copia de las migraciones en `supabase/migrations/`. Aplícalas en el SQL Editor de Supabase (mismo proyecto que Flutter) si aún no están:

1. `supabase/migrations/20260918000000_site_cms.sql`
2. `supabase/migrations/20260918104500_site_legal_pages.sql`

El primer admin es un usuario de **Supabase Auth** (Authentication → Users).
