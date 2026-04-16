# GEMINI.md - BWIA Smart Code Builder

This project is an intelligent code assistance system built with **Google ADK (Agent Development Kit)** and powered by **Gemini** models on **Vertex AI**. It provides a multi-agent orchestration to improve, create, modernize, and audit code following open-source best practices.

## Project Overview

- **Purpose**: Automate code reviews, legacy migrations, code generation, and repository audits.
- **Tech Stack**: 
  - **Framework**: Google ADK (Agent Development Kit).
  - **Runtime**: Python 3.11+.
  - **Models**: Multi-tier Gemini (Flash-Lite for routing, Flash for simple tasks, Pro for deep analysis).
  - **Deployment**: Google Cloud Run + Artifact Registry (managed via Makefile).
  - **Tooling**: `uv` or `pip` for dependencies, `ruff` for linting/formatting, `mypy` for type checking.

## Building and Running

### Prerequisites
- Python 3.11+
- Google Cloud SDK (`gcloud`)
- Authenticated with `gcloud auth application-default login`

### Installation
1.  **Clone & Setup**:
    ```bash
    bash scripts/setup.sh
    ```
    This script creates a virtual environment, installs dependencies, and configures the initial `.env`.

2.  **Environment Configuration**:
    Ensure `smart_code_builder/.env` (or project root `.env`) has the following:
    ```bash
    GCP_PROJECT_ID=your-project-id
    GCP_LOCATION=global
    ROUTER_MODEL=gemini-2.0-flash-lite
    FAST_MODEL=gemini-2.0-flash
    HEAVY_MODEL=gemini-2.0-pro
    ```

### Running Locally
- **CLI Mode**: `adk run smart_code_builder`
- **Web UI**: `adk web smart_code_builder` (accessible at http://localhost:8000)

### Deployment (Cloud Run)
The project uses a `Makefile` for deployment:
- `make setup`: Enable GCP APIs and create Artifact Registry.
- `make build`: Build the container image (requires Podman/Docker).
- `make deploy`: Deploy to Google Cloud Run.
- `make all`: Full setup, build, and deploy pipeline.

## Core Architecture

The system follows a **Router -> Sub-agent** pattern:

1.  **Smart Router (`smart_code_builder`)**: Uses `gemini-2.0-flash-lite` to classify user intent and delegate to specialized agents.
2.  **Improve Agent (`improve_code`)**: Uses `gemini-2.0-pro` to refactor existing code.
3.  **Create Agent (`create_code`)**: Uses `gemini-2.0-flash` to generate code from scratch.
4.  **Modernize Agent (`modernize_code`)**: Uses `gemini-2.0-pro` to migrate legacy code (e.g., JS to TS).
5.  **Audit Agent (`audit_repo`)**: A pipeline that clones a GitHub repo and generates a security/quality report.

### Key Directories
- `smart_code_builder/`: Core logic and agent definitions.
- `smart_code_builder/_tools/`: Specialized tools for language detection, repository operations, and coding standards.
- `standards/`: Markdown files containing curated coding standards for Python and TypeScript/JavaScript.

## Development Conventions

- **Python Standards**: Follow [PEP 8](https://peps.python.org/pep-0008/) and [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html).
- **TypeScript Standards**: Follow [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html).
- **Type Safety**: Strict typing is mandatory (Python 3.12+ features, TypeScript strict mode).
- **Tools Implementation**: Tools should be stateless, documented with docstrings, and placed in `smart_code_builder/_tools/`.
- **Instruction Engineering**: Agents use detailed markdown-formatted instructions stored in their respective files (e.g., `improve_agent.py`).
- **Dependency Management**: Prefer `uv` for speed and `pyproject.toml` for metadata.

## Important Files
- `smart_code_builder/agent.py`: Main entry point and router definition.
- `smart_code_builder/model.py`: Model factory for different performance tiers.
- `smart_code_builder/config.py`: Centralized environment configuration.
- `Makefile`: Build and deployment automation.
- `Dockerfile`: Cloud Run container definition.
