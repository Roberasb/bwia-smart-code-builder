#!/bin/bash
# BWIA Smart Code Builder - Workshop Setup (macOS + Linux)
set -euo pipefail

# ── Colores ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}$*${NC}"; }
log_ok()      { echo -e "${GREEN}✓${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
log_err()     { echo -e "${RED}✗${NC} $*" >&2; }
log_step()    { echo; echo -e "${BLUE}▶ $*${NC}"; }

echo "============================================"
echo "  BWIA Smart Code Builder - Workshop Setup"
echo "============================================"

# ── [1/8] Validar que estamos en la raiz del repo ──────
log_step "[1/8] Validando directorio del proyecto..."

if [ ! -f "smart_code_builder/agent.py" ] || [ ! -f "requirements.in" ]; then
    log_err "Este script debe ejecutarse desde la raiz del repo bwia-smart-code-builder"
    log_err "Archivos esperados: smart_code_builder/agent.py, requirements.in"
    exit 1
fi
log_ok "Directorio correcto"

# ── [2/8] Prerequisitos ─────────────────────────────────
log_step "[2/8] Verificando prerequisitos (python3.11+, gcloud, git)..."

OS="$(uname -s)"

# Funciones de instalacion por OS
install_prereqs_macos() {
    if ! command -v brew &>/dev/null; then
        log_err "Homebrew no esta instalado. Instalalo desde https://brew.sh/ y vuelve a ejecutar."
        exit 1
    fi
    if ! command -v python3 &>/dev/null; then
        log_info "Instalando Python via Homebrew..."
        brew install python@3.11
    fi
    if ! command -v gcloud &>/dev/null; then
        log_info "Instalando Google Cloud CLI..."
        brew install --cask google-cloud-sdk
    fi
    if ! command -v git &>/dev/null; then
        log_info "Instalando git..."
        brew install git
    fi
}

install_prereqs_debian() {
    sudo apt-get update -qq
    sudo apt-get install -y apt-transport-https ca-certificates gnupg curl git
    if ! command -v python3 &>/dev/null; then
        sudo apt-get install -y python3 python3-venv python3-pip
    fi
    if ! command -v gcloud &>/dev/null; then
        log_info "Instalando Google Cloud CLI..."
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y google-cloud-cli
    fi
    hash -r
}

install_prereqs_rhel() {
    if ! command -v python3 &>/dev/null; then
        sudo dnf install -y python3 python3-pip
    fi
    if ! command -v git &>/dev/null; then
        sudo dnf install -y git
    fi
    if ! command -v gcloud &>/dev/null; then
        log_info "Instalando Google Cloud CLI..."
        sudo tee /etc/yum.repos.d/google-cloud-sdk.repo > /dev/null <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        sudo dnf install -y google-cloud-cli
    fi
    hash -r
}

install_prereqs_arch() {
    sudo pacman -Sy --noconfirm
    if ! command -v python3 &>/dev/null; then
        sudo pacman -S --noconfirm python python-pip
    fi
    if ! command -v git &>/dev/null; then
        sudo pacman -S --noconfirm git
    fi
    if ! command -v gcloud &>/dev/null; then
        log_warn "Google Cloud CLI no esta en pacman oficial."
        log_warn "Instalalo desde AUR (google-cloud-cli) o manualmente:"
        log_warn "  https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    hash -r
}

case "$OS" in
    Darwin)
        log_info "Sistema: macOS"
        install_prereqs_macos
        ;;
    Linux)
        if command -v apt-get &>/dev/null; then
            log_info "Sistema: Linux (Debian/Ubuntu)"
            install_prereqs_debian
        elif command -v dnf &>/dev/null; then
            log_info "Sistema: Linux (RHEL/Fedora)"
            install_prereqs_rhel
        elif command -v pacman &>/dev/null; then
            log_info "Sistema: Linux (Arch)"
            install_prereqs_arch
        else
            log_err "Distribucion Linux no soportada automaticamente."
            log_err "Instala manualmente: python3.11+, gcloud CLI, git"
            exit 1
        fi
        ;;
    *)
        log_err "Sistema operativo no soportado: $OS"
        log_err "Este script soporta macOS y Linux. Para Windows usa scripts/setup.ps1"
        exit 1
        ;;
esac

# Validar Python 3.11+
if ! command -v python3 &>/dev/null; then
    log_err "python3 no encontrado despues de instalacion"
    exit 1
fi

PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 11 ]; }; then
    log_err "Python 3.11+ requerido. Version actual: ${PY_MAJOR}.${PY_MINOR}"
    log_err "Instala Python 3.11 o superior y vuelve a ejecutar."
    exit 1
fi

log_ok "python3: v${PY_MAJOR}.${PY_MINOR}"
log_ok "gcloud: $(gcloud --version | head -1)"
log_ok "git: $(git --version)"

# ── [3/8] Autenticacion GCP ─────────────────────────────
log_step "[3/8] Configurando autenticacion GCP..."

CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)
if [ -z "${CURRENT_ACCOUNT:-}" ] || [ "$CURRENT_ACCOUNT" = "(unset)" ]; then
    log_info "Abriendo navegador para login..."
    gcloud auth login
else
    log_ok "Ya autenticado como: $CURRENT_ACCOUNT"
fi

# ADC para las librerias (google-genai usa esto)
if ! gcloud auth application-default print-access-token &>/dev/null; then
    log_info "Configurando Application Default Credentials (ADC)..."
    gcloud auth application-default login
else
    log_ok "ADC ya configurado"
fi

# ── [4/8] Proyecto GCP ──────────────────────────────────
log_step "[4/8] Configurando proyecto GCP..."

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
if [ -z "${PROJECT_ID:-}" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo -n "Ingresa tu Project ID de Google Cloud: "
    read -r PROJECT_ID
    if [ -z "$PROJECT_ID" ]; then
        log_err "Project ID vacio. Abortando."
        exit 1
    fi
    gcloud config set project "$PROJECT_ID"
fi
log_ok "Proyecto: $PROJECT_ID"

# Validar billing (warning no-bloqueante)
if gcloud billing projects describe "$PROJECT_ID" &>/dev/null; then
    BILLING_ENABLED=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null || echo "false")
    if [ "$BILLING_ENABLED" = "True" ] || [ "$BILLING_ENABLED" = "true" ]; then
        log_ok "Billing habilitado"
    else
        log_warn "Billing NO esta habilitado en $PROJECT_ID"
        log_warn "Vertex AI requiere billing. Habilitalo en:"
        log_warn "  https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    fi
else
    log_warn "No se pudo verificar billing (puede requerir rol de Billing Viewer)"
fi

# ── [5/8] Dependencias Python ───────────────────────────
log_step "[5/8] Instalando dependencias Python..."

if [ ! -d ".venv" ]; then
    log_info "Creando entorno virtual .venv..."
    python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

pip install --upgrade pip --quiet

# Regenerar requirements.txt si no existe
if [ ! -f "requirements.txt" ]; then
    log_info "requirements.txt no existe. Generando con pip-compile..."
    pip install pip-tools --quiet
    pip-compile requirements.in -o requirements.txt --quiet
    log_ok "requirements.txt generado"
fi

log_info "Instalando dependencias (puede tardar 1-2 minutos)..."
pip install -r requirements.txt --quiet
log_ok "Dependencias instaladas"

# ── [6/8] Habilitar APIs GCP ────────────────────────────
log_step "[6/8] Habilitando APIs de GCP..."

if gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID" 2>&1; then
    log_ok "Vertex AI API habilitada"
else
    log_err "No se pudo habilitar Vertex AI API"
    log_err "Verifica que tienes billing habilitado y permisos de Editor/Owner"
    exit 1
fi

# ── [7/8] Generar .env ──────────────────────────────────
log_step "[7/8] Generando archivo de configuracion .env..."

ENV_FILE="smart_code_builder/.env"
if [ -f "$ENV_FILE" ]; then
    log_warn ".env ya existe, creando backup .env.bak"
    cp "$ENV_FILE" "${ENV_FILE}.bak"
fi

cat > "$ENV_FILE" <<EOF
GCP_PROJECT_ID=$PROJECT_ID
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
EOF

log_ok ".env creado en $ENV_FILE"

# ── [8/8] Verificacion final ────────────────────────────
log_step "[8/8] Verificando instalacion..."

if ! command -v adk &>/dev/null; then
    log_err "'adk' no esta en el PATH despues de instalar."
    log_err "Verifica que el venv este activo: source .venv/bin/activate"
    exit 1
fi
log_ok "adk: $(adk --version 2>&1 | head -1)"

if python3 -c "from smart_code_builder.agent import root_agent" 2>&1; then
    log_ok "Import de root_agent funciona"
else
    log_err "No se pudo importar el agente"
    exit 1
fi

# ── Final ───────────────────────────────────────────────
echo
echo "============================================"
echo -e "${GREEN}  Setup completado exitosamente!${NC}"
echo "============================================"
echo
echo "Para ejecutar la aplicacion:"
echo
echo -e "  ${YELLOW}source .venv/bin/activate${NC}"
echo -e "  ${YELLOW}adk web smart_code_builder${NC}"
echo
echo "La app estara disponible en: http://localhost:8000"
echo
echo "Si adk no se encuentra, re-activa el venv con:"
echo -e "  ${YELLOW}source .venv/bin/activate${NC}"
echo
