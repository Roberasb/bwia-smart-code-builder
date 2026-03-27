"""Factory de modelos Gemini para Google ADK.

Soporta selección por tier (router/fast/heavy) para optimizar
costos y latencia según la complejidad de cada agente.
"""

from google.genai.types import GenerateContentConfig

from smart_code_builder.config import (
    FAST_MODEL,
    HEAVY_MODEL,
    MODEL_ID,
    ROUTER_MODEL,
)

_MODELS: dict[str, str] = {
    "router": ROUTER_MODEL,
    "fast": FAST_MODEL,
    "heavy": HEAVY_MODEL,
    "default": MODEL_ID,
}

_CONFIGS: dict[str, GenerateContentConfig] = {
    "router": GenerateContentConfig(
        temperature=0.1,
        max_output_tokens=256,
    ),
    "fast": GenerateContentConfig(
        temperature=0.3,
        max_output_tokens=4096,
        top_p=0.9,
    ),
    "heavy": GenerateContentConfig(
        temperature=0.2,
        max_output_tokens=8192,
        top_p=0.95,
    ),
}

_DEFAULT_CONFIG = GenerateContentConfig(
    temperature=0.3,
    max_output_tokens=4096,
)


def get_model(tier: str = "default") -> str:
    """Retorna el ID del modelo Gemini para el tier solicitado.

    Args:
        tier: Nivel de modelo — "router", "fast", "heavy" o "default".

    Returns:
        String con el ID del modelo Gemini.
    """
    return _MODELS.get(tier, MODEL_ID)


def get_generate_config(tier: str = "default") -> GenerateContentConfig:
    """Retorna la configuración de generación optimizada por tier.

    Cada tier limita tokens de salida y ajusta temperature para
    reducir costos sin sacrificar calidad donde importa.

    Args:
        tier: Nivel de modelo — "router", "fast", "heavy" o "default".

    Returns:
        GenerateContentConfig con parámetros optimizados.
    """
    return _CONFIGS.get(tier, _DEFAULT_CONFIG)
