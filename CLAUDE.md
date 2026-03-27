# BWIA Smart Code Builder

## Estandares de Desarrollo
Este proyecto usa estandares open source en `standards/`:
- `standards/python_standards.md` - PEP 8, Google Style Guide, Ruff/uv, pytest
- `standards/typescript_standards.md` - Google TS Style Guide, Biome, Vitest
- Los agentes cargan estos archivos en runtime via `_tools/standards_tools.py`
- Al modificar standards, actualizar tambien los prompts de los agentes que los referencian

## Archivos Clave
- `smart_code_builder/agent.py` - Root agent (router)
- `smart_code_builder/{improve,create,modernize}_agent.py` - Sub-agentes
- `smart_code_builder/audit_agent.py` - Pipeline secuencial (crawler + reporter)
- `smart_code_builder/_tools/` - Tools compartidas entre agentes
- `smart_code_builder/config.py` - Env vars y paths (STANDARDS_DIR, TEMP_DIR)

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
