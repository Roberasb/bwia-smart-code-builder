#!/bin/bash
set -euo pipefail

echo "============================================"
echo "  BWIA Smart Code Builder - Workshop Setup"
echo "============================================"
echo ""

# Verificar prerequisitos
echo "[1/5] Verificando prerequisitos..."

if ! command -v gcloud &>/dev/null; then
    echo "ERROR: gcloud CLI no esta instalado."
    echo "Descarga: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 no esta instalado."
    exit 1
fi

PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "  - gcloud: OK"
echo "  - python3: OK (v$PYTHON_VERSION)"

# Configurar autenticacion GCP
echo ""
echo "[2/5] Configurando autenticacion GCP..."
echo "  Se abrira el navegador para iniciar sesion."
echo ""

gcloud auth login
gcloud auth application-default login

# Obtener y configurar proyecto
echo ""
echo "[3/5] Configurando proyecto GCP..."

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "No hay proyecto configurado."
    echo -n "Ingresa tu Project ID: "
    read -r PROJECT_ID
    gcloud config set project "$PROJECT_ID"
fi
echo "  Proyecto: $PROJECT_ID"

# Crear .env dentro del paquete del agente
echo ""
echo "[4/5] Creando archivo de configuracion .env..."

ENV_FILE="smart_code_builder/.env"
if [ -f "$ENV_FILE" ]; then
    echo "  .env ya existe, creando backup .env.bak"
    cp "$ENV_FILE" "${ENV_FILE}.bak"
fi

cat > "$ENV_FILE" <<EOF
GCP_PROJECT_ID=$PROJECT_ID
GCP_LOCATION=global
MODEL_ID=gemini-3.1-pro-preview
EOF
echo "  .env creado con PROJECT_ID=$PROJECT_ID"

# Crear venv e instalar dependencias
echo ""
echo "[5/5] Instalando dependencias..."

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Habilitar APIs
echo ""
echo "Habilitando Vertex AI API..."
gcloud services enable aiplatform.googleapis.com

echo ""
echo "============================================"
echo "  Setup completado exitosamente!"
echo "============================================"
echo ""
echo "Para ejecutar la aplicacion:"
echo ""
echo "  source .venv/bin/activate"
echo "  adk web smart_code_builder"
echo ""
echo "La app estara disponible en: http://localhost:8000"
echo ""
