"""Tools para operaciones de archivos y repositorios."""

import os
import shutil
import subprocess
import uuid

from smart_code_builder.config import TEMP_DIR

_EXCLUDE_DIRS = {
    ".git", "node_modules", ".venv", "__pycache__", ".next",
    "dist", "build", ".cache", ".mypy_cache", ".pytest_cache",
    "coverage", ".terraform", ".terragrunt-cache",
}

_EXCLUDE_EXTENSIONS = {
    ".pyc", ".pyo", ".exe", ".dll", ".so", ".dylib", ".jar",
    ".class", ".o", ".a", ".png", ".jpg", ".jpeg", ".gif",
    ".ico", ".svg", ".woff", ".woff2", ".ttf", ".eot",
    ".mp3", ".mp4", ".zip", ".tar", ".gz", ".lock",
}

_ANALYZABLE_EXTENSIONS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".json",
    ".yaml", ".yml", ".toml", ".cfg", ".ini", ".md",
    ".sh", ".bash", ".dockerfile",
}


def clone_git_repository(repo_url: str) -> str:
    """Clona un repositorio git publico a un directorio temporal.

    Realiza un shallow clone (--depth 1) para rapidez. Solo soporta
    repositorios publicos con URL HTTPS.

    Args:
        repo_url: URL HTTPS del repositorio git.

    Returns:
        Path absoluto al directorio donde se clono el repo.
    """
    clone_dir = os.path.join(TEMP_DIR, f"repo-{uuid.uuid4().hex[:8]}")
    os.makedirs(clone_dir, exist_ok=True)
    subprocess.run(
        ["git", "clone", "--depth", "1", repo_url, clone_dir],
        check=True, timeout=120, capture_output=True, text=True,
    )
    return clone_dir


def list_repository_tree(directory: str) -> str:
    """Lista la estructura completa de archivos de un directorio.

    Excluye directorios irrelevantes y archivos binarios.

    Args:
        directory: Path absoluto al directorio raiz.

    Returns:
        Arbol de archivos formateado como string.
    """
    result: list[str] = []
    file_count = 0
    for root, dirs, files in os.walk(directory):
        dirs[:] = sorted(d for d in dirs if d not in _EXCLUDE_DIRS)
        level = root.replace(directory, "").count(os.sep)
        indent = "  " * level
        result.append(f"{indent}{os.path.basename(root)}/")
        sub_indent = "  " * (level + 1)
        for filename in sorted(files):
            _, ext = os.path.splitext(filename)
            if ext.lower() not in _EXCLUDE_EXTENSIONS:
                result.append(f"{sub_indent}{filename}")
                file_count += 1
    result.insert(0, f"Total archivos: {file_count}\n")
    return "\n".join(result)


def read_file_content(file_path: str) -> str:
    """Lee el contenido de un archivo del repositorio.

    Limite de 50KB para evitar sobrecargar el contexto.

    Args:
        file_path: Path absoluto al archivo.

    Returns:
        Contenido del archivo como string.
    """
    max_size = 50 * 1024
    if not os.path.exists(file_path):
        return f"Archivo no encontrado: {file_path}"
    size = os.path.getsize(file_path)
    if size > max_size:
        return f"Archivo demasiado grande ({size // 1024}KB). Limite: {max_size // 1024}KB."
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        return "Archivo binario, no se puede leer como texto."


def list_analyzable_files(directory: str) -> str:
    """Lista archivos de codigo fuente analizables del directorio.

    Filtra por extensiones conocidas, limita a 20 archivos.

    Args:
        directory: Path absoluto al directorio raiz.

    Returns:
        Lista de paths relativos de archivos analizables.
    """
    files: list[str] = []
    for root, dirs, filenames in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in _EXCLUDE_DIRS]
        for filename in filenames:
            _, ext = os.path.splitext(filename)
            if ext.lower() in _ANALYZABLE_EXTENSIONS:
                rel_path = os.path.relpath(
                    os.path.join(root, filename), directory
                )
                files.append(rel_path)
    files.sort(key=lambda f: (
        0 if f.endswith((".py", ".js", ".ts", ".tsx")) else 1, f,
    ))
    limited = files[:20]
    result = f"Archivos analizables: {len(files)} (mostrando {len(limited)})\n"
    result += "\n".join(f"- {f}" for f in limited)
    return result
