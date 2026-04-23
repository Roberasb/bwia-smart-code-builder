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

| Agent                  | Type            | Model Tier            | Description                                                                           |
| ---------------------- | --------------- | --------------------- | ------------------------------------------------------------------------------------- |
| **smart_code_builder** | Router          | `router` (Flash-Lite) | Analyzes requests and delegates to the right sub-agent                                |
| **improve_code**       | LlmAgent        | `heavy` (Pro)         | Reviews and refactors existing code applying open source best practices               |
| **create_code**        | LlmAgent        | `fast` (Flash)        | Generates new code from natural language descriptions                                 |
| **modernize_code**     | LlmAgent        | `heavy` (Pro)         | Transforms legacy code to modern versions (Python 3.12+, ES2024+, TS 5.x+)            |
| **audit_repo**         | SequentialAgent | —                     | Clones a GitHub repository and generates a quality/security/architecture audit report |
| ↳ repo_crawler         | LlmAgent        | `fast` (Flash)        | Explores repository structure and reads key files                                     |
| ↳ audit_reporter       | LlmAgent        | `heavy` (Pro)         | Analyzes code against standards and produces scored report                            |

### Tools

| Tool                    | Description                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------ |
| `detect_code_language`  | Detects programming language from code content or filename                           |
| `load_coding_standards` | Loads open source coding standards (Python, TypeScript, JavaScript) with LRU caching |
| `clone_git_repository`  | Shallow clones a public GitHub repository (auto-cleans old repos)                    |
| `list_repository_tree`  | Lists the file structure of a cloned repository                                      |
| `list_analyzable_files` | Lists source code files suitable for analysis (max 20 files)                         |
| `read_file_content`     | Reads file content with 50KB size limit                                              |
| `estimate_tokens`       | Estimates token count using Gemini tokenizer (fallback: ~1.3 tokens/word)            |

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

### 2. Set up environment (Recommended)

The easiest way to get started is using the provided setup scripts. They run an 8-step automated setup:

1. **Validate project directory** — ensures you're in the repo root
2. **Install prerequisites** — Python 3.11+, Google Cloud CLI, git (via `brew`, `apt`, `dnf`, `pacman` or `winget`)
3. **Configure GCP authentication** — `gcloud auth login` + ADC for the SDK
4. **Select GCP project** — with a non-blocking billing check
5. **Install Python dependencies** — creates `.venv`, regenerates `requirements.txt` via `pip-compile` if missing
6. **Enable Vertex AI API** — `aiplatform.googleapis.com`
7. **Generate `.env`** — populates all model tiers (router/fast/heavy)
8. **Verify installation** — checks `adk --version` and imports `root_agent`

**Linux/macOS:**

```bash
bash scripts/setup.sh
```

**Windows (PowerShell):**

```powershell
.\scripts\setup.ps1
```

**Supported platforms:**

- macOS (Homebrew)
- Linux: Debian/Ubuntu (`apt`), RHEL/Fedora (`dnf`), Arch (`pacman`)
- Windows 10/11 with PowerShell + winget

### 3. Manual setup (Optional)

If you prefer to set up manually:

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your GCP_PROJECT_ID
```

Edit `.env` with your values:

```bash
GCP_PROJECT_ID=your-gcp-project-id
GCP_LOCATION=global

# Model tiers (cost/capability)
ROUTER_MODEL=gemini-2.5-flash-lite   # Routing, classification (cheapest)
FAST_MODEL=gemini-2.5-flash           # Code generation, crawling (balanced)
HEAVY_MODEL=gemini-2.5-pro            # Deep analysis, audits (best quality)
MODEL_ID=gemini-2.5-flash             # Fallback (optional)
```

### 4. Run locally

```bash
# Web UI (development)
adk web .

# CLI mode
adk run .
```

## Usage Examples

### Improve existing code

> "Mejora este codigo Python aplicando buenas practicas:"
>
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
>
> ```javascript
> var http = require("http");
> var server = http.createServer(function (req, res) {
>   res.end("Hello");
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

| Target        | Description                                             |
| ------------- | ------------------------------------------------------- |
| `make setup`  | Enable GCP APIs and create Artifact Registry repository |
| `make build`  | Build container image with Podman (linux/amd64)         |
| `make push`   | Push image to Artifact Registry                         |
| `make deploy` | Deploy to Cloud Run                                     |
| `make local`  | Run locally via ADK CLI                                 |
| `make web`    | Run locally via ADK Web UI                              |
| `make logs`   | View Cloud Run logs                                     |
| `make all`    | Full pipeline: setup + build + push + deploy            |

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
│       ├── standards_tools.py   # Standards loader (LRU cached)
│       └── token_tools.py       # Token estimation
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
- **Models**: Multi-tier Gemini via Vertex AI
  | Tier | Model | Use Case |
  |------|-------|----------|
  | `router` | gemini-2.5-flash-lite | Intent classification (lowest cost) |
  | `fast` | gemini-2.5-flash | Code generation, repo crawling |
  | `heavy` | gemini-2.5-pro | Deep analysis, code review, audits |
- **Runtime**: Python 3.11+ / FastAPI / Uvicorn
- **Deployment**: Google Cloud Run + Artifact Registry
- **Container**: Podman (Docker compatible)

## Troubleshooting

**`adk: command not found` after setup**
Re-activate your virtual environment:

```bash
source .venv/bin/activate           # macOS/Linux
.\.venv\Scripts\Activate.ps1        # Windows
```

**`PermissionDenied: 403` on Vertex AI calls**
Your account needs `roles/aiplatform.user` (or `Editor`/`Owner`) on the GCP project:

```bash
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/aiplatform.user"
```

**`Model not found` for `gemini-2.5-pro`**
Ensure `GCP_LOCATION=global` in `smart_code_builder/.env`. Preview/new models are only available on the global endpoint.

**`adk web` times out or hangs**
The first invocation loads the model and can take 20-30s. If it takes longer, check:

- Billing is enabled on the project
- `gcloud auth application-default login` was run
- `GOOGLE_GENAI_USE_VERTEXAI=true` is set (auto-configured by `config.py`)

**Setup script fails on Linux**
If you're on a distro without `apt`/`dnf`/`pacman`, install Python 3.11+, `gcloud`, and `git` manually, then re-run the script.

## License

This project is open source. See individual files for details.
