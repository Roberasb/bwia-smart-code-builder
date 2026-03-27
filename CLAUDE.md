# BWIA Smart Code Builder

## Estandares AXMOS (opt-in)
Este proyecto sigue los estandares de desarrollo de AXMOS Technologies.
Antes de generar codigo, consulta el estandar del lenguaje correspondiente en:
- `/Users/gabriel/Documents/axmos/repos/coding/languages/` (Python.md, GoLang.md, TypeScript.md, Shell.md, JSON.md)
- Git workflow y convenciones: `/Users/gabriel/Documents/axmos/repos/coding/CODING.md`
- Arquitectura GCP: `/Users/gabriel/Documents/axmos/repos/coding/architecture/`

## Arquitectura
- Framework de agentes: Google ADK (Agent Development Kit)
- Modelo: Gemini 3.1 Pro Preview (nativo en ADK)
- UI: ADK Web (`adk web smart_code_builder`)
- 4 sub-agentes: improve_code, create_code, modernize_code, audit_repo
- Root Agent actua como router inteligente

## Ejecucion
```bash
# Web UI (desarrollo)
adk web smart_code_builder

# CLI
adk run smart_code_builder

# Cloud Run
make all
```

## Variables de Entorno (smart_code_builder/.env)
- `GCP_PROJECT_ID`: ID del proyecto GCP
- `GCP_LOCATION`: Region (default: global)
- `MODEL_ID`: ID del modelo Gemini (default: gemini-3.1-pro-preview)
