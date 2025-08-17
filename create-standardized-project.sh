#!/bin/bash

# Quick project setup script
# Usage: ./create-standardized-project.sh [project-name] [project-type]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME=${1:-"my-new-project"}
PROJECT_TYPE=${2:-"fullstack"}

echo -e "${BLUE}🚀 Creating standardized project: $PROJECT_NAME${NC}"
echo ""

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize basic structure based on project type
case $PROJECT_TYPE in
    "fullstack")
        echo -e "${BLUE}Setting up full-stack project structure...${NC}"
        mkdir -p frontend backend .github/workflows
        
        # Basic package.json
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A standardized full-stack application",
  "main": "index.js",
  "scripts": {
    "dev": "echo 'Please run ./setup-new-project.sh to complete setup'"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF

        # Basic frontend structure
        mkdir -p frontend/src
        cat > frontend/package.json << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "echo 'Frontend development server'",
    "build": "echo 'Frontend build'",
    "test": "echo 'Frontend tests'",
    "lint": "echo 'Frontend linting'",
    "lint:fix": "echo 'Frontend lint fix'"
  }
}
EOF

        # Basic backend structure
        mkdir -p backend/app
        cat > backend/requirements.txt << EOF
fastapi>=0.110.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
python-multipart>=0.0.6
EOF

        cat > backend/app/__init__.py << EOF
# Backend application package
EOF

        cat > backend/app/main.py << EOF
from fastapi import FastAPI

app = FastAPI(title="$PROJECT_NAME API")

@app.get("/")
def root():
    return {"message": "Hello from $PROJECT_NAME!"}

@app.get("/health")
def health():
    return {"status": "healthy"}
EOF
        ;;
        
    "frontend")
        echo -e "${BLUE}Setting up frontend-only project structure...${NC}"
        mkdir -p src .github/workflows
        
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A standardized frontend application",
  "type": "module",
  "scripts": {
    "dev": "echo 'Please run ./setup-new-project.sh to complete setup'"
  }
}
EOF
        ;;
        
    "backend")
        echo -e "${BLUE}Setting up backend-only project structure...${NC}"
        mkdir -p app .github/workflows
        
        cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A standardized backend application",
  "scripts": {
    "dev": "echo 'Please run ./setup-new-project.sh to complete setup'"
  }
}
EOF

        cat > requirements.txt << EOF
fastapi>=0.110.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
EOF
        ;;
esac

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy the setup script
cp "$SCRIPT_DIR/setup-new-project.sh" .
chmod +x setup-new-project.sh

# Copy documentation
cp "$SCRIPT_DIR/NEW_PROJECT_SETUP.md" .

echo ""
echo -e "${GREEN}✅ Project '$PROJECT_NAME' created successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. cd $PROJECT_NAME"
echo "2. ./setup-new-project.sh"
echo "3. Review NEW_PROJECT_SETUP.md for customization options"
echo "4. Start developing!"
echo ""
echo -e "${YELLOW}Project structure created for: $PROJECT_TYPE${NC}"
echo "Available types: fullstack, frontend, backend"
echo ""