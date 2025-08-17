#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Find PyCharm installation
find_pycharm_config() {
    PYCHARM_CONFIG=""
    JETBRAINS_DIR="$HOME/Library/Application Support/JetBrains"
    
    # Check for specific versions in order of preference
    for version in PyCharm2025.2 PyCharm2025.1 PyCharm2024.3 PyCharm2024.2 PyCharm2024.1; do
        if [ -d "$JETBRAINS_DIR/$version" ]; then
            PYCHARM_CONFIG="$JETBRAINS_DIR/$version"
            print_success "Found PyCharm configuration: $version"
            break
        fi
    done
    
    if [ -z "$PYCHARM_CONFIG" ]; then
        print_error "Could not find PyCharm configuration directory"
        print_error "Please make sure PyCharm is installed"
        print_error "Looking in: $JETBRAINS_DIR"
        print_error "Available directories:"
        ls -la "$JETBRAINS_DIR" 2>/dev/null || print_error "Cannot access JetBrains directory"
        exit 1
    fi
}

# Create template directory
create_template_directory() {
    TEMPLATE_DIR="$PYCHARM_CONFIG/projectTemplates/StandardizedFullStack"
    mkdir -p "$TEMPLATE_DIR"
    print_success "Created template directory: $TEMPLATE_DIR"
}

# Create template files
create_template_files() {
    print_status "Creating template files..."
    
    # Create temporary project structure
    TEMP_PROJECT="/tmp/pycharm_template_project"
    rm -rf "$TEMP_PROJECT"
    mkdir -p "$TEMP_PROJECT"
    
    # Create project structure
    mkdir -p "$TEMP_PROJECT"/{frontend,backend,backend/app,.github/workflows}
    
    # Determine source directory (script's directory)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_DIR="$SCRIPT_DIR/template-files"
    
    # Copy standardized configuration files
    cp "$SOURCE_DIR/.pre-commit-config.yaml" "$TEMP_PROJECT/"
    cp "$SOURCE_DIR/setup-dev.sh" "$TEMP_PROJECT/"
    cp "$SOURCE_DIR/DEVELOPMENT.md" "$TEMP_PROJECT/"
    cp "$SCRIPT_DIR/NEW_PROJECT_SETUP.md" "$TEMP_PROJECT/"
    
    # Backend configuration
    cp "$SOURCE_DIR/backend/requirements-dev.txt" "$TEMP_PROJECT/backend/"
    cp "$SOURCE_DIR/backend/pyproject.toml" "$TEMP_PROJECT/backend/"
    cp "$SOURCE_DIR/backend/.flake8" "$TEMP_PROJECT/backend/"
    
    # GitHub workflows
    cp "$SOURCE_DIR/.github/workflows/quality-standardized.yml" "$TEMP_PROJECT/.github/workflows/"
    
    # Create package.json with template variables
    cat > "$TEMP_PROJECT/package.json" << 'EOF'
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "A standardized full-stack application with professional CI/CD",
  "main": "index.js",
  "scripts": {
    "dev": "concurrently \"npm run frontend:dev\" \"npm run backend:dev\"",
    "build": "npm run frontend:build",
    "start": "cd backend && uvicorn app.main:app --host 0.0.0.0 --port 8001",
    "test": "cd frontend && npm test",
    "test:watch": "cd frontend && npm run test:watch",
    "test:coverage": "cd frontend && npm run test:coverage",
    "test:e2e": "cd frontend && npm run test:e2e",
    "lint": "npm run frontend:lint && npm run backend:lint",
    "lint:fix": "npm run frontend:lint:fix && npm run backend:lint:fix",
    "type-check": "npm run frontend:type-check && npm run backend:type-check",
    "quality-check": "npm run lint && npm run type-check && npm test",
    "frontend:dev": "cd frontend && npm run dev",
    "frontend:build": "cd frontend && npm run build",
    "frontend:test": "cd frontend && npm test",
    "frontend:lint": "cd frontend && npm run lint",
    "frontend:lint:fix": "cd frontend && npm run lint:fix",
    "frontend:type-check": "cd frontend && npx tsc --noEmit",
    "backend:dev": "cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8001 --log-level debug",
    "backend:install": "cd backend && pip install -r requirements.txt",
    "backend:install:dev": "cd backend && pip install -r requirements-dev.txt",
    "backend:test": "cd backend && pytest",
    "backend:lint": "cd backend && flake8 && black --check . && isort --check-only .",
    "backend:lint:fix": "cd backend && black . && isort .",
    "backend:type-check": "cd backend && mypy .",
    "precommit:install": "pre-commit install",
    "precommit:run": "pre-commit run --all-files",
    "precommit:run-changed": "pre-commit run",
    "setup:dev": "./setup-dev.sh",
    "setup:hooks": "npm run precommit:install && echo 'Pre-commit hooks installed successfully!'"
  },
  "keywords": ["standardized", "full-stack", "ci-cd"],
  "author": "${USER_NAME}",
  "license": "ISC",
  "devDependencies": {
    "concurrently": "^8.2.2"
  }
}
EOF

    # Create basic backend structure
    cat > "$TEMP_PROJECT/backend/requirements.txt" << 'EOF'
fastapi>=0.110.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
pydantic-settings>=2.3.0
python-multipart>=0.0.6
httpx>=0.27.0
python-dotenv>=1.0.0
EOF

    cat > "$TEMP_PROJECT/backend/app/__init__.py" << 'EOF'
"""${PROJECT_NAME} Backend Application"""
EOF

    cat > "$TEMP_PROJECT/backend/app/main.py" << 'EOF'
"""
${PROJECT_NAME} FastAPI Application

This is a standardized FastAPI application with:
- Professional CI/CD pipeline
- Pre-commit hooks with auto-fix
- Comprehensive testing setup
- Quality gates and security scanning
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from typing import Dict, Any

# Initialize FastAPI app
app = FastAPI(
    title="${PROJECT_NAME} API",
    description="A standardized FastAPI application with professional development workflow",
    version="1.0.0"
)

# CORS configuration for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],  # React dev servers
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class HealthResponse(BaseModel):
    status: str
    message: str
    version: str

class InfoResponse(BaseModel):
    name: str
    description: str
    features: list[str]

# Routes
@app.get("/", response_model=InfoResponse)
async def root() -> InfoResponse:
    """Root endpoint with API information."""
    return InfoResponse(
        name="${PROJECT_NAME} API",
        description="A standardized full-stack application",
        features=[
            "FastAPI backend with async support",
            "Professional CI/CD pipeline",
            "Pre-commit hooks with auto-fix",
            "Comprehensive testing setup",
            "Quality gates and security scanning",
            "Docker containerization ready",
            "Type-safe with Pydantic models"
        ]
    )

@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        message="API is running successfully",
        version="1.0.0"
    )

@app.get("/api/info")
async def api_info() -> Dict[str, Any]:
    """API information and available endpoints."""
    return {
        "endpoints": {
            "GET /": "API information and features",
            "GET /health": "Health check endpoint",
            "GET /api/info": "This endpoint - API documentation",
            "GET /docs": "Interactive API documentation (Swagger UI)",
            "GET /redoc": "Alternative API documentation (ReDoc)"
        },
        "development": {
            "setup": "Run ./setup-dev.sh to initialize development environment",
            "commands": {
                "npm run dev": "Start development servers (frontend + backend)",
                "npm run quality-check": "Run all quality checks",
                "npm run lint:fix": "Auto-fix linting issues",
                "npm test": "Run all tests"
            }
        },
        "documentation": [
            "README.md - Project overview and setup",
            "DEVELOPMENT.md - Development workflow guide",
            "NEW_PROJECT_SETUP.md - Setup instructions for new developers"
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        log_level="info"
    )
EOF

    # Create basic frontend structure
    mkdir -p "$TEMP_PROJECT/frontend/src"
    
    cat > "$TEMP_PROJECT/frontend/package.json" << 'EOF'
{
  "name": "${PROJECT_NAME}-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@typescript-eslint/eslint-plugin": "^8.15.0",
    "@typescript-eslint/parser": "^8.15.0",
    "@vitejs/plugin-react": "^4.3.4",
    "eslint": "^9.15.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "eslint-plugin-react-refresh": "^0.4.14",
    "typescript": "~5.6.2",
    "vite": "^6.0.1",
    "vitest": "^2.1.8"
  }
}
EOF

    # Create README
    cat > "$TEMP_PROJECT/README.md" << 'EOF'
# ${PROJECT_NAME}

A standardized full-stack application with professional development workflow.

## 🚀 Quick Start

```bash
# Set up development environment (one command!)
./setup-dev.sh

# Start development servers
npm run dev

# Run quality checks
npm run quality-check
```

## 📋 Features

✅ **Instant Local Feedback** (< 10 seconds)
- Pre-commit hooks with auto-fix
- TypeScript compilation checks  
- ESLint with automatic fixing
- Python code formatting (Black, isort)

✅ **Professional CI/CD Pipeline**
- Frontend quality gates
- Backend quality gates
- Security vulnerability scanning
- Automated testing

✅ **Complete Development Workflow**
- One-command environment setup
- Standardized npm scripts
- Comprehensive documentation
- Cross-platform compatibility

## 🛠️ Development

### Available Commands

```bash
npm run dev              # Start both frontend and backend
npm run build           # Build for production  
npm run test            # Run all tests
npm run lint:fix        # Fix all auto-fixable issues
npm run quality-check   # Run all quality checks
npm run setup:dev       # Set up development environment
```

### Project Structure

```
${PROJECT_NAME}/
├── frontend/           # React TypeScript frontend
├── backend/            # FastAPI Python backend
├── .github/workflows/  # CI/CD pipeline
├── setup-dev.sh       # Development setup script
└── DEVELOPMENT.md     # Detailed workflow guide
```

## 📚 Documentation

- `DEVELOPMENT.md` - Complete development workflow guide
- `NEW_PROJECT_SETUP.md` - Setup instructions for new developers
- `/docs` - Interactive API documentation (when server is running)

## 🎯 Quality Standards

This project maintains high quality standards with:

- **TypeScript**: Static type checking
- **ESLint**: Code quality and consistency  
- **Prettier**: Code formatting
- **Black/isort**: Python code formatting
- **MyPy**: Python static type checking
- **pytest**: Comprehensive testing
- **Pre-commit hooks**: Automated quality checks

## 🚀 Deployment

The project is configured for easy deployment to:
- Docker containers
- Cloud platforms (Google Cloud Run, AWS, Azure)
- Traditional VPS/dedicated servers

See deployment documentation for platform-specific instructions.

---

Generated from the Standardized Project Template 🎉
EOF

    # Create gitignore
    cat > "$TEMP_PROJECT/.gitignore" << 'EOF'
# Dependencies
node_modules/
*/node_modules/

# Production builds
dist/
build/
*/dist/
*/build/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
*/.env
*/.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
*/venv/
*/__pycache__/

# Testing
coverage/
.coverage
.pytest_cache/
.vitest/
test-results/
playwright-report/
*/coverage/
*/.pytest_cache/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
logs/

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port
EOF

    # Make setup script executable
    chmod +x "$TEMP_PROJECT/setup-dev.sh"
    
    print_success "Created template project structure"
}

# Create PyCharm template configuration
create_pycharm_config() {
    print_status "Creating PyCharm template configuration..."
    
    # Create template.xml
    cat > "$TEMPLATE_DIR/template.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<template>
  <name>Standardized Full-Stack Project</name>
  <description>A professional full-stack project template with React frontend, FastAPI backend, and comprehensive CI/CD pipeline</description>
  <option name="AUTHOR" default="${USER}"/>
  <option name="PROJECT_NAME" default="${PROJECT_NAME}"/>
  <option name="PACKAGE_NAME" default="${PACKAGE_NAME}"/>
</template>
EOF

    # Create description.html
    cat > "$TEMPLATE_DIR/description.html" << 'EOF'
<html>
<head>
    <title>Standardized Full-Stack Project Template</title>
</head>
<body>
    <h2>🚀 Standardized Full-Stack Project</h2>
    
    <p>A professional project template that includes:</p>
    
    <h3>✅ Complete Development Workflow</h3>
    <ul>
        <li><strong>One-Command Setup</strong>: <code>./setup-dev.sh</code> initializes everything</li>
        <li><strong>Instant Local Feedback</strong>: Pre-commit hooks with auto-fix (&lt;10 seconds)</li>
        <li><strong>Professional CI/CD Pipeline</strong>: Quality gates, testing, security scanning</li>
        <li><strong>Comprehensive Documentation</strong>: Complete workflow guides</li>
    </ul>
    
    <h3>🎯 Technology Stack</h3>
    <ul>
        <li><strong>Frontend</strong>: React 18 + TypeScript + Vite</li>
        <li><strong>Backend</strong>: FastAPI + Python 3.11+ + Pydantic</li>
        <li><strong>Quality Tools</strong>: ESLint, Prettier, Black, isort, MyPy</li>
        <li><strong>Testing</strong>: Vitest, pytest, Playwright E2E</li>
        <li><strong>CI/CD</strong>: GitHub Actions with quality gates</li>
    </ul>
    
    <h3>🛠️ After Creation</h3>
    <ol>
        <li>Run <code>./setup-dev.sh</code> to initialize the development environment</li>
        <li>Use <code>npm run dev</code> to start development servers</li>
        <li>Run <code>npm run quality-check</code> to verify everything works</li>
        <li>Check <code>DEVELOPMENT.md</code> for complete workflow guide</li>
    </ol>
    
    <p><strong>Features included:</strong></p>
    <ul>
        <li>Pre-commit hooks with auto-fixing</li>
        <li>TypeScript compilation checking</li>
        <li>Python code formatting and linting</li>
        <li>Security vulnerability scanning</li>
        <li>Cross-browser E2E testing setup</li>
        <li>Docker containerization ready</li>
        <li>Professional documentation</li>
    </ul>
    
    <p><em>This template provides a production-ready foundation for rapid, high-quality development.</em></p>
</body>
</html>
EOF

    # Create the template zip file
    cd "$TEMP_PROJECT"
    zip -r "$TEMPLATE_DIR/template.zip" . -x "*.git*" "*.DS_Store*"
    
    print_success "Created PyCharm template configuration"
}

# Main execution
main() {
    echo "🚀 Creating PyCharm Standardized Project Template..."
    echo "=================================================="
    echo ""
    
    find_pycharm_config
    create_template_directory
    create_template_files
    create_pycharm_config
    
    # Cleanup
    rm -rf "$TEMP_PROJECT"
    
    echo ""
    echo "=================================================="
    print_success "🎉 PyCharm template created successfully!"
    echo ""
    echo -e "${BLUE}Template Location:${NC}"
    echo "$TEMPLATE_DIR"
    echo ""
    echo -e "${BLUE}How to Use:${NC}"
    echo "1. Restart PyCharm"
    echo "2. File → New Project"
    echo "3. Look for 'Standardized Full-Stack Project' template"
    echo "4. Create your project and run ./setup-dev.sh"
    echo ""
    echo -e "${BLUE}Template Features:${NC}"
    echo "✓ Complete React + FastAPI project structure"
    echo "✓ Professional CI/CD pipeline"
    echo "✓ Pre-commit hooks with auto-fix"
    echo "✓ Comprehensive quality tools"
    echo "✓ One-command development setup"
    echo "✓ Complete documentation"
    echo ""
    print_success "Happy coding! 🚀"
}

# Run main function
main "$@"