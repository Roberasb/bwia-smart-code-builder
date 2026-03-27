"""Factory del modelo Gemini para Google ADK."""

from smart_code_builder.config import MODEL_ID


def get_model() -> str:
    """Retorna el ID del modelo Gemini para ADK.

    Returns:
        String con el ID del modelo.
    """
    return MODEL_ID
