param(
  [string]$OutputDirectory = "backups"
)

$pgDump = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $pgDump) {
  throw "No se encontró pg_dump. Instala PostgreSQL Client Tools y vuelve a ejecutar este script."
}

$defaultHost = "db.ahlnxgtglibdbcialzbo.supabase.co"
$hostName = Read-Host "Host de Supabase [$defaultHost]"
if ([string]::IsNullOrWhiteSpace($hostName)) { $hostName = $defaultHost }

$userName = Read-Host "Usuario de base de datos [postgres]"
if ([string]::IsNullOrWhiteSpace($userName)) { $userName = "postgres" }

$databaseName = Read-Host "Base de datos [postgres]"
if ([string]::IsNullOrWhiteSpace($databaseName)) { $databaseName = "postgres" }

$port = Read-Host "Puerto [5432]"
if ([string]::IsNullOrWhiteSpace($port)) { $port = "5432" }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$schemaFile = Join-Path $OutputDirectory "supabase-public-schema-$stamp.sql"
$dataFile = Join-Path $OutputDirectory "supabase-public-data-$stamp.sql"

$commonArgs = @(
  "--host", $hostName,
  "--port", $port,
  "--username", $userName,
  "--dbname", $databaseName,
  "--schema=public",
  "--no-owner",
  "--no-privileges",
  "--no-comments",
  "--format=plain"
)

Write-Host "Creando respaldo del esquema public en $schemaFile"
& $pgDump.Source @commonArgs "--schema-only" "--file=$schemaFile"
if ($LASTEXITCODE -ne 0) { throw "Falló el respaldo del esquema." }

Write-Host "Creando respaldo de datos public en $dataFile"
& $pgDump.Source @commonArgs "--data-only" "--file=$dataFile"
if ($LASTEXITCODE -ne 0) { throw "Falló el respaldo de datos." }

Write-Host "Respaldo terminado:"
Write-Host "  $schemaFile"
Write-Host "  $dataFile"
