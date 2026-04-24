"""Configuracion centralizada del proyecto."""

import os
import tempfile

from dotenv import load_dotenv

load_dotenv()

GCP_PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "")
GCP_LOCATION: str = os.getenv("GCP_LOCATION", "global")

# ── Modelo por tier (costo/capacidad) ──────────────────────────
# Router: solo clasifica intención, no necesita razonamiento
ROUTER_MODEL: str = os.getenv("ROUTER_MODEL", "gemini-2.5-flash-lite")
# Fast: generación de código, crawling — buen balance velocidad/calidad
FAST_MODEL: str = os.getenv("FAST_MODEL", "gemini-2.5-flash")
# Heavy: análisis profundo, auditorías, code review
HEAVY_MODEL: str = os.getenv("HEAVY_MODEL", "gemini-2.5-pro")
# Fallback para compatibilidad
MODEL_ID: str = os.getenv("MODEL_ID", FAST_MODEL)

# Configurar google-genai para usar Vertex AI con ADC
os.environ.setdefault("GOOGLE_GENAI_USE_VERTEXAI", "true")
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", GCP_PROJECT_ID)
os.environ.setdefault("GOOGLE_CLOUD_LOCATION", GCP_LOCATION)

STANDARDS_DIR: str = os.path.join(
    os.path.dirname(os.path.dirname(__file__)), "standards"
)

TEMP_DIR: str = os.path.join(tempfile.gettempdir(), "bwia-audit")
