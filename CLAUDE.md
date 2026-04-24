# BWIA Smart Code Builder

## Que es este repo
- Proyecto Python basado en Google ADK.
- Expone un `root_agent` en `smart_code_builder/__init__.py`.
- El agente raiz enruta a 4 sub-agentes:
  - `improve_code`
  - `create_code`
  - `modernize_code`
  - `audit_repo`
- Los modelos corren en Vertex AI usando Gemini.

## Regla mas importante para levantarlo
- Ejecutar siempre desde la raiz del repo.
- El directorio correcto es el que contiene:
  - `smart_code_builder/agent.py`
  - `requirements.txt`
  - `Dockerfile`
  - `Makefile`
- El arranque correcto es con `.` como agents dir, no con `smart_code_builder`.

Comandos correctos:
```bash
adk web .
adk run .
adk api_server --host=0.0.0.0 --port=8000 .
```

Comandos a evitar:
```bash
adk web smart_code_builder
adk run smart_code_builder
adk api_server --host=0.0.0.0 --port=8000 smart_code_builder
```

## Requisitos reales
- Python 3.11+
- `git`
- `gcloud`
- Un proyecto GCP con Vertex AI habilitado
- ADC configuradas con `gcloud auth application-default login`

## Variables de entorno
Este repo espera el archivo de entorno en:

```bash
smart_code_builder/.env
```

Variables minimas:
```bash
GCP_PROJECT_ID=tu-project-id
GCP_LOCATION=global
ROUTER_MODEL=gemini-2.5-flash-lite
FAST_MODEL=gemini-2.5-flash
HEAVY_MODEL=gemini-2.5-pro
MODEL_ID=gemini-2.5-flash
```

Notas:
- `GCP_LOCATION=global` es la configuracion recomendada para reducir errores de capacidad y disponibilidad.
- `config.py` setea `GOOGLE_GENAI_USE_VERTEXAI=true`.
- ADK carga correctamente `smart_code_builder/.env` cuando el repo se arranca desde la raiz.

## Setup recomendado

### Windows
```powershell
.\scripts\setup.ps1
```

### Linux / macOS
```bash
bash scripts/setup.sh
```

Los scripts hacen esto:
1. validan que estes en la raiz del repo
2. instalan prerequisitos
3. ejecutan `gcloud auth login`
4. ejecutan `gcloud auth application-default login`
5. fijan el proyecto en `gcloud`
6. habilitan `aiplatform.googleapis.com`
7. crean `.venv`
8. instalan dependencias
9. generan `smart_code_builder/.env`
10. verifican que `adk` y `root_agent` funcionen

## Setup manual

### 1. Crear venv e instalar dependencias
```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 2. Instalar y configurar Google Cloud CLI
Si `gcloud` no existe:
```powershell
winget install -e --id Google.CloudSDK
```

### 3. Login de GCP
```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project TU_GCP_PROJECT_ID
gcloud services enable aiplatform.googleapis.com --project TU_GCP_PROJECT_ID
```

### 4. Crear `smart_code_builder/.env`
Usar el formato indicado arriba.

### 5. Verificaciones minimas
```powershell
gcloud auth list
gcloud auth application-default print-access-token
gcloud config get-value project
.\.venv\Scripts\adk.exe --version
.\.venv\Scripts\python.exe -c "from smart_code_builder.agent import root_agent; print(root_agent.name)"
```

## Como levantarlo localmente

### Opcion 1: UI web
```powershell
.\.venv\Scripts\adk.exe web .
```

Abrir:
```text
http://127.0.0.1:8000/dev-ui/
```

### Opcion 2: API server
```powershell
.\.venv\Scripts\adk.exe api_server --host=127.0.0.1 --port=8000 .
```

### Opcion 3: CLI
```powershell
.\.venv\Scripts\adk.exe run .
```

## Como probar que funciona
Prompts utiles:

```text
Mejora este codigo Python aplicando buenas practicas:
def get_data(url):
    import requests
    r = requests.get(url)
    return r.json()
```

```text
Crea un servicio REST con FastAPI que gestione usuarios con CRUD completo
```

```text
Moderniza este codigo JavaScript a TypeScript moderno:
var http = require("http");
var server = http.createServer(function (req, res) {
  res.end("Hello");
});
```

```text
Audita este repositorio: https://github.com/public-apis/public-apis
```

## Estado real del repo despues de la puesta en marcha

### Ya corregido
- El `clone_git_repository` ahora funciona en Windows.
- `TEMP_DIR` usa `tempfile.gettempdir()` en vez de `"/tmp"` hardcodeado.
- El pipeline de auditoria ya no rompe por crear mal la carpeta destino de `git clone`.
- El `Dockerfile` ya arranca ADK con `.` como agents dir.
- `README.md` y `pyproject.toml` ya fueron alineados con el comportamiento real.

### Limitaciones conocidas
- Las auditorias de repos grandes pueden disparar `429 RESOURCE_EXHAUSTED` de Vertex AI.
- Eso no significa necesariamente un bug del repo; suele ser saturacion temporal de capacidad compartida.
- Mitigaciones ya aplicadas:
  - `GCP_LOCATION=global`
  - crawler mas liviano
  - `audit_reporter` usando `fast` en vez de `heavy`
- Si vuelve a ocurrir:
  - esperar 30-60 segundos
  - reintentar
  - evitar lanzar varias auditorias al mismo tiempo

## Archivos clave
- `smart_code_builder/__init__.py`: exporta `root_agent`
- `smart_code_builder/agent.py`: router principal
- `smart_code_builder/improve_agent.py`: mejora de codigo
- `smart_code_builder/create_agent.py`: creacion de codigo
- `smart_code_builder/modernize_agent.py`: modernizacion
- `smart_code_builder/audit_agent.py`: auditoria de repositorios
- `smart_code_builder/model.py`: seleccion de modelos por tier
- `smart_code_builder/config.py`: carga de env vars y paths
- `smart_code_builder/_tools/file_tools.py`: clone, tree, lectura de archivos
- `standards/`: estandares de Python y TypeScript/JavaScript

## Troubleshooting rapido

### `adk` no se reconoce
Activar el venv o usar la ruta explicita:
```powershell
.\.venv\Scripts\adk.exe web .
```

### `gcloud` no se reconoce
Instalar con:
```powershell
winget install -e --id Google.CloudSDK
```

Luego abrir una terminal nueva.

### `DefaultCredentialsError`
Faltan ADC:
```powershell
gcloud auth application-default login
```

### `Session not found`
Ocurre al usar la API `/run` sin crear sesion antes. La UI web no requiere manejar esto manualmente.

### `429 RESOURCE_EXHAUSTED`
- esperar y reintentar
- usar `global`
- evitar bursts
- no correr varias auditorias en paralelo

### El repo arranca pero no responde
Verificar:
```powershell
gcloud auth application-default print-access-token
gcloud config get-value project
```

Y confirmar que `smart_code_builder/.env` exista.

## Convenciones de desarrollo
- Standards en `standards/`
- Python: PEP 8, Google Style Guide, Ruff/uv
- TypeScript: Google TS Style Guide, Biome, Vitest
- Si cambias prompts o standards, revisar consistencia entre:
  - `standards/*.md`
  - sub-agentes en `smart_code_builder/*_agent.py`
  - `README.md`
  - `CLAUDE.md`
