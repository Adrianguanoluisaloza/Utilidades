# Requires: PowerShell 7+, OpenSSH client, Maven (optional), Docker on remote
param(
  [string]$HostName = "ec2-your-ip-or-dns",
  [string]$User = "ubuntu",
  [string]$PemFile = "$HOME/.ssh/your-key.pem",
  [string]$RemotePath = "/opt/delivery-api",
  [switch]$BuildJar,
  [switch]$OnlyJar
)

$ErrorActionPreference = "Stop"

function Invoke-SSH {
  param([string]$cmd)
  & ssh -i $PemFile "$User@$HostName" $cmd
}

function Copy-Remote {
  param([string]$src, [string]$dst)
  & scp -i $PemFile -r $src "$("$($User)@$($HostName):$dst")"
}

# 1) Build fat JAR (optional)
if ($PSBoundParameters.ContainsKey('BuildJar')) {
  Write-Host "[1/4] Construyendo JAR (maven package -DskipTests)..." -ForegroundColor Cyan
  Push-Location "$PSScriptRoot/.." | Out-Null
  try {
    & mvn -f "../pom.xml" -DskipTests package
  } catch {
    Write-Warning "No se pudo ejecutar Maven. Puedes compilar manualmente o desactivar -BuildJar."
  }
  Pop-Location | Out-Null
}

$JarPath = Join-Path $PSScriptRoot "../target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar"
if (!(Test-Path $JarPath)) {
  throw "No existe el JAR esperado: $JarPath. Compila primero."
}

# 2) Crear carpeta remota
Write-Host "[2/4] Asegurando ruta remota $RemotePath..." -ForegroundColor Cyan
Invoke-SSH "sudo mkdir -p $RemotePath && sudo chown -R $($User):$($User) $RemotePath"

# 3) Copiar archivos
if ($PSBoundParameters.ContainsKey('OnlyJar')) {
  Write-Host "[3/4] Subiendo solo JAR..." -ForegroundColor Cyan
  Copy-Remote $JarPath "$RemotePath/target/"
} else {
  Write-Host "[3/4] Subiendo project delivery-api completo (sin .git y build pesados)..." -ForegroundColor Cyan
  # Sync mínimos: Dockerfile, compose, src opcionalmente, y JAR
  Copy-Remote (Join-Path $PSScriptRoot "../Dockerfile") $RemotePath
  Copy-Remote (Join-Path $PSScriptRoot "../docker-compose.yml") $RemotePath
  Invoke-SSH "mkdir -p $RemotePath/target"
  Copy-Remote $JarPath "$RemotePath/target/"
}

# 4) Levantar contenedor sin logs cloudwatch
Write-Host "[4/4] Ejecutando docker compose (sin CloudWatch logs)..." -ForegroundColor Cyan
Invoke-SSH "cd $RemotePath && docker compose down && docker compose build --no-cache && docker compose up -d && docker ps --filter name=delivery-api"

Write-Host "Listo. Verifica salud con: curl -fsS http://localhost:7070/health (en el servidor)" -ForegroundColor Green
