# TypeScript Development Standards

Best practices and coding standards for TypeScript development based on open source community guidelines.

## Sources & References

These standards are compiled from the following open source references:

- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [ts.dev Style Guide](https://ts.dev/style/)
- [TypeScript Style Guide by mkosir](https://mkosir.github.io/typescript-style-guide/)
- [Biome - Web Toolchain](https://biomejs.dev/)
- [Vitest - Testing Framework](https://vitest.dev/)
- [Microsoft TypeScript Coding Guidelines](https://github.com/microsoft/TypeScript/wiki/Coding-guidelines)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)

## Table of Contents

- [Dependency Management](#dependency-management)
- [Code Quality Tools](#code-quality-tools)
- [TypeScript Project Structure](#typescript-project-structure)
- [File Organization](#file-organization)
- [Import and Export Patterns](#import-and-export-patterns)
- [Naming Conventions](#naming-conventions)
- [Variables and Declarations](#variables-and-declarations)
- [Functions](#functions)
- [Classes](#classes)
- [Objects and Arrays](#objects-and-arrays)
- [Type Annotations](#type-annotations)
- [Immutability Patterns](#immutability-patterns)
- [Control Flow](#control-flow)
- [Strings and Templates](#strings-and-templates)
- [Error Handling](#error-handling)
- [Testing Standards](#testing-standards)
- [Disallowed Features](#disallowed-features)
- [Common Patterns](#common-patterns)

---

## Dependency Management

### Package Manager

Use **npm** (or **pnpm** for monorepos) for dependency management.

### File Structure

Every TypeScript project must have:

1. **`package.json`** - Project metadata and dependencies
2. **`package-lock.json`** (or `pnpm-lock.yaml`) - Locked dependency versions
3. **`tsconfig.json`** - TypeScript compiler configuration

### package.json Format

```json
{
  "name": "service-name",
  "version": "1.0.0",
  "description": "Service description",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "test": "vitest",
    "test:coverage": "vitest run --coverage",
    "check": "biome check .",
    "check:fix": "biome check --write .",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "express": "^5.0.0"
  },
  "devDependencies": {
    "@biomejs/biome": "^2.0.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.7.0",
    "vitest": "^3.0.0",
    "tsx": "^4.0.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

### Dependency Management Workflow

```bash
# Install dependencies
npm install

# Add dependency
npm install package-name

# Add dev dependency
npm install --save-dev @types/package-name

# Clean install (CI/CD)
npm ci

# Audit vulnerabilities
npm audit
npm audit fix
```

### Version Pinning Rules

- **Direct dependencies**: Use caret ranges (`^1.2.3`) for minor/patch updates
- **Security-critical packages**: Pin exact versions (`1.2.3`)
- **Lock files**: Always commit `package-lock.json`

---

## Code Quality Tools

### Option A: Biome (Recommended for new projects)

**Biome** is a Rust-based linter and formatter that replaces ESLint + Prettier in a single tool. It is 10-25x faster and requires one config file instead of multiple.

```json
// biome.json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": "warn"
      },
      "suspicious": {
        "noExplicitAny": "error"
      },
      "style": {
        "noDefaultExport": "error",
        "useConst": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "trailingCommas": "all",
      "semicolons": "always",
      "arrowParentheses": "always"
    }
  }
}
```

```bash
# Check code
npx biome check .

# Check and auto-fix
npx biome check --write .

# Format only
npx biome format --write .
```

### Option B: ESLint + Prettier (Mature ecosystem)

For projects needing framework-specific plugins (React, Angular, Vue):

```bash
# ESLint with flat config (v9+)
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Prettier
npm install --save-dev prettier
```

```javascript
// eslint.config.js (flat config)
import tsPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';

export default [
  {
    files: ['src/**/*.ts'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
    },
    rules: {
      'no-var': 'error',
      'prefer-const': 'error',
      'eqeqeq': ['error', 'always'],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': 'warn',
    },
  },
];
```

### TypeScript Compiler

All code must pass strict type checking:

```bash
# Check types without emitting
npx tsc --noEmit

# Build
npx tsc
```

---

## TypeScript Project Structure

### Organize by Feature

Structure projects by feature/domain, not by type:

```
project-name/
├── src/
│   ├── index.ts
│   ├── config.ts
│   ├── common/
│   │   ├── types.ts
│   │   ├── errors.ts
│   │   └── utils.ts
│   ├── users/
│   │   ├── user.service.ts
│   │   ├── user.model.ts
│   │   ├── user.controller.ts
│   │   ├── user.types.ts
│   │   └── __tests__/
│   │       └── user.service.test.ts
│   └── orders/
│       ├── order.service.ts
│       ├── order.model.ts
│       └── __tests__/
│           └── order.service.test.ts
├── dist/
├── package.json
├── tsconfig.json
├── biome.json
├── vitest.config.ts
└── README.md
```

### tsconfig.json Configuration

Enable strict mode with modern settings:

```json
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2024"],
    "outDir": "./dist",
    "rootDir": "./src",

    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,

    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,

    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,

    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Key strict flags explained:**
- `strict: true` enables all strict checks (~40% fewer type bugs in production)
- `exactOptionalPropertyTypes` distinguishes `undefined` from missing properties
- `verbatimModuleSyntax` enforces explicit `import type` usage
- `isolatedModules` ensures compatibility with Babel/SWC/esbuild

---

## File Organization

### File Structure Order

Every TypeScript file follows this order:

1. **Import statements**
2. **Type definitions** (if file-local)
3. **Implementation code**
4. **Exports** (if not inline)

```typescript
import { Database } from '../common/database.js';
import type { User, UserRole } from './user.types.js';

export class UserService {
  // Implementation...
}
```

### File Naming

- Use **lowercase with dashes**: `user-service.ts`, `string-utils.ts`
- Test files: `user-service.test.ts` or `user-service.spec.ts`
- Type definitions: `user.types.ts`
- Never use spaces, underscores, or PascalCase in filenames

```
user-service.ts
validation-utils.ts
http-client.ts
user.types.ts
```

---

## Import and Export Patterns

### Always Use Named Exports

**Never use default exports:**

```typescript
// Bad: default export
export default class UserService {}

// Good: named export
export class UserService {}
```

**Rationale:**
- Named exports have a canonical name
- Better IDE refactoring support
- Consistent import names across codebase
- Errors when importing non-existent symbols

### Type-Only Imports

Separate type imports from value imports for better tree-shaking:

```typescript
// Good: separate type imports
import type { User, UserRole } from './user.types.js';
import { createUser, deleteUser } from './user.service.js';

// Good: inline type imports
import { createUser, type User } from './user.service.js';
```

### Import Styles

**Named imports for specific symbols:**

```typescript
import { User, UserRole } from './user.types.js';
import { validateEmail } from '../common/validation.js';
```

**Namespace imports for large APIs:**

```typescript
import * as fs from 'node:fs';
import * as path from 'node:path';
```

### Import Organization

Group imports in this order with blank lines between:

```typescript
// 1. Node.js built-ins (with node: protocol)
import * as fs from 'node:fs';
import * as path from 'node:path';

// 2. External dependencies
import express from 'express';
import { z } from 'zod';

// 3. Internal absolute imports
import { config } from '@/config.js';

// 4. Internal relative imports
import type { User } from './user.types.js';
import { UserService } from './user.service.js';
```

---

## Naming Conventions

### Overview Table

| Category | Convention | Example |
|----------|------------|---------|
| Classes | `UpperCamelCase` | `UserService`, `HttpClient` |
| Interfaces | `UpperCamelCase` | `User`, `RequestHandler` |
| Types | `UpperCamelCase` | `UserId`, `ResponseData` |
| Functions | `lowerCamelCase` | `getUserById`, `validateEmail` |
| Variables | `lowerCamelCase` | `userName`, `isActive` |
| Parameters | `lowerCamelCase` | `userId`, `callback` |
| Properties | `lowerCamelCase` | `firstName`, `createdAt` |
| Global constants | `CONSTANT_CASE` | `MAX_RETRY_ATTEMPTS` |
| Booleans | prefix: `is`, `has`, `can`, `should` | `isActive`, `hasPermission` |
| Generics | `T` + descriptive name | `TRequest`, `TResponse` |

### Acronyms

Treat acronyms as whole words:

```typescript
// Good
class HttpClient {}           // Not HTTPClient
class XmlParser {}            // Not XMLParser
function loadHttpUrl() {}     // Not loadHTTPURL
const apiKey = '...';         // Not aPIKey
```

### No Prefix/Suffix for Visibility

```typescript
// Bad: underscore prefix
class User {
  private _id: string;
}

// Good: TypeScript visibility modifiers
class User {
  private id: string;
}
```

### No `I` Prefix for Interfaces

```typescript
// Bad
interface IUser {}
interface IUserService {}

// Good
interface User {}
interface UserService {}
```

---

## Variables and Declarations

### Use const and let, Never var

```typescript
// Good
const userName = 'Alice';
let counter = 0;

// Bad: never use var
var oldStyle = 'bad';
```

### One Variable Per Statement

```typescript
// Bad
let a = 1, b = 2, c = 3;

// Good
let a = 1;
let b = 2;
let c = 3;

// Exception: destructuring
const { name, email } = user;
const [first, second] = items;
```

### Array and Object Literals

```typescript
// Good: literals
const items = [1, 2, 3];
const empty: number[] = [];
const obj = { name: 'Alice', age: 30 };

// Bad: constructors
const items = new Array(1, 2, 3);
const obj = new Object();
```

---

## Functions

### Prefer Function Declarations

```typescript
// Good: function declaration for named functions
function getUserById(id: string): User {
  // ...
}

// Good: arrow function for callbacks
users.map((user) => user.name);

// Good: arrow function for short utilities
const double = (x: number): number => x * 2;
```

### Arrow Functions

Use concise body only when the return value is used:

```typescript
// Good: concise body, return value used
const doubled = items.map((x) => x * 2);

// Good: block body for side effects
items.forEach((item) => {
  console.log(item);
});
```

### Object Parameters for Many Arguments

```typescript
// Good: object parameter
interface CreateUserOptions {
  name: string;
  email: string;
  age?: number;
  role?: UserRole;
}

function createUser(options: CreateUserOptions): User {
  const { name, email, age = 18, role = 'user' } = options;
  // ...
}

// Avoid: too many positional parameters
function createUser(name: string, email: string, age: number, role: string): User {
  // ...
}
```

### Explicit Return Types

Always specify return types for public/exported functions:

```typescript
// Good: explicit return type
function getUserById(id: string): User | undefined {
  // ...
}

async function fetchData(url: string): Promise<Response> {
  // ...
}

// Acceptable: inferred for trivial arrow functions
const double = (x: number) => x * 2;
```

---

## Classes

### Member Organization

Order class members:

1. Static properties
2. Instance properties
3. Constructor
4. Static methods
5. Instance methods

```typescript
class UserService {
  // 1. Static properties
  private static instance: UserService;

  // 2. Instance properties
  private readonly db: Database;
  private cache: Map<string, User>;

  // 3. Constructor
  constructor(db: Database) {
    this.db = db;
    this.cache = new Map();
  }

  // 4. Static methods
  static getInstance(db: Database): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService(db);
    }
    return UserService.instance;
  }

  // 5. Instance methods
  async getUser(id: string): Promise<User> {
    // ...
  }
}
```

### Parameter Properties

Reduce boilerplate with parameter properties:

```typescript
// Good: parameter properties
class User {
  constructor(
    private readonly id: string,
    private name: string,
  ) {}
}

// Equivalent verbose version (avoid)
class User {
  private id: string;
  private name: string;

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}
```

### Readonly Properties

Mark non-reassigned properties as `readonly`:

```typescript
class Config {
  constructor(
    readonly host: string,
    readonly port: number,
    readonly debug: boolean = false,
  ) {}
}
```

### Use TypeScript Visibility, Not `#private`

```typescript
// Good: TypeScript private
class Service {
  private db: Database;
}

// Bad: ECMAScript #private
class Service {
  #db: Database;
}
```

### Always Use Parentheses When Instantiating

```typescript
// Good
const user = new User();
const date = new Date();

// Bad
const user = new User;
```

---

## Objects and Arrays

### Spread Syntax

```typescript
// Array spread
const copy = [...original];
const merged = [...arr1, ...arr2];

// Object spread
const updated = { ...user, age: 31 };
```

### Destructuring

```typescript
// Object destructuring
const { name, email } = user;
const { name, ...rest } = user;

// Array destructuring
const [first, second] = items;
const [first, ...rest] = items;

// Rename during destructuring
const { name: userName } = user;
```

---

## Type Annotations

### Prefer Type Inference When Obvious

```typescript
// Good: inference is clear
const name = 'Alice';
const count = 42;
const items = [1, 2, 3];

// Good: annotate when narrowing or clarifying
const users = new Map<string, User>();
const result: UserResponse = await fetchUser(id);
```

### Never Use `any`

Use `unknown` instead of `any` for truly unknown types:

```typescript
// Bad
function parse(data: any): void {}

// Good
function parse(data: unknown): void {
  if (typeof data === 'string') {
    // data is narrowed to string
  }
}
```

### Never Use Wrapper Types

```typescript
// Bad
const name: String = 'Alice';
const count: Number = 42;
const valid: Boolean = true;

// Good
const name: string = 'Alice';
const count: number = 42;
const valid: boolean = true;
```

### Prefer `type` Over `interface`

Use `type` by default. Use `interface` only when declaration merging is needed:

```typescript
// Good: type alias
type User = {
  id: string;
  name: string;
  email: string;
};

type UserId = string;
type Callback = (result: User) => void;

// Acceptable: interface for declaration merging
interface WindowExtensions {
  customProperty: string;
}
```

### Discriminated Unions

Prefer discriminated unions over optional properties:

```typescript
// Bad: optional properties
type Shape = {
  kind: string;
  radius?: number;
  width?: number;
  height?: number;
};

// Good: discriminated union
type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'rectangle'; width: number; height: number }
  | { kind: 'square'; side: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'rectangle':
      return shape.width * shape.height;
    case 'square':
      return shape.side ** 2;
  }
}
```

### Utility Types

Leverage built-in utility types:

```typescript
// Partial: all properties optional
function updateUser(id: string, data: Partial<User>): User {
  // ...
}

// Pick / Omit: select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;
type UserWithoutEmail = Omit<User, 'email'>;

// Record: typed dictionary
type UserMap = Record<string, User>;

// Required: all properties required
type CompleteUser = Required<User>;

// Readonly: all properties readonly
type FrozenUser = Readonly<User>;
```

### Type-Safe Constants with `as const satisfies`

```typescript
const ROUTES = {
  home: '/',
  users: '/users',
  settings: '/settings',
} as const satisfies Record<string, string>;

// Type is narrowed: typeof ROUTES.home is '/' (not string)
```

### Template Literal Types

```typescript
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiRoute = 'users' | 'orders' | 'products';
type ApiEndpoint = `/${ApiRoute}`;

type EventName = `on${Capitalize<string>}`;
```

### Avoid Enums, Prefer Union Types

```typescript
// Avoid: enum
enum UserRole {
  ADMIN = 'admin',
  USER = 'user',
  GUEST = 'guest',
}

// Prefer: union type (better tree-shaking)
type UserRole = 'admin' | 'user' | 'guest';

// Or: const object for runtime access
const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  GUEST: 'guest',
} as const;

type UserRole = (typeof USER_ROLES)[keyof typeof USER_ROLES];
```

---

## Immutability Patterns

### Readonly Types

```typescript
// Readonly object
type Config = Readonly<{
  host: string;
  port: number;
  debug: boolean;
}>;

// ReadonlyArray
function processItems(items: ReadonlyArray<string>): void {
  // items.push('x');  // Error: push does not exist on ReadonlyArray
  const copy = [...items, 'x'];  // OK: create new array
}

// Readonly Map/Set
type UserCache = ReadonlyMap<string, User>;
type UniqueIds = ReadonlySet<string>;
```

### Const Assertions

```typescript
// Narrow to literal types
const COLORS = ['red', 'green', 'blue'] as const;
// Type: readonly ['red', 'green', 'blue']

const CONFIG = {
  maxRetries: 3,
  timeout: 5000,
  endpoints: ['api', 'auth'],
} as const;
// All properties are deeply readonly with literal types
```

### Prefer Immutable Operations

```typescript
// Good: return new data
function addItem(items: ReadonlyArray<string>, item: string): string[] {
  return [...items, item];
}

function updateUser(user: Readonly<User>, updates: Partial<User>): User {
  return { ...user, ...updates };
}

// Bad: mutate in place
function addItem(items: string[], item: string): void {
  items.push(item);  // Side effect
}
```

---

## Control Flow

### Always Use Braces

```typescript
// Good
if (condition) {
  doSomething();
}

// Bad
if (condition) doSomething();
```

### Use Strict Equality

```typescript
// Good
if (value === 'hello') {}
if (value !== undefined) {}

// Bad
if (value == 'hello') {}
if (value != undefined) {}

// Exception: comparing to null covers both null and undefined
if (value == null) {}
```

### Exhaustive Switch Statements

```typescript
type Status = 'pending' | 'active' | 'inactive';

function handleStatus(status: Status): string {
  switch (status) {
    case 'pending':
      return 'Waiting...';
    case 'active':
      return 'Running';
    case 'inactive':
      return 'Stopped';
    default: {
      const _exhaustive: never = status;
      throw new Error(`Unhandled status: ${_exhaustive}`);
    }
  }
}
```

### Prefer `for...of` Over `for...in`

```typescript
// Good: for...of for arrays
for (const item of items) {
  process(item);
}

// Good: Object methods for objects
for (const [key, value] of Object.entries(config)) {
  console.log(`${key}: ${value}`);
}

// Bad: for...in on arrays
for (const index in items) {
  // index is string, not number!
}
```

### Nullish Coalescing and Optional Chaining

```typescript
// Good: nullish coalescing
const name = user.name ?? 'Anonymous';
const port = config.port ?? 3000;

// Good: optional chaining
const city = user.address?.city;
const first = items?.[0];
const result = callback?.();

// Bad: logical OR for defaults (falsy trap)
const name = user.name || 'Anonymous';  // '' becomes 'Anonymous'
const port = config.port || 3000;        // 0 becomes 3000
```

---

## Strings and Templates

### Use Single Quotes

```typescript
// Good
const name = 'Alice';
const greeting = 'Hello, World!';

// Bad
const name = "Alice";
```

### Template Literals for Interpolation

```typescript
// Good: template literal
const message = `Hello, ${name}! You have ${count} items.`;

// Bad: string concatenation
const message = 'Hello, ' + name + '! You have ' + count + ' items.';
```

### Multi-line Strings

```typescript
// Good: template literal
const query = `
  SELECT *
  FROM users
  WHERE active = true
  ORDER BY name
`;
```

---

## Error Handling

### Always Throw Error Objects

```typescript
// Good
throw new Error('Something went wrong');
throw new TypeError('Expected string');

// Bad
throw 'Something went wrong';
throw 42;
throw { message: 'error' };
```

### Custom Error Classes

```typescript
class AppError extends Error {
  constructor(
    message: string,
    readonly code: string,
    readonly statusCode: number = 500,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`, 'NOT_FOUND', 404);
    this.name = 'NotFoundError';
  }
}

class ValidationError extends AppError {
  constructor(
    message: string,
    readonly fields: Record<string, string>,
  ) {
    super(message, 'VALIDATION_ERROR', 400);
    this.name = 'ValidationError';
  }
}
```

### Type-Safe Catch Blocks

```typescript
try {
  await fetchData(url);
} catch (error: unknown) {
  if (error instanceof NotFoundError) {
    // Handle not found
    return null;
  }
  if (error instanceof Error) {
    logger.error('Fetch failed', { message: error.message });
    throw error;
  }
  // Unknown error type
  throw new Error(`Unknown error: ${String(error)}`);
}
```

### Prefer Result Types for Expected Failures

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

function parseJson(input: string): Result<unknown> {
  try {
    return { success: true, data: JSON.parse(input) };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error : new Error(String(error)),
    };
  }
}

// Usage
const result = parseJson(rawData);
if (result.success) {
  console.log(result.data);
} else {
  console.error(result.error.message);
}
```

---

## Testing Standards

### Framework: Vitest

Use **Vitest** as the testing framework. It is 2-10x faster than Jest, has native ESM and TypeScript support, and zero-config for Vite projects.

### Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.types.ts'],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
});
```

### Test Structure (AAA Pattern)

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { UserService } from './user.service.js';

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService(mockDb);
  });

  it('should return user when user exists', async () => {
    // Arrange
    const userId = 'user-123';

    // Act
    const user = await service.getUser(userId);

    // Assert
    expect(user).toBeDefined();
    expect(user.id).toBe(userId);
  });

  it('should throw NotFoundError when user does not exist', async () => {
    // Arrange
    const userId = 'nonexistent';

    // Act & Assert
    await expect(service.getUser(userId)).rejects.toThrow(NotFoundError);
  });

  it('should create user with valid data', async () => {
    // Arrange
    const data = { name: 'Alice', email: 'alice@example.com' };

    // Act
    const user = await service.createUser(data);

    // Assert
    expect(user.name).toBe('Alice');
    expect(user.email).toBe('alice@example.com');
    expect(user.id).toBeDefined();
  });
});
```

### Mocking

```typescript
import { describe, it, expect, vi } from 'vitest';

// Mock modules
vi.mock('./database.js', () => ({
  Database: vi.fn().mockImplementation(() => ({
    query: vi.fn(),
    close: vi.fn(),
  })),
}));

// Mock functions
const mockFetch = vi.fn();

// Spy on methods
const spy = vi.spyOn(service, 'validate');
expect(spy).toHaveBeenCalledWith(data);
```

### Test Naming

Use descriptive names that read as sentences:

```typescript
// Good: describes behavior
it('should return empty array when no users match filter', () => {});
it('should throw ValidationError when email is invalid', () => {});
it('should retry 3 times before failing', () => {});

// Bad: vague or implementation-focused
it('test1', () => {});
it('works correctly', () => {});
it('calls the database', () => {});
```

### Running Tests

```bash
# Run all tests
npx vitest

# Run in watch mode
npx vitest --watch

# Run specific file
npx vitest src/users/user.service.test.ts

# Run with coverage
npx vitest run --coverage

# Run with UI
npx vitest --ui
```

### Testing Guidelines

- Test behavior, not implementation details
- Keep functions pure to minimize mocking
- One concept per test
- Use descriptive test names: `should <expected> when <condition>`
- Don't test third-party libraries
- Don't mandate 100% coverage; focus on critical paths (80%+ target)
- Use `beforeEach` for per-test setup, `beforeAll` for expensive shared setup
- Avoid snapshot tests unless there is a strong rationale

---

## Disallowed Features

| Feature | Why | Alternative |
|---------|-----|-------------|
| `var` | Function-scoped, hoisting bugs | `const` / `let` |
| `any` | Defeats type safety | `unknown` |
| Default exports | Ambiguous imports, harder refactoring | Named exports |
| `#private` fields | Not interoperable with TypeScript's type system | `private` keyword |
| `namespace` | Outdated, use ES modules | ES module imports |
| `require()` | CommonJS, not type-safe | `import` statements |
| `eval()` | Security risk | Structured alternatives |
| `debugger` | Must not reach production | Breakpoints in IDE |
| Wrapper types (`String`, `Number`, `Boolean`) | Confusing boxing behavior | Primitive types |
| `const enum` | Emit issues with isolatedModules | Union types or plain `enum` |
| `enum` (discouraged) | Poor tree-shaking, runtime overhead | Union types / `as const` objects |
| Modifying built-in prototypes | Breaks third-party code | Utility functions |

---

## Common Patterns

### Singleton

```typescript
class Database {
  private static instance: Database;

  private constructor(private readonly connectionString: string) {}

  static getInstance(connectionString: string): Database {
    if (!Database.instance) {
      Database.instance = new Database(connectionString);
    }
    return Database.instance;
  }
}
```

### Builder

```typescript
class QueryBuilder {
  private table = '';
  private conditions: string[] = [];
  private limit?: number;

  from(table: string): this {
    this.table = table;
    return this;
  }

  where(condition: string): this {
    this.conditions.push(condition);
    return this;
  }

  take(limit: number): this {
    this.limit = limit;
    return this;
  }

  build(): string {
    let query = `SELECT * FROM ${this.table}`;
    if (this.conditions.length > 0) {
      query += ` WHERE ${this.conditions.join(' AND ')}`;
    }
    if (this.limit !== undefined) {
      query += ` LIMIT ${this.limit}`;
    }
    return query;
  }
}

// Usage
const query = new QueryBuilder()
  .from('users')
  .where('active = true')
  .take(10)
  .build();
```

### Repository Pattern

```typescript
interface Repository<T> {
  findById(id: string): Promise<T | undefined>;
  findAll(): Promise<T[]>;
  create(data: Omit<T, 'id'>): Promise<T>;
  update(id: string, data: Partial<T>): Promise<T>;
  delete(id: string): Promise<void>;
}

class UserRepository implements Repository<User> {
  constructor(private readonly db: Database) {}

  async findById(id: string): Promise<User | undefined> {
    return this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async findAll(): Promise<User[]> {
    return this.db.query('SELECT * FROM users');
  }

  async create(data: Omit<User, 'id'>): Promise<User> {
    const id = crypto.randomUUID();
    await this.db.execute('INSERT INTO users VALUES (?, ?, ?)', [
      id,
      data.name,
      data.email,
    ]);
    return { id, ...data };
  }

  async update(id: string, data: Partial<User>): Promise<User> {
    // ...
  }

  async delete(id: string): Promise<void> {
    await this.db.execute('DELETE FROM users WHERE id = ?', [id]);
  }
}
```
