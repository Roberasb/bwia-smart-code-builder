# GEMINI.md - BWIA Smart Code Builder

This file documents the actual, working way to run this repository after local validation and fixes.

## What This Repo Is
- Python project built with Google ADK.
- Exposes `root_agent` from `smart_code_builder/__init__.py`.
- The root agent routes requests to 4 sub-agents:
  - `improve_code`
  - `create_code`
  - `modernize_code`
  - `audit_repo`
- Models run on Vertex AI using Gemini.

## Most Important Rule
- Always run the app from the repository root.
- The correct agents directory is `.` and not `smart_code_builder`.

Correct commands:
```bash
adk web .
adk run .
adk api_server --host=0.0.0.0 --port=8000 .
```

Commands to avoid:
```bash
adk web smart_code_builder
adk run smart_code_builder
adk api_server --host=0.0.0.0 --port=8000 smart_code_builder
```

## Real Requirements
- Python 3.11+
- `git`
- `gcloud`
- A GCP project with Vertex AI enabled
- Application Default Credentials configured with:

```bash
gcloud auth application-default login
```

## Environment File
This repo expects the environment file at:

```bash
smart_code_builder/.env
```

Minimum working config:
```bash
GCP_PROJECT_ID=your-project-id
GCP_LOCATION=global
ROUTER_MODEL=gemini-2.5-flash-lite
FAST_MODEL=gemini-2.5-flash
HEAVY_MODEL=gemini-2.5-pro
MODEL_ID=gemini-2.5-flash
```

Notes:
- `GCP_LOCATION=global` is the recommended setting to reduce availability issues and 429 errors.
- `config.py` sets `GOOGLE_GENAI_USE_VERTEXAI=true`.
- ADK correctly loads `smart_code_builder/.env` when started from the repo root.

## Recommended Setup

### Windows
```powershell
.\scripts\setup.ps1
```

### Linux / macOS
```bash
bash scripts/setup.sh
```

Those scripts:
1. validate the repo root
2. install prerequisites
3. run `gcloud auth login`
4. run `gcloud auth application-default login`
5. set the active GCP project
6. enable `aiplatform.googleapis.com`
7. create `.venv`
8. install dependencies
9. generate `smart_code_builder/.env`
10. verify `adk` and `root_agent`

## Manual Setup

### 1. Create the virtual environment
```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 2. Install Google Cloud CLI
If `gcloud` is missing on Windows:
```powershell
winget install -e --id Google.CloudSDK
```

### 3. Authenticate with Google Cloud
```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_GCP_PROJECT_ID
gcloud services enable aiplatform.googleapis.com --project YOUR_GCP_PROJECT_ID
```

### 4. Create `smart_code_builder/.env`
Use the config shown above.

### 5. Minimum verification
```powershell
gcloud auth list
gcloud auth application-default print-access-token
gcloud config get-value project
.\.venv\Scripts\adk.exe --version
.\.venv\Scripts\python.exe -c "from smart_code_builder.agent import root_agent; print(root_agent.name)"
```

## Running Locally

### Option 1: Web UI
```powershell
.\.venv\Scripts\adk.exe web .
```

Open:
```text
http://127.0.0.1:8000/dev-ui/
```

### Option 2: API server
```powershell
.\.venv\Scripts\adk.exe api_server --host=127.0.0.1 --port=8000 .
```

### Option 3: CLI
```powershell
.\.venv\Scripts\adk.exe run .
```

## Quick Functional Prompts
```text
Improve this Python code applying best practices:
def get_data(url):
    import requests
    r = requests.get(url)
    return r.json()
```

```text
Create a FastAPI REST service for users with full CRUD
```

```text
Modernize this JavaScript code to modern TypeScript:
var http = require("http");
var server = http.createServer(function (req, res) {
  res.end("Hello");
});
```

```text
Audit this repository: https://github.com/public-apis/public-apis
```

## Current Repo State After Bring-Up

### Already Fixed
- `clone_git_repository` now works on Windows.
- `TEMP_DIR` uses `tempfile.gettempdir()` instead of hardcoded `"/tmp"`.
- The audit pipeline no longer breaks by creating the clone destination before `git clone`.
- `Dockerfile` now starts ADK with `.` as the agents dir.
- `README.md`, `CLAUDE.md`, and `pyproject.toml` are aligned with actual runtime behavior.

### Known Limitations
- Large repository audits can still trigger Vertex AI `429 RESOURCE_EXHAUSTED`.
- This is typically a temporary shared-capacity issue, not necessarily a code bug.
- Current mitigations already applied:
  - `GCP_LOCATION=global`
  - lighter crawler behavior
  - `audit_reporter` using `fast` instead of `heavy`
- If it happens again:
  - wait 30-60 seconds
  - retry
  - avoid launching multiple audits in parallel

## Key Files
- `smart_code_builder/__init__.py`: exports `root_agent`
- `smart_code_builder/agent.py`: main router
- `smart_code_builder/improve_agent.py`: code improvement agent
- `smart_code_builder/create_agent.py`: code generation agent
- `smart_code_builder/modernize_agent.py`: modernization agent
- `smart_code_builder/audit_agent.py`: repository audit pipeline
- `smart_code_builder/model.py`: model tier selection
- `smart_code_builder/config.py`: env vars and paths
- `smart_code_builder/_tools/file_tools.py`: clone, tree listing, file reading
- `standards/`: Python and TypeScript/JavaScript standards

## Quick Troubleshooting

### `adk` is not recognized
Activate the venv or use the explicit path:
```powershell
.\.venv\Scripts\adk.exe web .
```

### `gcloud` is not recognized
Install it:
```powershell
winget install -e --id Google.CloudSDK
```

Then open a new terminal.

### `DefaultCredentialsError`
ADC are missing:
```powershell
gcloud auth application-default login
```

### `Session not found`
This happens when calling `/run` directly without creating a session first. The web UI handles this for you.

### `429 RESOURCE_EXHAUSTED`
- wait and retry
- use `global`
- avoid bursts
- avoid parallel large audits

### App starts but does not answer
Verify:
```powershell
gcloud auth application-default print-access-token
gcloud config get-value project
```

And confirm `smart_code_builder/.env` exists.

## Development Conventions
- Standards live in `standards/`
- Python: PEP 8, Google Style Guide, Ruff/uv
- TypeScript: Google TS Style Guide, Biome, Vitest
- If prompts or standards change, keep these aligned:
  - `standards/*.md`
  - `smart_code_builder/*_agent.py`
  - `README.md`
  - `CLAUDE.md`
  - `GEMINI.md`
