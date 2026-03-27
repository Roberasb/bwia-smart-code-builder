# BWIA Smart Code Builder

An intelligent code assistance system built with [Google ADK](https://google.github.io/adk-docs/) (Agent Development Kit) and powered by Gemini. It helps developers improve, create, modernize, and audit code using open source best practices.

Built for [Google Build with AI 2025](https://buildwithai.devpost.com/).

## Architecture

```
                    ┌─────────────────────┐
                    │   Root Agent        │
                    │  (Smart Router)     │
                    └─────────┬───────────┘
                              │
            ┌─────────┬───────┴───────┬──────────┐
            ▼         ▼               ▼          ▼
     ┌────────┐ ┌──────────┐ ┌───────────┐ ┌─────────┐
     │improve │ │ create   │ │modernize  │ │ audit   │
     │ _code  │ │ _code    │ │  _code    │ │ _repo   │
     └────────┘ └──────────┘ └───────────┘ └────┬────┘
                                                 │
                                          ┌──────┴──────┐
                                          ▼             ▼
                                    ┌──────────┐ ┌───────────┐
                                    │  repo    │ │  audit    │
                                    │ crawler  │ │ reporter  │
                                    └──────────┘ └───────────┘
```

### Agents

| Agent | Type | Description |
|-------|------|-------------|
| **smart_code_builder** | Router | Analyzes requests and delegates to the right sub-agent |
| **improve_code** | LlmAgent | Reviews and refactors existing code applying open source best practices |
| **create_code** | LlmAgent | Generates new code from natural language descriptions |
| **modernize_code** | LlmAgent | Transforms legacy code to modern versions (Python 3.12+, ES2024+, TS 5.x+) |
| **audit_repo** | SequentialAgent | Clones a GitHub repository and generates a quality/security/architecture audit report |

### Tools

| Tool | Description |
|------|-------------|
| `detect_code_language` | Detects programming language from code content or filename |
| `load_coding_standards` | Loads open source coding standards (Python, TypeScript, JavaScript) |
| `clone_git_repository` | Shallow clones a public GitHub repository |
| `list_repository_tree` | Lists the file structure of a cloned repository |
| `list_analyzable_files` | Lists source code files suitable for analysis |
| `read_file_content` | Reads file content with size limits |

### Standards

The agents use curated coding standards based on open source community guidelines:

- **Python**: [PEP 8](https://peps.python.org/pep-0008/), [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html), [Ruff](https://docs.astral.sh/ruff/), [uv](https://docs.astral.sh/uv/)
- **TypeScript/JavaScript**: [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html), [ts.dev](https://ts.dev/style/), [Biome](https://biomejs.dev/), [Vitest](https://vitest.dev/)

## Prerequisites

- Python 3.11+
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- A GCP project with Vertex AI API enabled
- Authenticated with `gcloud auth application-default login`

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/bwia-smart-code-builder.git
cd bwia-smart-code-builder
```

### 2. Set up environment

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Or use the setup script
bash scripts/setup.sh
```

### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```
GCP_PROJECT_ID=your-gcp-project-id
GCP_LOCATION=global
MODEL_ID=gemini-3.1-pro-preview
```

### 4. Run locally

```bash
# Web UI (development)
adk web smart_code_builder

# CLI mode
adk run smart_code_builder
```

## Usage Examples

### Improve existing code

> "Mejora este codigo Python aplicando buenas practicas:"
> ```python
> def get_data(url):
>     import requests
>     r = requests.get(url)
>     return r.json()
> ```

### Create new code

> "Crea un servicio REST con FastAPI que gestione usuarios con CRUD completo"

### Modernize legacy code

> "Moderniza este codigo JavaScript a TypeScript moderno:"
> ```javascript
> var http = require('http');
> var server = http.createServer(function(req, res) {
>     res.end('Hello');
> });
> ```

### Audit a repository

> "Audita este repositorio: https://github.com/user/repo"

## Deployment to Cloud Run

```bash
# Set your GCP project
export GCP_PROJECT_ID=your-project-id

# Full deployment (setup + build + push + deploy)
make all

# Or step by step
make setup     # Enable APIs and create Artifact Registry
make build     # Build container with Podman
make push      # Push to Artifact Registry
make deploy    # Deploy to Cloud Run
```

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make setup` | Enable GCP APIs and create Artifact Registry repository |
| `make build` | Build container image with Podman (linux/amd64) |
| `make push` | Push image to Artifact Registry |
| `make deploy` | Deploy to Cloud Run |
| `make local` | Run locally via ADK CLI |
| `make web` | Run locally via ADK Web UI |
| `make logs` | View Cloud Run logs |
| `make all` | Full pipeline: setup + build + push + deploy |

## Project Structure

```
bwia-smart-code-builder/
├── smart_code_builder/          # Main package
│   ├── __init__.py              # Exports root_agent
│   ├── agent.py                 # Root agent (router)
│   ├── improve_agent.py         # Code improvement agent
│   ├── create_agent.py          # Code creation agent
│   ├── modernize_agent.py       # Code modernization agent
│   ├── audit_agent.py           # Repository audit pipeline
│   ├── model.py                 # Model configuration
│   ├── config.py                # Environment configuration
│   └── _tools/                  # Agent tools
│       ├── code_tools.py        # Language detection
│       ├── file_tools.py        # Repository operations
│       └── standards_tools.py   # Standards loader
├── standards/                   # Coding standards (open source)
│   ├── python_standards.md      # Python best practices
│   └── typescript_standards.md  # TypeScript best practices
├── tests/                       # Test suite
├── scripts/                     # Utility scripts
├── .env.example                 # Environment template
├── Dockerfile                   # Cloud Run container
├── Makefile                     # Build/deploy automation
├── pyproject.toml               # Project metadata
└── requirements.txt             # Python dependencies
```

## Tech Stack

- **Agent Framework**: [Google ADK](https://google.github.io/adk-docs/) (Agent Development Kit)
- **Model**: Gemini 3.1 Pro Preview (via Vertex AI)
- **Runtime**: Python 3.11+ / FastAPI / Uvicorn
- **Deployment**: Google Cloud Run + Artifact Registry
- **Container**: Podman (Docker compatible)

## License

This project is open source. See individual files for details.
