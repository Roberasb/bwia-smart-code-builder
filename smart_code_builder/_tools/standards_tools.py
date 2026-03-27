"""Tools para cargar estandares de codificacion open source."""

import os

from smart_code_builder.config import STANDARDS_DIR

_STANDARDS_MAP: dict[str, str] = {
    "python": "python_standards.md",
    "typescript": "typescript_standards.md",
    "javascript": "typescript_standards.md",
}


def load_coding_standards(language: str) -> str:
    """Carga los estandares de codificacion para el lenguaje especificado.

    Lee los estandares de desarrollo basados en buenas practicas open
    source de la industria (PEP 8, Google Style Guides, guias
    comunitarias). Incluye convenciones de naming, formateo, type hints,
    testing, error handling, tooling moderno, y mas.

    Args:
        language: Lenguaje de programacion (python, typescript,
            javascript).

    Returns:
        Contenido completo de los estandares como string.
    """
    filename = _STANDARDS_MAP.get(language.lower())
    if not filename:
        return (
            f"No hay estandares disponibles para '{language}'. "
            f"Lenguajes soportados: {', '.join(_STANDARDS_MAP.keys())}"
        )

    filepath = os.path.join(STANDARDS_DIR, filename)
    if not os.path.exists(filepath):
        return f"Archivo de estandares no encontrado: {filepath}"

    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()
