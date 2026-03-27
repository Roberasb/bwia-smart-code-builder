"""Configuracion centralizada del proyecto."""

import os

from dotenv import load_dotenv

load_dotenv()

GCP_PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "")
GCP_LOCATION: str = os.getenv("GCP_LOCATION", "global")
MODEL_ID: str = os.getenv("MODEL_ID", "gemini-3.1-pro-preview")

# Configurar google-genai para usar Vertex AI con ADC
os.environ.setdefault("GOOGLE_GENAI_USE_VERTEXAI", "true")
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", GCP_PROJECT_ID)
os.environ.setdefault("GOOGLE_CLOUD_LOCATION", GCP_LOCATION)

STANDARDS_DIR: str = os.path.join(
    os.path.dirname(os.path.dirname(__file__)), "standards"
)

TEMP_DIR: str = os.path.join("/tmp", "bwia-audit")
