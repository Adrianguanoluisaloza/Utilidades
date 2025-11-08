param(
  [Parameter(Mandatory=$true)][string]$HostName,
  [Parameter(Mandatory=$true)][string]$User,
  [Parameter(Mandatory=$true)][string]$PemFile,
  [Parameter(Mandatory=$true)][string]$RemotePath,
  [Parameter(Mandatory=$true)][string]$DbUrl,
  [Parameter(Mandatory=$true)][string]$DbUser,
  [Parameter(Mandatory=$true)][SecureString]$DbPassword
)

$ErrorActionPreference = "Stop"

# 1) Construir un .env.new temporal local con solo DB_* y preservar otras variables remotas
$tempEnv = New-TemporaryFile
@(
  "# .env (actualizado para RDS)",
  "DB_URL=$DbUrl",
  "DB_USER=$DbUser",
  "DB_PASSWORD=$( [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DbPassword)) )",
  "",
  "# Pool (opcional)",
  "DB_POOL_SIZE=10",
  "DB_MIN_IDLE=2",
  "DB_CONN_TIMEOUT_MS=10000",
  "DB_IDLE_TIMEOUT_MS=600000",
  "DB_MAX_LIFETIME_MS=1800000"
) | Set-Content -Path $tempEnv -Encoding UTF8

Write-Host "Subiendo .env.new a $RemotePath..." -ForegroundColor Cyan
& scp -i $PemFile $tempEnv.FullName "$("$($User)@$($HostName):$RemotePath/.env.new")"

Write-Host "Haciendo backup de .env remoto y reemplazando..." -ForegroundColor Cyan
$remoteCmd = @"
set -e
cd $RemotePath
if [ -f .env ]; then cp .env ".env.bak-$(/usr/bin/date +%Y%m%d%H%M%S)"; fi
# Combinar: mantener líneas existentes que no sean DB_* y agregar/actualizar DB_*
if [ -f .env ]; then
  grep -v '^DB_' .env > .env.rest || true
else
  touch .env.rest
fi
cat .env.new >> .env.rest
mv .env.rest .env
rm -f .env.new
"@

& ssh -i $PemFile "$User@$HostName" $remoteCmd

Write-Host "Listo. .env actualizado. Reinicia el contenedor para aplicar cambios." -ForegroundColor Green
