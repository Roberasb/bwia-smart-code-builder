"""Tools para cargar estandares de codificacion open source."""

import os
from functools import lru_cache

from smart_code_builder.config import STANDARDS_DIR

_STANDARDS_MAP: dict[str, str] = {
    "python": "python_standards.md",
    "typescript": "typescript_standards.md",
    "javascript": "typescript_standards.md",
}


@lru_cache(maxsize=4)
def _read_standards_file(filepath: str) -> str:
    """Lee y cachea un archivo de estandares desde disco.

    Usa lru_cache para evitar lecturas repetidas del mismo archivo.
    Los standards son estáticos durante la ejecución del servidor.

    Args:
        filepath: Path absoluto al archivo de estandares.

    Returns:
        Contenido del archivo como string.
    """
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def load_coding_standards(language: str) -> str:
    """Carga los estandares de codificacion para el lenguaje especificado.

    Lee los estandares de desarrollo basados en buenas practicas open
    source de la industria (PEP 8, Google Style Guides, guias
    comunitarias). Incluye convenciones de naming, formateo, type hints,
    testing, error handling, tooling moderno, y mas.

    Los archivos se cachean en memoria tras la primera lectura.

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

    return _read_standards_file(filepath)
