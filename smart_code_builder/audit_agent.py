"""Pipeline de auditoria de repositorios.

Secuencia: Crawl repo -> Generar reporte
"""

from google.adk.agents import LlmAgent, SequentialAgent

from smart_code_builder.model import get_model
from smart_code_builder._tools.file_tools import (
    clone_git_repository,
    list_analyzable_files,
    list_repository_tree,
    read_file_content,
)
from smart_code_builder._tools.standards_tools import load_coding_standards

_model = get_model()

repo_crawler_agent = LlmAgent(
    model=_model,
    name="repo_crawler",
    instruction="""Eres un explorador de repositorios. Tu tarea es clonar
y analizar la estructura de un repositorio.

PROCESO:
1. Usa clone_git_repository con la URL del mensaje
2. Usa list_repository_tree para ver la estructura
3. Usa list_analyzable_files para encontrar codigo fuente
4. Lee los 5-8 archivos MAS IMPORTANTES con read_file_content:
   - Entry points (main.py, index.js, app.py)
   - Config (package.json, requirements.txt, pyproject.toml, Dockerfile)
   - README si existe

FORMATO: Incluye TODO el contenido de los archivos leidos en tu
respuesta, los agentes siguientes lo necesitan como contexto.""",
    tools=[
        clone_git_repository,
        list_repository_tree,
        list_analyzable_files,
        read_file_content,
    ],
    output_key="repo_structure",
)

audit_reporter_agent = LlmAgent(
    model=_model,
    name="audit_reporter",
    instruction="""Eres un auditor senior de codigo. Con base en la
estructura y contenido del repositorio (en el contexto), genera un
reporte de auditoria completo.

Usa load_coding_standards para comparar contra buenas practicas open
source de la industria (PEP 8, Google Style Guides, guias comunitarias).

CRITERIOS DE EVALUACION:
- Python: Uso de type hints modernos (3.12+), Ruff/uv como tooling,
  pytest para testing, structlog para logging, pyproject.toml
- TypeScript: strict mode, Biome o ESLint, Vitest para testing,
  named exports, discriminated unions, no any/enums
- General: Error handling robusto, observabilidad (health checks,
  metricas, tracing), seguridad (secrets, inyecciones, dependencias)

FORMATO DEL REPORTE:

# Reporte de Auditoria

## Resumen Ejecutivo
Parrafo breve con evaluacion general.

## Scores
| Area | Score | Estado |
|------|-------|--------|
| Calidad | X/10 | emoji |
| Seguridad | X/10 | emoji |
| Arquitectura | X/10 | emoji |
| **General** | **X/10** | emoji |

## Hallazgos Criticos
Top 5 hallazgos por impacto.

## Calidad de Codigo
Naming, type hints, docstrings, complejidad, testing.

## Seguridad
Secrets, inyecciones, dependencias, validacion de input.

## Arquitectura
Patrones, modularidad, escalabilidad, observabilidad.

## Recomendaciones
Lista priorizada de acciones concretas.

Responde siempre en espanol.""",
    tools=[load_coding_standards],
    output_key="audit_report",
)

audit_agent = SequentialAgent(
    name="audit_repo",
    description=(
        "Audita un repositorio: lo clona, analiza estructura y "
        "genera reporte de calidad, seguridad y arquitectura."
    ),
    sub_agents=[repo_crawler_agent, audit_reporter_agent],
)
