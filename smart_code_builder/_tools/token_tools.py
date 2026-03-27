"""Tools para monitoreo y estimación de uso de tokens."""

import logging

logger = logging.getLogger(__name__)


def estimate_tokens(text: str) -> str:
    """Estima la cantidad de tokens de un texto.

    Usa el tokenizer de google-genai si esta disponible, con
    fallback a estimacion por palabras (~1.3 tokens/palabra).

    Util para que el agente evalúe si un contenido es demasiado
    grande antes de incluirlo en el contexto.

    Args:
        text: Texto a estimar.

    Returns:
        String con la cantidad estimada de tokens.
    """
    try:
        from google import genai

        client = genai.Client()
        result = client.models.count_tokens(
            model="gemini-2.5-flash",
            contents=text,
        )
        return f"Tokens estimados: {result.total_tokens:,}"
    except Exception as exc:
        word_count = len(text.split())
        estimated = int(word_count * 1.3)
        logger.debug("Token count API no disponible: %s", exc)
        return f"Tokens estimados (aprox): {estimated:,}"
