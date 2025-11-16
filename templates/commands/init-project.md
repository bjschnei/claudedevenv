# Project Initialization Command

You are helping the user initialize a new full-featured project with Docker, development tools, and a complete project structure based on their tech stack choices.

## Overview

This command will:
1. Interactively gather project requirements
2. Detect required languages from stack choices
3. Generate a complete project structure with Docker setup
4. Create development tools (dev-shell.sh, Makefile)
5. Set up documentation and configuration files

## PHASE 1: Gather Project Requirements

Ask the user the following questions **one at a time** using the AskUserQuestion tool:

### Question 1: Project Name
Ask for the project name (will be used for directory name, container names, etc.)

### Question 2: Backend Framework
**Question:** "Which backend framework would you like to use?"
**Options:**
- None
- FastAPI (Python)
- Flask (Python)
- Django (Python)
- Express (Node.js/TypeScript)
- NestJS (TypeScript)
- Go (stdlib net/http)
- Go (Gin framework)
- Go (Echo framework)

### Question 3: Frontend Framework
**Question:** "Which frontend framework would you like to use?"
**Options:**
- None
- Streamlit (Python)
- React (TypeScript)
- Next.js (TypeScript)
- Vue.js (TypeScript)
- Svelte (TypeScript)

### Question 4: Database
**Question:** "Which database would you like to use?"
**Options:**
- None
- PostgreSQL
- MySQL
- MongoDB
- Redis
- SQLite

### Question 5: AI Providers
**Question:** "Which AI providers would you like to integrate?"
**Options (multiSelect: true):**
- None
- OpenAI
- Anthropic
- LangChain/LangGraph

### Question 6: Architecture (only if both backend AND frontend are selected)
**Question:** "How would you like to structure your services?"
**Options:**
- Monorepo (both frontend and backend in same repo/container)
- Separate services (separate Docker containers for each)

### Question 7: Python Version (only if Python is detected from choices)
**Question:** "Which Python version would you like to use?"
**Options:**
- Python 3.11
- Python 3.12
- Python 3.13

### Question 8: Backend Port
Ask for backend port (default suggestion based on framework, e.g., 8000 for FastAPI, 3000 for Express, 8080 for Go)

### Question 9: Frontend Port (only if frontend is selected)
Ask for frontend port (default suggestion based on framework, e.g., 8501 for Streamlit, 3000 for React)

### Question 10: Database Port (only if database is selected)
Ask for database port (default suggestion based on database, e.g., 5432 for PostgreSQL, 3306 for MySQL, 27017 for MongoDB)

## PHASE 2: Research Compatible Versions

Before generating any files, research the latest compatible versions for the chosen stack:

### Version Research Steps:

1. **For Node.js/TypeScript projects**, use Bash to query npm registry:
   ```bash
   # Get latest versions
   REACT_VERSION=$(npm view react version)
   TYPESCRIPT_VERSION=$(npm view typescript version)
   REACT_SCRIPTS_VERSION=$(npm view react-scripts version)

   # Check for deprecations
   npm view create-react-app deprecated
   npm view react-scripts deprecated

   # Check TypeScript peer dependency for react-scripts
   npm view "react-scripts@$REACT_SCRIPTS_VERSION" peerDependencies.typescript
   ```

2. **For Python projects**, use Bash to query pip:
   ```bash
   # Get latest versions
   pip index versions fastapi 2>/dev/null | head -1
   pip index versions uvicorn 2>/dev/null | head -1
   ```

3. **For Go projects**, use Bash:
   ```bash
   # Check latest Go version
   go version
   ```

4. **Check for known compatibility issues:**
   - If `react-scripts` is selected, verify TypeScript compatibility
   - If react-scripts requires TypeScript 3.x-4.x but latest is 5.x, use TypeScript ^4.9.5
   - Check if Create React App is deprecated → recommend Vite instead
   - For FastAPI, ensure uvicorn version matches
   - For database drivers, check compatibility with chosen database version

5. **Use WebSearch for current best practices** (optional but recommended):
   ```
   Search: "[framework] recommended versions 2025"
   Search: "[framework] deprecation status"
   ```

6. **Store researched versions in variables** for use in file generation:
   - `REACT_VERSION`
   - `TYPESCRIPT_VERSION` (adjusted for compatibility)
   - `REACT_SCRIPTS_VERSION`
   - `FASTAPI_VERSION`
   - `UVICORN_VERSION`
   - `GO_VERSION`
   - `PYTHON_VERSION` (from user choice, but verify availability)
   - `NODE_VERSION` (default to 20-alpine for Docker)

7. **Display research findings:**
   ```
   📊 Version Research Results:

   [If React selected]
   - React: [version]
   - TypeScript: [version] (adjusted for react-scripts compatibility)
   - react-scripts: [version]
   - ⚠️ Note: Create React App is deprecated. Consider using Vite for new projects.

   [If FastAPI selected]
   - FastAPI: [version]
   - Uvicorn: [version]
   - Python: [user_choice]

   [If Go selected]
   - Go: [version]

   Would you like to proceed with these versions?
   ```

### Compatibility Rules:

**React + TypeScript:**
- If `react-scripts@5.x` is latest AND requires TypeScript `^3.2.1 || ^4`:
  - Use TypeScript `^4.9.5` (latest 4.x)
  - OR recommend switching to Vite
- If `react-scripts@6.x` supports TypeScript 5.x:
  - Use latest TypeScript

**FastAPI + Python:**
- FastAPI 0.100+ requires Python 3.7+
- FastAPI 0.110+ requires Python 3.8+
- Ensure uvicorn version matches FastAPI version

**Database Drivers:**
- PostgreSQL: use `psycopg2-binary` or `asyncpg`
- MongoDB: use `motor` for async, `pymongo` for sync
- MySQL: use `aiomysql` for async

## PHASE 3: Validate and Confirm

Display a summary of all choices **including researched versions** and ask for confirmation:
```
Project Configuration Summary:
- Project Name: [name]
- Backend: [framework] on port [port]
- Frontend: [framework] on port [port]
- Database: [database] on port [port]
- AI Providers: [providers]
- Architecture: [monorepo/separate]
- Languages: [detected languages]

Versions (researched):
[List all researched versions]

⚠️ Warnings/Notes:
[Any deprecation warnings or compatibility notes]

Is this correct?
```

If not confirmed, ask which settings to change and repeat the relevant questions.

## PHASE 4: Create Project Structure

Based on the user's choices and **researched versions**, create the following files and directories:

### Always Create:
1. **README.md** - Minimal project overview with quick start instructions
2. **CLAUDE.md** - Minimal project context for Claude Code
3. **.gitignore** - Comprehensive ignore patterns for detected languages
4. **.dockerignore** - Docker build context ignore patterns
5. **.env.example** - Template environment variables (no actual secrets)
6. **Makefile** - Common development commands (dev, test, build, deploy, clean)
7. **dev-shell.sh** - Helper script to access development container

### Docker Files:
8. **Dockerfile** (or multiple if separate services) - Multi-stage build (base → development → production)
9. **docker-compose.yml** - Development configuration with volume mounts
10. **docker-compose.prod.yml** - Production configuration

### Language-Specific Files:

**If Python:**
- **requirements.txt** - Minimal dependencies for chosen frameworks
- **pytest.ini** - Test configuration with markers (asyncio, integration, unit)
- **setup.py** or **pyproject.toml** - Package configuration

**If Go:**
- **go.mod** - Go module file
- **go.sum** - Dependency checksums

**If Node.js/TypeScript:**
- **package.json** - Dependencies and scripts **using researched versions**
- **package-lock.json** - Generate after package.json by running `npm install`
- **tsconfig.json** - TypeScript configuration (if TypeScript)
- **.eslintrc.js** - Linting configuration
- **.prettierrc** - Code formatting

**IMPORTANT for React projects:**
- Use the researched `TYPESCRIPT_VERSION` (e.g., ^4.9.5 if react-scripts 5.x)
- Always run `npm install` after creating package.json to generate package-lock.json
- Check for peer dependency conflicts and create `.npmrc` with `legacy-peer-deps=true` if needed
- Update Dockerfile to copy `.npmrc` if it exists

### Source Directory Structure:

Create `src/` directory with subdirectories based on choices:

**Backend subdirectories (if backend selected):**
- `api/` - API routes and endpoints
- `services/` - Business logic services
- `models/` - Data models/schemas
- `config/` - Configuration management
- `utils/` - Utility functions

**Additional Python subdirectories (if LangChain/LangGraph):**
- `workflows/` - LangGraph workflows
- `agents/` - AI agent implementations

**Frontend subdirectories (if frontend selected):**
- `ui/` (Python) or `components/` (React/etc.)
- `pages/` (if applicable)
- `styles/` (if applicable)

**Database subdirectories (if database selected):**
- `database/` - Database connection, migrations, schemas

**Golang structure (if Go backend):**
- `cmd/` - Main applications
- `internal/` - Private application code
- `pkg/` - Public libraries
- `api/` - API definitions

**Node.js/TypeScript structure (if Node backend):**
- `src/routes/` - Route handlers
- `src/controllers/` - Business logic
- `src/models/` - Data models
- `src/middleware/` - Express middleware
- `src/config/` - Configuration

### Tests Directory:
- `tests/` - Test files (structure mirrors src/)

### Starter Files:

Create minimal working starter files for each service:

**Python/FastAPI:**
```python
# src/main.py
from fastapi import FastAPI

app = FastAPI(title="[Project Name]")

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {"message": "Hello from [Project Name]"}
```

**Python/Streamlit:**
```python
# src/ui/app.py
import streamlit as st

st.set_page_config(page_title="[Project Name]", layout="wide")

st.title("[Project Name]")
st.write("Welcome to your new Streamlit app!")
```

**Go/stdlib:**
```go
// cmd/server/main.go
package main

import (
    "encoding/json"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/", rootHandler)

    log.Println("Server starting on :[PORT]")
    log.Fatal(http.ListenAndServe(":[PORT]", nil))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"message": "Hello from [Project Name]"})
}
```

**TypeScript/Express:**
```typescript
// src/index.ts
import express from 'express';

const app = express();
const PORT = process.env.PORT || [PORT];

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/', (req, res) => {
  res.json({ message: 'Hello from [Project Name]' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**React (CRA/Vite):**
```typescript
// src/App.tsx
import { useState } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="App">
      <h1>[Project Name]</h1>
      <p>Welcome to your new app!</p>
      <button onClick={() => setCount(count + 1)}>
        Count: {count}
      </button>
    </div>
  );
}

export default App;
```

**Next.js:**
```typescript
// src/pages/index.tsx (Next.js)
export default function Home() {
  return (
    <div>
      <h1>[Project Name]</h1>
      <p>Welcome to your new Next.js app!</p>
    </div>
  );
}
```

**IMPORTANT for React:**
- Do NOT import React in components (use new JSX transform)
- Only import hooks/functions you need: `import { useState, useEffect } from 'react';`

## PHASE 5: Generate Docker Configuration

**IMPORTANT:** Use the researched `NODE_VERSION`, `PYTHON_VERSION`, and `GO_VERSION` in all Dockerfiles.

### Dockerfile Structure (Multi-stage):

**Python Example:**
```dockerfile
# syntax=docker/dockerfile:1.5
FROM python:[version]-slim AS base

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Development stage
FROM base AS development
RUN pip install --no-cache-dir \
    pytest \
    pytest-asyncio \
    black \
    ruff
WORKDIR /app
CMD ["/bin/bash"]

# Production stage
FROM base AS production
COPY src/ ./src/
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "[PORT]"]
```

**Go Example:**
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

# Development stage
FROM golang:1.21-alpine AS development
WORKDIR /app
RUN apk add --no-cache bash git
CMD ["/bin/bash"]

# Production stage
FROM alpine:latest AS production
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /server .
CMD ["./server"]
```

**Node.js/TypeScript Example:**
```dockerfile
# syntax=docker/dockerfile:1.5
FROM node:[NODE_VERSION] AS base

WORKDIR /app

# Copy package files and .npmrc if it exists
COPY package*.json ./
COPY .npmrc* ./

# Install dependencies
RUN npm ci

# Development stage
FROM base AS development

# Install dev dependencies
RUN npm install

# Copy source code
COPY . .

# Expose port
EXPOSE [PORT]

# Start development server
CMD ["npm", "run", "dev"]

# Build stage (for production)
FROM base AS builder

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:[NODE_VERSION] AS production

WORKDIR /app

# Copy built assets from builder
COPY --from=builder /app/build ./build
COPY --from=builder /app/package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Expose port
EXPOSE [PORT]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:[PORT] || exit 1

# Start application
CMD ["npm", "start"]
```

### docker-compose.yml (Development):

Adapt based on architecture choice (monorepo vs separate services):

**Separate Services:**
```yaml
services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    container_name: [project]-backend
    ports:
      - "[backend_port]:[backend_port]"
    volumes:
      - ./src:/app/src
      - ./tests:/app/tests
    environment:
      - PORT=[backend_port]
    restart: unless-stopped

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
      target: development
    container_name: [project]-frontend
    ports:
      - "[frontend_port]:[frontend_port]"
    volumes:
      - ./src:/app/src
    environment:
      - PORT=[frontend_port]
      - BACKEND_URL=http://backend:[backend_port]
    depends_on:
      - backend
    restart: unless-stopped

  # Add database service if selected
  db:
    image: postgres:15
    container_name: [project]-db
    ports:
      - "[db_port]:[db_port]"
    environment:
      - POSTGRES_USER=[project]
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=[project]
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  db-data:

networks:
  default:
    name: [project]-network
```

**Monorepo:**
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    container_name: [project]-app
    ports:
      - "[backend_port]:[backend_port]"
      - "[frontend_port]:[frontend_port]"
    volumes:
      - ./src:/app/src
      - ./tests:/app/tests
    environment:
      - BACKEND_PORT=[backend_port]
      - FRONTEND_PORT=[frontend_port]
    restart: unless-stopped
```

### docker-compose.prod.yml:

Similar structure but using production targets, no volume mounts, and production-ready configurations.

## PHASE 6: Generate package.json with Researched Versions

For React/Node.js projects, generate package.json using the researched versions:

```json
{
  "name": "[project-name]",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^[REACT_VERSION]",
    "react-dom": "^[REACT_VERSION]",
    "react-scripts": "[REACT_SCRIPTS_VERSION]",
    "axios": "^[AXIOS_VERSION]",
    "typescript": "[TYPESCRIPT_VERSION]"
  },
  "scripts": {
    "dev": "react-scripts start",
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test"
  },
  "eslintConfig": {
    "extends": ["react-app"]
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  },
  "devDependencies": {
    "@types/react": "^[REACT_TYPES_VERSION]",
    "@types/react-dom": "^[REACT_DOM_TYPES_VERSION]",
    "@types/node": "^[NODE_TYPES_VERSION]"
  }
}
```

**After creating package.json:**
1. Run `npm install` to generate package-lock.json
2. If peer dependency conflicts occur:
   - Create `.npmrc` with `legacy-peer-deps=true`
   - Re-run `npm install`
3. Verify package-lock.json was created successfully

## PHASE 7: Generate Development Tools

### dev-shell.sh:
```bash
#!/bin/bash
# Helper script to access the development container shell

set -e

CONTAINER_NAME="[project]-[service]"  # or just [project] for monorepo

echo "🐳 Accessing development container..."

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠️  Development container is not running."
    echo "Starting it now with: docker-compose up -d"
    docker-compose up -d
    echo "⏳ Waiting for container to be ready..."
    sleep 2
fi

echo "✅ Connecting to shell..."
docker exec -it ${CONTAINER_NAME} bash

echo "👋 Exited development container"
```

### Makefile:
```makefile
.PHONY: help dev dev-shell test build clean deploy logs stop

help:
	@echo "Available commands:"
	@echo "  make dev        - Start development environment"
	@echo "  make dev-shell  - Access development container shell"
	@echo "  make test       - Run tests"
	@echo "  make build      - Build production images"
	@echo "  make deploy     - Deploy to production"
	@echo "  make logs       - View logs"
	@echo "  make stop       - Stop all services"
	@echo "  make clean      - Clean up containers and volumes"

dev:
	docker-compose up -d
	@echo "✅ Development environment started"
	@echo "Backend: http://localhost:[backend_port]"
	@echo "Frontend: http://localhost:[frontend_port]"

dev-shell:
	./dev-shell.sh

test:
	docker-compose exec [service] [test_command]

build:
	docker-compose -f docker-compose.prod.yml build

deploy:
	docker-compose -f docker-compose.prod.yml up -d

logs:
	docker-compose logs -f

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker system prune -f
```

## PHASE 8: Generate Documentation

### README.md:
```markdown
# [Project Name]

## Quick Start

### Development

1. Start the development environment:
   ```bash
   make dev
   ```

2. Access the application:
   - Backend: http://localhost:[backend_port]
   - Frontend: http://localhost:[frontend_port]

3. Access development shell:
   ```bash
   make dev-shell
   ```

### Testing

```bash
make test
```

### Production

```bash
make build
make deploy
```

## Project Structure

- `src/` - Source code
- `tests/` - Test files
- `docker-compose.yml` - Development configuration
- `docker-compose.prod.yml` - Production configuration

## Environment Variables

Copy `.env.example` to `.env` and update with your values.
```

### CLAUDE.md:
```markdown
# Claude Code Guidelines

## Project Overview

[Project Name] is a [brief description based on stack choices].

## Technology Stack

- Backend: [framework] ([language])
- Frontend: [framework] ([language])
- Database: [database]
- AI: [providers]

## Development

### Running the Application

```bash
make dev
```

### Project Structure

- `src/[subdirectories]` - [descriptions]

## Docker

- Multi-stage Dockerfile with development and production targets
- docker-compose.yml for development (hot reload)
- docker-compose.prod.yml for production

## Key Patterns

[Add patterns specific to the chosen stack]
```

### .env.example:
```bash
# Application
PROJECT_NAME=[project]
ENVIRONMENT=development

# Backend
BACKEND_PORT=[backend_port]
[Backend-specific env vars]

# Frontend
FRONTEND_PORT=[frontend_port]
[Frontend-specific env vars]

# Database
DB_HOST=db
DB_PORT=[db_port]
DB_NAME=[project]
DB_USER=[project]
DB_PASSWORD=changeme

# AI Providers
[If OpenAI: OPENAI_API_KEY=your_key_here]
[If Anthropic: ANTHROPIC_API_KEY=your_key_here]
```

## PHASE 9: Final Steps

1. Make dev-shell.sh executable:
   ```bash
   chmod +x dev-shell.sh
   ```

2. Display completion message:
   ```
   ✅ Project '[Project Name]' initialized successfully!

   📁 Created files:
   - Docker setup (Dockerfile, docker-compose.yml, docker-compose.prod.yml)
   - Development tools (Makefile, dev-shell.sh)
   - Configuration (.env.example, .gitignore, .dockerignore)
   - Documentation (README.md, CLAUDE.md)
   - Source structure (src/[subdirectories])
   - Starter files ([list key files])

   🚀 Next steps:
   1. Copy .env.example to .env and update values
   2. Run: make dev
   3. Visit: http://localhost:[ports]

   💡 Useful commands:
   - make dev       - Start development
   - make dev-shell - Access container shell
   - make test      - Run tests
   - make help      - See all commands
   ```

## Notes

### Critical Requirements:

- **Always research versions before generating files** (Phase 2)
- **Always run `npm install` after creating package.json** to generate package-lock.json
- **Always check for peer dependency conflicts** and create `.npmrc` if needed
- **Always use researched versions** in package.json, requirements.txt, go.mod
- **Always use multi-stage Dockerfiles** (base → development → production)
- **Always include health checks** in docker-compose
- **Always use volume mounts for development** (hot reload)
- **Always inform users about Docker Desktop file sharing requirement**

### Best Practices:

- Adapt directory structure to be idiomatic for each language
- Keep starter files minimal but functional
- Include sensible defaults but make everything configurable
- Warn about deprecated frameworks (e.g., Create React App)
- Recommend modern alternatives when appropriate

### Docker Desktop File Sharing:

Include in the final completion message:

```
⚠️  IMPORTANT: Docker File Sharing Configuration

For development mode to work, you must configure Docker Desktop:
1. Open Docker Desktop → Settings → Resources → File Sharing
2. Add this project's path: [full_path_to_project]
3. Click "Apply & Restart"

Without this configuration, volume mounts will fail and containers won't start.
```
