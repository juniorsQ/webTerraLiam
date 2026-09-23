# Web oficial — Terra Liam

Landing de marketing en **Vue 3 + Vite** con un CMS en **PostgreSQL** (el mismo proyecto Supabase que usa la app Flutter).

No es el `web/` de Flutter. Esta app vive en `web-oficial/`.

## Cómo correrla en local

```bash
cd web-oficial
cp .env.example .env.local
npm install
npm run dev
```

Abre `http://localhost:5173`.

Sin `VITE_SUPABASE_ANON_KEY` el sitio **igual se ve**: carga el copy de `src/data/fallback.json`. El admin (`/admin`) sí necesita Supabase.

Build de producción:

```bash
npm run build
npm run preview
```

## Variables de entorno

Copia `.env.example` → `.env.local` (no lo subas a git):

```
VITE_SUPABASE_URL=https://ahlnxgtglibdbcialzbo.supabase.co
VITE_SUPABASE_ANON_KEY=
```

Pega **solo** la anon / publishable key del proyecto. Nunca `service_role`.

## CMS (Postgres)

Migraciones:

- `supabase/migrations/20260918000000_site_cms.sql` — tablas y seed de la home
- `supabase/migrations/20260918104500_site_legal_pages.sql` — Privacidad, Términos, Familias, Eliminar cuenta

Tablas:

| Tabla | Qué guarda |
| --- | --- |
| `site_pages` | `slug`, `title`, `published` (`home`, `privacidad`, `terminos`, `familias`, `eliminar-cuenta`) |
| `site_sections` | `page_id`, `key` único por página. Home: `nav`, `hero`, `how`, `kids`, `parents`, `rarities`, `minigames`, `safety`, `faq`, `cta`, `footer`. Legales: `body` (JSONB) |

La landing pública hace `SELECT` de la página `home` publicada y arma cada bloque Vue desde `content`. Las páginas legales cargan `body`. Si falta env o falla la red, usa el JSON local (`src/data/fallback.json`).

### RLS

- Anon: solo páginas **publicadas** y sus secciones.
- Authenticated: leer / crear / editar / borrar (el CMS). Un `UPDATE` también necesita poder `SELECT` la fila; por eso el admin autenticado ve todas las secciones, no solo las publicadas.

No hay tabla de roles extra. **El primer admin es un usuario de Supabase Auth** (email + contraseña).

## Aplicar las migraciones

Desde el SQL Editor del dashboard de Supabase, ejecuta en orden:

1. `supabase/migrations/20260918000000_site_cms.sql`
2. `supabase/migrations/20260918104500_site_legal_pages.sql`

O con la CLI del repo:

```bash
supabase db push
```

### Mantener el esquema y crear respaldo

Las migraciones en `supabase/migrations/` son la fuente de verdad del esquema. No edites una migracion que ya se haya aplicado; crea otra con un timestamp posterior. Antes de aplicar cambios en una base compartida:

1. Ejecuta `scripts/backup-supabase.ps1` desde PowerShell. Genera un respaldo separado del esquema y los datos del esquema `public` en `backups/`.
2. El script requiere `pg_dump` (PostgreSQL Client Tools) y solicita la contrasena directamente en la terminal. No guardes contrasenas, `service_role` keys ni URLs con credenciales en el repositorio.
3. Revisa el SQL y aplica las migraciones en orden con `supabase db push` o desde el SQL Editor.
4. Ejecuta el build y verifica las tablas y funciones nuevas en Supabase.

La migracion `20260922000000_platform_ops_video_security.sql` fue aplicada manualmente en el proyecto Supabase `terra_liam` y su version `20260922000000` quedo registrada en `supabase_migrations.schema_migrations`. No la vuelvas a ejecutar manualmente.

Ejemplo:

```powershell
.\scripts\backup-supabase.ps1
```

El respaldo es local y debe quedar fuera de Git. La copia administrada de Supabase requiere un plan que incluya backups.

El seed trae el copy en español LATAM de la landing y las páginas legales (Google Play). El correo de contacto es un placeholder (`hola@terraliam.app`): cámbialo en el CMS.

## Crear el usuario admin

1. Supabase → Authentication → Users → Add user (email + password).
2. Entra a `http://localhost:5173/admin`.
3. Edita una sección o una página legal y usa **Vista previa**.

Cualquier usuario autenticado puede editar el CMS en v1. No compartas esa cuenta.

## Rutas

- `/` landing con anclas
- `/privacidad` política de privacidad
- `/terminos` términos de uso
- `/familias` responsabilidad parental (lectura de 60 segundos)
- `/eliminar-cuenta` cómo pedir el borrado de la cuenta
- `/recuperar` recuperar / cambiar contraseña (Supabase Auth recovery)
- `/admin/login`
- `/admin` lista de secciones de la home + páginas legales
- `/admin/secciones/:sectionKey` editor de la home
- `/admin/paginas/:slug` editor de una página legal

## Recuperar contraseña (Vercel + Supabase)

El flujo vive en `/recuperar`:

1. El adulto pide el enlace con su correo.
2. Supabase envía el email con `redirectTo = https://TU-DOMINIO/recuperar`.
3. Al abrir el enlace, la misma página pide la contraseña nueva.

En Supabase → **Authentication** → **URL Configuration**:

| Campo | Valor |
| --- | --- |
| **Site URL** | `https://terraliam.vercel.app` (o tu dominio custom) |
| **Redirect URLs** | `https://terraliam.vercel.app/recuperar`, `http://localhost:5173/recuperar`, `terraliam://reset-password`, `terraliam://login` |

Quita `http://localhost:3000` si no lo usas. Sin esas URLs allowlisted, el link del correo falla o cae en un host vacío.

`vercel.json` reescribe todas las rutas a `index.html` para que `/recuperar` no dé 404 al refrescar.

Desde la app Flutter, el login de adulto envía el correo con `redirectTo = terraliam://reset-password` (scheme registrado en Android/iOS). Tras guardar la clave nueva, la app va al lobby. Si cambias la contraseña en esta web, el botón **Abrir Terra Liam** abre `terraliam://login`.

## Google Play Console

Cuando el sitio esté en producción (ejemplo: `https://terraliam.app`), pega estas URLs:

| Campo en Play Console | URL |
| --- | --- |
| Política de privacidad | `https://terraliam.app/privacidad` |
| Términos de uso (si pide URL) | `https://terraliam.app/terminos` |
| Familias / responsabilidad parental | `https://terraliam.app/familias` |
| Eliminar cuenta (Account deletion) | `https://terraliam.app/eliminar-cuenta` |

Sustituye el dominio por el que realmente publiques. El adulto es el titular de la cuenta y el responsable; el niño juega bajo su supervisión. Hoy no hay compras in-app ni un portal de autoborrado: el borrado se pide por correo.

## Marca

Imágenes en `public/brand/` (icono Liam+Buck, Buck SVG/PNG). Paleta y UI kit: `src/styles/tokens.css`, alineados con `lib/config/theme.dart`.
