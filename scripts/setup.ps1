# BWIA Smart Code Builder - Windows Setup Script
$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  BWIA Smart Code Builder - Windows Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Check-Command($Command) {
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# [1/5] Verificar e instalar prerequisitos
Write-Host "[1/5] Verificando prerequisitos..." -ForegroundColor Yellow

# Verificar Winget
if (-not (Check-Command "winget")) {
    Write-Error "ERROR: winget no está instalado. Por favor, instálalo desde la Microsoft Store o GitHub."
}

# Verificar Python
if (-not (Check-Command "python")) {
    Write-Host "  - Python no encontrado. Instalando via winget..." -ForegroundColor Gray
    winget install -e --id Python.Python.3.11 --accept-package-agreements --accept-source-agreements
    $EnvChanged = $true
} else {
    $Version = python --version
    Write-Host "  - Python: OK ($Version)" -ForegroundColor Green
}

# Verificar gcloud
if (-not (Check-Command "gcloud")) {
    Write-Host "  - Google Cloud CLI no encontrado. Instalando via winget..." -ForegroundColor Gray
    winget install -e --id Google.CloudSDK --accept-package-agreements --accept-source-agreements
    $EnvChanged = $true
} else {
    Write-Host "  - gcloud: OK" -ForegroundColor Green
}

# Recargar variables de entorno si se instaló algo
if ($EnvChanged) {
    Write-Host "  - Recargando variables de entorno del sistema..." -ForegroundColor Gray
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Forzar actualización de la tabla de comandos de PowerShell
    Get-ChildItem -Path "Env:\Path" | Out-Null 
    
    # Verificación final de binarios tras recarga
    if (-not (Check-Command "python")) {
        Write-Host "  - Aviso: Python no se detecta aún en el PATH. Intentando localizarlo manualmente..." -ForegroundColor Gray
        $PythonPath = Get-ChildItem -Path "$env:ProgramFiles\Python3*", "$env:LocalAppData\Programs\Python\Python3*" -Recurse -Include python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($PythonPath) {
            $env:Path += ";$($PythonPath.DirectoryName)"
            Write-Host "  - Python localizado en $($PythonPath.FullName). PATH actualizado temporalmente." -ForegroundColor Green
        }
    }
}

# [2/5] Configurar autenticación GCP
Write-Host ""
Write-Host "[2/5] Configurando autenticación GCP..." -ForegroundColor Yellow
Write-Host "  Se abrirá el navegador para iniciar sesión." -ForegroundColor Gray
Write-Host ""

gcloud auth login
gcloud auth application-default login

# [3/5] Configurar proyecto GCP
Write-Host ""
Write-Host "[3/5] Configurando proyecto GCP..." -ForegroundColor Yellow

$ProjectId = gcloud config get-value project 2>$null
if ([string]::IsNullOrWhiteSpace($ProjectId) -or $ProjectId -eq "(unset)") {
    Write-Host "No hay proyecto configurado." -ForegroundColor Red
    $ProjectId = Read-Host "Ingresa tu Project ID de Google Cloud"
    gcloud config set project $ProjectId
}
Write-Host "  Proyecto: $ProjectId" -ForegroundColor Green

# [4/5] Configurar entorno (.env)
Write-Host ""
Write-Host "[4/5] Creando archivo de configuración .env..." -ForegroundColor Yellow

$EnvPath = "smart_code_builder/.env"
if (Test-Path $EnvPath) {
    Write-Host "  .env ya existe, creando backup .env.bak" -ForegroundColor Gray
    Copy-Item $EnvPath "$EnvPath.bak"
}

$EnvContent = @"
GCP_PROJECT_ID=$ProjectId
GCP_LOCATION=global
MODEL_ID=gemini-2.0-flash
"@
Set-Content -Path $EnvPath -Value $EnvContent
Write-Host "  .env creado exitosamente." -ForegroundColor Green

# [5/5] Instalar dependencias de Python
Write-Host ""
Write-Host "[5/5] Instalando dependencias..." -ForegroundColor Yellow

if (-not (Test-Path ".venv")) {
    Write-Host "  - Creando entorno virtual..." -ForegroundColor Gray
    python -m venv .venv
}

Write-Host "  - Instalando requerimientos (esto puede tardar unos minutos)..." -ForegroundColor Gray
& ".\.venv\Scripts\pip.exe" install --upgrade pip
& ".\.venv\Scripts\pip.exe" install -r requirements.txt

# Habilitar APIs
Write-Host ""
Write-Host "Habilitando Vertex AI API..." -ForegroundColor Yellow
gcloud services enable aiplatform.googleapis.com

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Setup completado exitosamente!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para ejecutar la aplicación:" -ForegroundColor Gray
Write-Host ""
Write-Host "  .\.venv\Scripts\Activate.ps1"
Write-Host "  adk web smart_code_builder"
Write-Host ""
Write-Host "La app estará disponible en: http://localhost:8000" -ForegroundColor Gray
Write-Host ""
