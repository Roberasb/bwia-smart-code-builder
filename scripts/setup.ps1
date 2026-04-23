# BWIA Smart Code Builder - Workshop Setup (Windows)
$ErrorActionPreference = "Stop"

# ── Helpers ─────────────────────────────────────────────
function Write-Step($Text) {
    Write-Host ""
    Write-Host "▶ $Text" -ForegroundColor Blue
}
function Write-Ok($Text)   { Write-Host "✓ $Text" -ForegroundColor Green }
function Write-Warn($Text) { Write-Host "⚠ $Text" -ForegroundColor Yellow }
function Write-Err($Text)  { Write-Host "✗ $Text" -ForegroundColor Red }

function Test-Command($Command) {
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  BWIA Smart Code Builder - Windows Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ── [1/8] Validar directorio ────────────────────────────
Write-Step "[1/8] Validando directorio del proyecto..."

if (-not (Test-Path "smart_code_builder/agent.py") -or -not (Test-Path "requirements.in")) {
    Write-Err "Este script debe ejecutarse desde la raiz del repo bwia-smart-code-builder"
    Write-Err "Archivos esperados: smart_code_builder/agent.py, requirements.in"
    exit 1
}
Write-Ok "Directorio correcto"

# ── [2/8] Prerequisitos ─────────────────────────────────
Write-Step "[2/8] Verificando prerequisitos (python3.11+, gcloud, git)..."

$EnvChanged = $false

# Verificar Winget
if (-not (Test-Command "winget")) {
    Write-Err "winget no esta instalado. Instalalo desde la Microsoft Store."
    exit 1
}

# Python
if (-not (Test-Command "python")) {
    Write-Host "  Instalando Python 3.11 via winget..." -ForegroundColor Gray
    winget install -e --id Python.Python.3.11 --accept-package-agreements --accept-source-agreements --silent
    $EnvChanged = $true
}

# Google Cloud CLI
if (-not (Test-Command "gcloud")) {
    Write-Host "  Instalando Google Cloud CLI via winget..." -ForegroundColor Gray
    winget install -e --id Google.CloudSDK --accept-package-agreements --accept-source-agreements --silent
    $EnvChanged = $true
}

# Git
if (-not (Test-Command "git")) {
    Write-Host "  Instalando Git via winget..." -ForegroundColor Gray
    winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent
    $EnvChanged = $true
}

# Recargar PATH si se instalo algo
if ($EnvChanged) {
    Write-Host "  Recargando variables de entorno..." -ForegroundColor Gray
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Localizar Python manualmente si no aparece
    if (-not (Test-Command "python")) {
        $PythonPath = Get-ChildItem -Path "$env:ProgramFiles\Python3*", "$env:LocalAppData\Programs\Python\Python3*" -Recurse -Include python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($PythonPath) {
            $env:Path += ";$($PythonPath.DirectoryName)"
            Write-Ok "Python localizado en $($PythonPath.FullName)"
        }
    }
}

# Validar Python 3.11+
if (-not (Test-Command "python")) {
    Write-Err "Python no encontrado despues de instalacion. Cierra y abre una nueva PowerShell y vuelve a ejecutar."
    exit 1
}

$PyVersionStr = (python --version 2>&1) -replace "Python ", ""
$PyParts = $PyVersionStr.Split(".")
$PyMajor = [int]$PyParts[0]
$PyMinor = [int]$PyParts[1]

if ($PyMajor -lt 3 -or ($PyMajor -eq 3 -and $PyMinor -lt 11)) {
    Write-Err "Python 3.11+ requerido. Version actual: $PyVersionStr"
    exit 1
}

Write-Ok "python: v$PyVersionStr"
Write-Ok "gcloud: OK"
Write-Ok "git: OK"

# ── [3/8] Autenticacion GCP ─────────────────────────────
Write-Step "[3/8] Configurando autenticacion GCP..."

$CurrentAccount = gcloud config get-value account 2>$null
if ([string]::IsNullOrWhiteSpace($CurrentAccount) -or $CurrentAccount -eq "(unset)") {
    Write-Host "  Abriendo navegador para login..." -ForegroundColor Gray
    gcloud auth login
} else {
    Write-Ok "Ya autenticado como: $CurrentAccount"
}

# ADC
try {
    gcloud auth application-default print-access-token 2>$null | Out-Null
    Write-Ok "ADC ya configurado"
} catch {
    Write-Host "  Configurando Application Default Credentials..." -ForegroundColor Gray
    gcloud auth application-default login
}

# ── [4/8] Proyecto GCP ──────────────────────────────────
Write-Step "[4/8] Configurando proyecto GCP..."

$ProjectId = gcloud config get-value project 2>$null
if ([string]::IsNullOrWhiteSpace($ProjectId) -or $ProjectId -eq "(unset)") {
    $ProjectId = Read-Host "Ingresa tu Project ID de Google Cloud"
    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        Write-Err "Project ID vacio. Abortando."
        exit 1
    }
    gcloud config set project $ProjectId
}
Write-Ok "Proyecto: $ProjectId"

# Validar billing (no-bloqueante)
try {
    $BillingOutput = gcloud billing projects describe $ProjectId --format="value(billingEnabled)" 2>$null
    if ($BillingOutput -eq "True" -or $BillingOutput -eq "true") {
        Write-Ok "Billing habilitado"
    } else {
        Write-Warn "Billing NO esta habilitado en $ProjectId"
        Write-Warn "Habilitalo en: https://console.cloud.google.com/billing/linkedaccount?project=$ProjectId"
    }
} catch {
    Write-Warn "No se pudo verificar billing (puede requerir rol Billing Viewer)"
}

# ── [5/8] Dependencias Python ───────────────────────────
Write-Step "[5/8] Instalando dependencias Python..."

if (-not (Test-Path ".venv")) {
    Write-Host "  Creando entorno virtual .venv..." -ForegroundColor Gray
    python -m venv .venv
}

$VenvPip = ".\.venv\Scripts\pip.exe"
$VenvPython = ".\.venv\Scripts\python.exe"

& $VenvPip install --upgrade pip --quiet

# Regenerar requirements.txt si no existe
if (-not (Test-Path "requirements.txt")) {
    Write-Host "  requirements.txt no existe. Generando con pip-compile..." -ForegroundColor Gray
    & $VenvPip install pip-tools --quiet
    & ".\.venv\Scripts\pip-compile.exe" requirements.in -o requirements.txt --quiet
    Write-Ok "requirements.txt generado"
}

Write-Host "  Instalando dependencias (puede tardar 1-2 minutos)..." -ForegroundColor Gray
& $VenvPip install -r requirements.txt --quiet
Write-Ok "Dependencias instaladas"

# ── [6/8] Habilitar APIs GCP ────────────────────────────
Write-Step "[6/8] Habilitando APIs de GCP..."

try {
    gcloud services enable aiplatform.googleapis.com --project=$ProjectId
    Write-Ok "Vertex AI API habilitada"
} catch {
    Write-Err "No se pudo habilitar Vertex AI API"
    Write-Err "Verifica que tienes billing habilitado y permisos de Editor/Owner"
    exit 1
}

# ── [7/8] Generar .env ──────────────────────────────────
Write-Step "[7/8] Generando archivo de configuracion .env..."

$EnvPath = "smart_code_builder/.env"
if (Test-Path $EnvPath) {
    Write-Warn ".env ya existe, creando backup .env.bak"
    Copy-Item $EnvPath "$EnvPath.bak" -Force
}

$EnvContent = @"
GCP_PROJECT_ID=$ProjectId
GCP_LOCATION=global

# ── Modelos por tier (costo/capacidad) ──────────────────
# Router: clasificacion de intencion (el mas barato)
ROUTER_MODEL=gemini-2.5-flash-lite
# Fast: generacion de codigo, crawling (balance velocidad/calidad)
FAST_MODEL=gemini-2.5-flash
# Heavy: analisis profundo, auditorias, code review (mejor calidad)
HEAVY_MODEL=gemini-2.5-pro
# Fallback general
MODEL_ID=gemini-2.5-flash
"@
Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
Write-Ok ".env creado en $EnvPath"

# ── [8/8] Verificacion final ────────────────────────────
Write-Step "[8/8] Verificando instalacion..."

$VenvAdk = ".\.venv\Scripts\adk.exe"
if (-not (Test-Path $VenvAdk)) {
    Write-Err "'adk' no esta instalado en el venv."
    Write-Err "Verifica que google-adk se instalo correctamente."
    exit 1
}

$AdkVersion = & $VenvAdk --version 2>&1 | Select-Object -First 1
Write-Ok "adk: $AdkVersion"

$ImportTest = & $VenvPython -c "from smart_code_builder.agent import root_agent; print('OK')" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Ok "Import de root_agent funciona"
} else {
    Write-Err "No se pudo importar el agente:"
    Write-Err $ImportTest
    exit 1
}

# ── Final ───────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Setup completado exitosamente!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para ejecutar la aplicacion:"
Write-Host ""
Write-Host "  .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host "  adk web smart_code_builder" -ForegroundColor Yellow
Write-Host ""
Write-Host "La app estara disponible en: http://localhost:8000"
Write-Host ""
