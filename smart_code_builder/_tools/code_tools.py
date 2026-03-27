"""Tools para analisis de codigo."""

_EXTENSION_MAP: dict[str, str] = {
    ".py": "python",
    ".js": "javascript",
    ".ts": "typescript",
    ".tsx": "typescript",
    ".jsx": "javascript",
}


def detect_code_language(code: str, filename: str = "") -> str:
    """Detecta el lenguaje de programacion de un fragmento de codigo.

    Analiza el contenido del codigo y opcionalmente el nombre del
    archivo para determinar el lenguaje de programacion.

    Args:
        code: Codigo fuente a analizar.
        filename: Nombre del archivo (opcional, mejora la deteccion).

    Returns:
        Nombre del lenguaje detectado (python, javascript, typescript,
        o unknown).
    """
    if filename:
        for ext, lang in _EXTENSION_MAP.items():
            if filename.endswith(ext):
                return lang

    indicators = {
        "python": ["def ", "import ", "class ", "self.", "elif "],
        "typescript": ["interface ", ": string", ": number", "export "],
        "javascript": ["function ", "const ", "=>", "require("],
    }

    scores: dict[str, int] = {}
    for lang, keywords in indicators.items():
        scores[lang] = sum(1 for kw in keywords if kw in code)

    if not scores or max(scores.values()) == 0:
        return "unknown"

    return max(scores, key=lambda k: scores[k])
