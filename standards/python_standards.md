# Python Development Standards

Best practices and coding standards for Python development based on open source community guidelines.

## Sources & References

These standards are compiled from the following open source references:

- [PEP 8 - Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Ruff - Python Linter & Formatter](https://docs.astral.sh/ruff/)
- [uv - Python Package Manager](https://docs.astral.sh/uv/)
- [pytest Documentation](https://docs.pytest.org/)
- [OpenTelemetry Python](https://opentelemetry-python-contrib.readthedocs.io/)
- [structlog - Structured Logging](https://www.structlog.org/)

## Table of Contents

- [Dependency Management](#dependency-management)
- [Code Quality Tools](#code-quality-tools)
- [Python Project Template](#python-project-template)
- [Naming Conventions](#naming-conventions)
- [Code Formatting Standards](#code-formatting-standards)
- [Import Standards](#import-standards)
- [Docstring Standards](#docstring-standards)
- [Language Features](#language-features)
- [Type Hints](#type-hints)
- [Logging Standards](#logging-standards)
- [Observability and Telemetry](#observability-and-telemetry)
- [Error Handling](#error-handling)
- [API Development Best Practices](#api-development-best-practices)
- [Testing Standards](#testing-standards)

---

## Dependency Management

Use **uv** as the primary package manager and `pyproject.toml` as the single source of truth for project metadata and dependencies.

### Why uv

uv is a Rust-based package manager that is 10-100x faster than pip/poetry for dependency resolution. It provides a single binary with built-in Python version management and native monorepo support.

### pyproject.toml as Source of Truth

Every Python project must have a `pyproject.toml` defining all metadata and dependencies:

```toml
[project]
name = "service-name"
version = "0.1.0"
description = "Service description"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115.0",
    "httpx>=0.28.0",
    "pydantic>=2.10.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.25.0",
    "pytest-cov>=6.0.0",
    "ruff>=0.9.0",
    "mypy>=1.14.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Dependency Management Workflow

```bash
# Install uv (one-time)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create new project
uv init project-name
cd project-name

# Add dependencies
uv add fastapi httpx pydantic

# Add dev dependencies
uv add --group dev pytest ruff mypy

# Install all dependencies
uv sync

# Update all dependencies
uv lock --upgrade

# Run a command in the project environment
uv run python main.py
uv run pytest

# Pin Python version (.python-version)
uv python pin 3.12
```

### Version Pinning Rules

- **Direct dependencies**: Use minimum version constraints (`>=0.115.0`)
- **Critical security packages**: Pin exact versions (`==2.10.5`)
- **Lock file**: Always commit `uv.lock` for reproducible builds
- **Python version**: Pin with `.python-version` file, managed by uv

---

## Code Quality Tools

### Ruff (Linter + Formatter)

Use **Ruff** as the unified linter and formatter. It replaces pylint, flake8, black, isort, and more in a single Rust-based tool.

```toml
# pyproject.toml
[tool.ruff]
target-version = "py312"
line-length = 88
indent-width = 4

[tool.ruff.lint]
select = [
    "E",     # pycodestyle errors
    "W",     # pycodestyle warnings
    "F",     # pyflakes
    "I",     # isort
    "B",     # flake8-bugbear
    "C4",    # flake8-comprehensions
    "UP",    # pyupgrade
    "SIM",   # flake8-simplify
    "TCH",   # flake8-type-checking
    "RUF",   # ruff-specific rules
]
fixable = ["ALL"]

[tool.ruff.lint.isort]
known-first-party = ["myproject"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true
```

```bash
# Lint code
uv run ruff check .

# Lint and auto-fix
uv run ruff check --fix .

# Format code
uv run ruff format .

# Check formatting without changes
uv run ruff format --check .
```

### Type Checking with mypy

Static type checking is mandatory for public APIs:

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

```bash
# Run type checks
uv run mypy src/

# Check specific module
uv run mypy src/services/
```

### Pre-commit Hooks

Configure pre-commit for automatic quality checks:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.14.0
    hooks:
      - id: mypy
        additional_dependencies: []
```

```bash
# Install pre-commit hooks
uv run pre-commit install

# Run on all files
uv run pre-commit run --all-files
```

---

## Python Project Template

### Recommended Project Layout

```
project-name/
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── main.py
│       ├── config.py
│       ├── services/
│       │   └── __init__.py
│       ├── models/
│       │   └── __init__.py
│       └── utils/
│           └── __init__.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_main.py
├── pyproject.toml
├── uv.lock
├── .python-version
├── .pre-commit-config.yaml
├── Dockerfile
└── README.md
```

---

## Naming Conventions

Follow PEP 8 and Google Python Style Guide naming conventions.

### Module and Package Names

Use `lower_with_under` format:

```python
# Good
import string_utils
import user_service
from database import connection_pool

# Bad
import StringUtils
import UserService
```

**Rules:**
- Always use `.py` extension
- Never use dashes in filenames: `my_module.py` not `my-module.py`
- Internal modules: prefix with underscore: `_internal_utils.py`

### Class Names

Use `CapWords` (PascalCase):

```python
# Public classes
class UserManager:
    pass

class DatabaseConnection:
    pass

# Internal classes
class _InternalCache:
    pass

# Exception classes end with "Error"
class ValidationError(Exception):
    pass
```

### Function and Method Names

Use `lower_with_under`:

```python
# Public functions
def calculate_total(items):
    pass

def fetch_user_data(user_id):
    pass

# Internal functions
def _validate_input(data):
    pass
```

### Constants

Use `CAPS_WITH_UNDER` for module-level constants:

```python
MAX_CONNECTIONS = 100
DEFAULT_TIMEOUT = 30
API_BASE_URL = "https://api.example.com"

# Internal constants
_MAX_RETRY_ATTEMPTS = 3
```

### Variables

Use `lower_with_under` for all variables:

```python
user_count = 0
total_amount = 100.50
error_messages = []
```

### Names to Avoid

- Single characters except: `i`, `j`, `k` (loop counters), `e` (exceptions), `f` (file handles)
- Dashes in any names
- `__double_leading_and_trailing_underscore__` (reserved for Python)
- Type-inclusive names: `user_dict`, `name_list` (redundant with type hints)

```python
# Bad
def process(d, l, s):
    pass

# Good
def process(data, limit, status):
    pass
```

---

## Code Formatting Standards

Ruff enforces formatting automatically. These are the rules it follows:

### Line Length

**Maximum: 88 characters per line** (Ruff/Black standard)

```python
# Good: fits within 88 characters
result = calculate_total(items, tax_rate, discount)

# Good: use implicit line joining with parentheses
result = calculate_total(
    items, tax_rate, discount,
    shipping_fee, handling_fee, insurance,
)

# Good: break long strings
message = (
    "This is a very long message that would exceed "
    "the line limit if written on a single line"
)
```

**Exceptions:**
- Long imports
- URLs in comments
- Long string constants without whitespace

### Indentation

**4 spaces per level** (never tabs):

```python
def process_data(items):
    for item in items:
        if item.valid:
            process(item)
        else:
            log_error(item)
```

**Hanging indents:**

```python
# Aligned with opening delimiter
result = some_function(argument_one, argument_two,
                       argument_three, argument_four)

# 4-space hanging indent (preferred)
result = some_function(
    argument_one, argument_two,
    argument_three, argument_four,
)
```

### Blank Lines

- **Two blank lines** between top-level definitions (functions, classes)
- **One blank line** between method definitions within a class
- **No blank line** after `def` or `class` statement

### Whitespace Rules

```python
# No whitespace inside parentheses/brackets/braces
spam(ham[1], {"eggs": 2}, [])

# No whitespace before comma, semicolon, or colon
if x == 4:
    print(x, y)

# Single space around binary operators
x = 1
result = x + y

# No space around = for keyword arguments
def func(a, b=None, c=0):
    pass

# Space when type annotation present
def func(a: int, b: int = 0) -> int:
    pass
```

### Trailing Commas

Use trailing commas when closing bracket is on a separate line:

```python
items = [
    "apple",
    "banana",
    "cherry",
]

# Single-element tuple requires trailing comma
singleton = ("hello",)
```

---

## Import Standards

### Import Format

Import packages and modules; import individual names only from `typing` and `collections.abc`:

```python
# Good
import os
import sys
from typing import Any

from myproject.utils import helper_module
from myproject.database import connection
```

### Import Grouping

Group imports in this order with blank lines between:

```python
"""Module docstring."""

# 1. Future imports
from __future__ import annotations

# 2. Standard library
import os
import sys
from pathlib import Path

# 3. Third-party imports
import httpx
from fastapi import FastAPI
from pydantic import BaseModel

# 4. Local application imports
from myproject.utils import helper
from myproject.database import connection
```

**Within each group: sorted lexicographically** (Ruff handles this automatically with `isort` rules).

### Import Guidelines

- Use `import x` for packages and modules
- Use `from x import y` where x is a package and y is a module
- Use `from x import y as z` for naming conflicts or long names
- Standard abbreviations are acceptable: `import numpy as np`
- **No relative imports**: always use full package path

```python
# Bad
from . import sibling
from .. import parent

# Good
from myproject.module import sibling
from myproject import parent
```

---

## Docstring Standards

Use Google-style docstrings per PEP 257.

### Format

Use `"""` (triple double-quotes). Summary line max 88 characters:

```python
def function(arg):
    """Summary line (one physical line).

    Extended description providing additional context,
    behavior details, and edge cases.

    Args:
        arg: Description of arg.

    Returns:
        Description of return value.
    """
```

### Module Docstrings

Every module should have a docstring:

```python
"""User authentication and authorization module.

Provides functions for user authentication, session management,
and role-based access control.

Typical usage:

    user = authenticate_user(email, password)
    if has_permission(user, "admin"):
        perform_admin_action()
"""

import logging
```

### Function Docstrings

Required for public API and non-trivial functions:

```python
def fetch_user(user_id: str, timeout: int = 30) -> dict:
    """Fetches user data from the database.

    Retrieves complete user profile including metadata.
    Results are cached for 5 minutes.

    Args:
        user_id: The unique identifier for the user.
        timeout: Maximum wait time in seconds. Defaults to 30.

    Returns:
        Dictionary with keys 'name', 'email', and 'id'.

    Raises:
        ValueError: If user_id is empty or invalid.
        TimeoutError: If database query exceeds timeout.
    """
```

### Class Docstrings

Document class purpose and public attributes:

```python
class User:
    """Represents a user in the system.

    Encapsulates user information and provides methods
    for authentication and authorization.

    Attributes:
        username: The user's unique username.
        email: The user's email address.
        role: User role for authorization.
    """

    def __init__(self, username: str, email: str):
        """Initializes User with username and email.

        Args:
            username: Unique username for the user.
            email: Valid email address.
        """
        self.username = username
        self.email = email
```

### Generators

Use `Yields:` instead of `Returns:`:

```python
def read_lines(filename: str) -> Iterator[str]:
    """Reads file line by line.

    Args:
        filename: Path to file to read.

    Yields:
        Each line from the file with newline stripped.
    """
```

---

## Language Features

### Default Argument Values

**Never use mutable objects as defaults:**

```python
# Bad: mutable default (BUG!)
def append_to_list(item, my_list=[]):
    my_list.append(item)
    return my_list

# Good: use None
def append_to_list(item, my_list=None):
    if my_list is None:
        my_list = []
    my_list.append(item)
    return my_list
```

### Comprehensions

Use for simple cases only:

```python
# Good: simple comprehension
squares = [x**2 for x in range(10)]
even_squares = [x**2 for x in range(10) if x % 2 == 0]

# Bad: too complex
result = [x + y for x in range(10) for y in range(10) if x > y]

# Good: use regular loop for complex logic
result = []
for x in range(10):
    for y in range(10):
        if x > y:
            result.append(x + y)
```

### Context Managers

Use `with` for resource management:

```python
# Good
with open("file.txt") as f:
    contents = f.read()

# Good: multiple context managers
with open("input.txt") as fin, open("output.txt", "w") as fout:
    fout.write(fin.read())
```

### Dataclasses

Prefer dataclasses over plain classes for data containers:

```python
from dataclasses import dataclass, field


@dataclass
class User:
    name: str
    email: str
    age: int = 0
    tags: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Config:
    """Immutable configuration."""
    host: str
    port: int = 8080
```

### Match Statements (Python 3.10+)

Use structural pattern matching for complex conditionals:

```python
match command:
    case "quit":
        sys.exit(0)
    case "hello" | "hi":
        print("Hello!")
    case str(s) if s.startswith("/"):
        handle_path(s)
    case _:
        print(f"Unknown command: {command}")
```

### Walrus Operator (`:=`)

Use assignment expressions to reduce repetition:

```python
# Good: avoid calling function twice
if (n := len(data)) > 10:
    print(f"Processing {n} items")

# Good: in while loops
while chunk := file.read(8192):
    process(chunk)
```

---

## Type Hints

Use modern Python 3.12+ type annotation syntax.

### Built-in Generic Types

Use lowercase built-in types (no imports from `typing` needed):

```python
# Good: modern syntax (Python 3.10+)
def process(items: list[str]) -> dict[str, int]:
    pass

names: list[str] = []
mapping: dict[str, int] = {}
coordinates: tuple[float, float] = (0.0, 0.0)
unique: set[str] = set()

# Bad: old typing imports
from typing import List, Dict, Tuple, Set
def process(items: List[str]) -> Dict[str, int]:
    pass
```

### Union Types

Use `|` syntax instead of `Union` or `Optional`:

```python
# Good: modern union syntax (Python 3.10+)
def find_user(user_id: str) -> User | None:
    pass

value: str | int = "hello"

# Bad: old syntax
from typing import Optional, Union
def find_user(user_id: str) -> Optional[User]:
    pass
```

### Type Aliases

Use the `type` statement (Python 3.12+):

```python
# Good: Python 3.12+ type alias
type UserId = str
type Callback = Callable[[str, int], bool]
type JSON = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

# Alternative for Python 3.10-3.11
from typing import TypeAlias
UserId: TypeAlias = str
```

### TypeVar and Generics

```python
# Python 3.12+ syntax
def first[T](items: list[T]) -> T:
    return items[0]

class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()
```

### Protocol (Structural Typing)

Use Protocol for duck typing:

```python
from typing import Protocol


class Renderable(Protocol):
    def render(self) -> str: ...


def display(item: Renderable) -> None:
    print(item.render())
```

### Annotate Public APIs

All public functions and methods must have type annotations:

```python
# Good: fully annotated public function
def calculate_discount(
    price: float,
    discount_percent: float,
    min_price: float = 0.0,
) -> float:
    return max(price * (1 - discount_percent / 100), min_price)
```

---

## Logging Standards

Use **structlog** for structured JSON logging in production.

### Basic Setup

```python
import structlog

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()
```

### Usage

```python
# Bind context for request lifecycle
logger = logger.bind(request_id=request_id, user_id=user.id)

# Log with structured data
logger.info("user_login", method="oauth", provider="google")
logger.warning("rate_limit_approaching", current=95, limit=100)
logger.error("payment_failed", order_id=order.id, reason=str(e))
```

### Log Levels

| Level | Use Case |
|-------|----------|
| `DEBUG` | Detailed diagnostic information |
| `INFO` | Business events, request lifecycle |
| `WARNING` | Unexpected but recoverable situations |
| `ERROR` | Failures requiring attention |
| `CRITICAL` | System-level failures |

### Guidelines

- Always use structured key-value pairs, not formatted strings
- Include correlation IDs (request_id, trace_id) in all log entries
- Never log sensitive data (passwords, tokens, PII)
- Use `logger.exception()` to automatically include stack traces

---

## Observability and Telemetry

### Three Pillars

1. **Logs**: Structured JSON via structlog
2. **Metrics**: Prometheus-format via `prometheus_client`
3. **Traces**: Distributed tracing via OpenTelemetry

### Health Checks

Every service must expose health endpoints:

```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def health():
    """Liveness probe - is the process running?"""
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    """Readiness probe - can the service handle traffic?"""
    # Check database, cache, external dependencies
    return {"status": "ready", "checks": {"db": "ok", "cache": "ok"}}
```

### Metrics

Expose key RED metrics (Rate, Errors, Duration):

```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration",
    ["method", "endpoint"],
)
```

### OpenTelemetry Tracing

```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Auto-instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# Manual spans for business logic
tracer = trace.get_tracer(__name__)

async def process_order(order_id: str) -> Order:
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)
        order = await fetch_order(order_id)
        await validate_order(order)
        return await submit_order(order)
```

---

## Error Handling

### Use Built-in Exceptions

Prefer built-in exceptions for common error cases:

```python
# Good: built-in exceptions
def get_item(items: list, index: int):
    if index < 0 or index >= len(items):
        raise IndexError(f"Index {index} out of range [0, {len(items)})")
    return items[index]

def parse_config(data: str) -> dict:
    if not data:
        raise ValueError("Config data cannot be empty")
    return json.loads(data)
```

### Custom Exceptions

Create custom exceptions inheriting from appropriate base classes:

```python
class ServiceError(Exception):
    """Base exception for service errors."""

    def __init__(self, message: str, code: str | None = None):
        super().__init__(message)
        self.code = code


class NotFoundError(ServiceError):
    """Raised when a requested resource is not found."""


class ValidationError(ServiceError):
    """Raised when input validation fails."""
```

### Exception Handling Rules

```python
# Good: specific exceptions, minimal try block
try:
    user = fetch_user(user_id)
except ConnectionError:
    logger.error("database_unreachable", user_id=user_id)
    raise
except KeyError:
    raise NotFoundError(f"User {user_id} not found")

# Bad: bare except
try:
    do_something()
except:  # Never do this
    pass

# Bad: catching Exception too broadly
try:
    do_something()
except Exception:
    pass  # Swallows all errors

# Good: re-raise after logging
try:
    result = process(data)
except ProcessingError as e:
    logger.error("processing_failed", error=str(e))
    raise
```

### Assertions

Use `assert` only in tests, never for runtime validation:

```python
# Bad: assert for user input validation
def set_age(age: int) -> None:
    assert age > 0, "Age must be positive"  # Removed with -O flag!

# Good: explicit validation
def set_age(age: int) -> None:
    if age <= 0:
        raise ValueError("Age must be positive")
```

---

## API Development Best Practices

### FastAPI with Pydantic

```python
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

app = FastAPI(title="User Service", version="1.0.0")


class CreateUserRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    age: int = Field(ge=0, le=150)


class UserResponse(BaseModel):
    id: str
    name: str
    email: str


@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(request: CreateUserRequest) -> UserResponse:
    user = await user_service.create(request)
    return UserResponse(id=user.id, name=user.name, email=user.email)


@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str) -> UserResponse:
    user = await user_service.get(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found",
        )
    return UserResponse(id=user.id, name=user.name, email=user.email)
```

### Request Validation

Use Pydantic models for all request/response schemas. Leverage Field validators:

```python
from pydantic import BaseModel, field_validator


class OrderRequest(BaseModel):
    items: list[str]
    quantity: int

    @field_validator("items")
    @classmethod
    def items_not_empty(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("Order must contain at least one item")
        return v

    @field_validator("quantity")
    @classmethod
    def quantity_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("Quantity must be positive")
        return v
```

---

## Testing Standards

### Framework: pytest

Use **pytest** as the testing framework with the Arrange-Act-Assert (AAA) pattern.

### Project Setup

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --tb=short --strict-markers"
markers = [
    "slow: marks tests as slow",
    "integration: marks integration tests",
]

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
show_missing = true
fail_under = 80
```

### Test Structure

```python
"""Tests for user service."""

import pytest
from myproject.services.user import UserService


class TestUserService:
    """Tests for UserService."""

    def test_create_user_with_valid_data(self, user_service: UserService):
        """Creates a user when given valid input data."""
        # Arrange
        name = "Alice"
        email = "alice@example.com"

        # Act
        user = user_service.create(name=name, email=email)

        # Assert
        assert user.name == name
        assert user.email == email
        assert user.id is not None

    def test_create_user_with_empty_name_raises_error(self, user_service: UserService):
        """Raises ValueError when name is empty."""
        with pytest.raises(ValueError, match="Name cannot be empty"):
            user_service.create(name="", email="alice@example.com")
```

### Fixtures

Use fixtures for test setup and dependency injection:

```python
# conftest.py
import pytest
from myproject.database import Database
from myproject.services.user import UserService


@pytest.fixture
def db():
    """Provides a test database connection."""
    database = Database(":memory:")
    database.create_tables()
    yield database
    database.close()


@pytest.fixture
def user_service(db: Database) -> UserService:
    """Provides a UserService with test database."""
    return UserService(db=db)
```

### Parametrize

Use `@pytest.mark.parametrize` for data-driven tests:

```python
@pytest.mark.parametrize(
    ("input_value", "expected"),
    [
        ("hello", "HELLO"),
        ("world", "WORLD"),
        ("", ""),
        ("123", "123"),
    ],
)
def test_uppercase(input_value: str, expected: str):
    assert input_value.upper() == expected


@pytest.mark.parametrize(
    ("a", "b", "expected"),
    [
        (1, 2, 3),
        (0, 0, 0),
        (-1, 1, 0),
    ],
)
def test_add(a: int, b: int, expected: int):
    assert add(a, b) == expected
```

### Async Tests

```python
import pytest


@pytest.mark.asyncio
async def test_fetch_user(user_service: UserService):
    user = await user_service.fetch("user-123")
    assert user.name == "Alice"
```

### Coverage

Target 80-90% coverage on core business logic:

```bash
# Run tests with coverage
uv run pytest --cov=src --cov-report=term-missing

# Generate HTML report
uv run pytest --cov=src --cov-report=html

# Fail if coverage drops below threshold
uv run pytest --cov=src --cov-fail-under=80
```

### Testing Guidelines

- Name tests descriptively: `test_<function>_<scenario>_<expected_result>`
- One assertion per test (or closely related assertions)
- Use fixtures for setup, not setUp/tearDown methods
- Mock external dependencies (HTTP, database) but prefer integration tests for critical paths
- Use `pytest.raises` for expected exceptions
- Use `pytest.approx` for floating point comparisons
- Mark slow tests with `@pytest.mark.slow`
