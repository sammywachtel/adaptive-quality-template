#!/bin/bash

# Configuration Generator for Adaptive Quality Gate Template
# Processes templates and generates project-specific configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(pwd)"

# Global variables
PROJECT_DETECTION=""
PROJECT_NAME=""

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get project name
get_project_name() {
    # Try to get from package.json
    if [[ -f "package.json" ]] && command -v jq >/dev/null 2>&1; then
        PROJECT_NAME=$(jq -r '.name // empty' package.json 2>/dev/null)
    fi
    
    # Fallback to directory name
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME=$(basename "$PROJECT_ROOT")
    fi
    
    # Sanitize project name
    PROJECT_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9-]/-/g')
}

# Function to detect project structure
detect_project_structure() {
    print_status "Detecting project structure..."
    
    # Run project detection script
    if [[ -f "$SCRIPT_DIR/detect-project-type.sh" ]]; then
        PROJECT_DETECTION=$("$SCRIPT_DIR/detect-project-type.sh" json)
        print_success "Project structure detected"
    else
        print_error "Project detection script not found"
        exit 1
    fi
}

# Function to extract values from detection JSON
extract_detection_value() {
    local key="$1"
    echo "$PROJECT_DETECTION" | jq -r "$key" 2>/dev/null || echo ""
}

# Function to convert boolean to lowercase
to_lowercase_bool() {
    local value="$1"
    [[ "$value" == "true" ]] && echo "true" || echo "false"
}

# Function to process template with substitutions
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    print_status "Processing template: $(basename "$template_file")"
    
    # Extract project detection values
    local project_type=$(extract_detection_value '.project.type')
    local has_frontend=$(to_lowercase_bool "$(extract_detection_value '.project.has_frontend')")
    local has_backend=$(to_lowercase_bool "$(extract_detection_value '.project.has_backend')")
    local has_typescript=$(to_lowercase_bool "$(extract_detection_value '.project.has_typescript')")
    local has_python=$(to_lowercase_bool "$(extract_detection_value '.project.has_python')")
    local has_tests=$(to_lowercase_bool "$(extract_detection_value '.project.has_tests')")
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    local languages_json=$(echo "$PROJECT_DETECTION" | jq -c '.languages')
    local frameworks_json=$(echo "$PROJECT_DETECTION" | jq -c '.frameworks')
    
    # Process the template file
    sed \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{HAS_FRONTEND}}|$has_frontend|g" \
        -e "s|{{HAS_BACKEND}}|$has_backend|g" \
        -e "s|{{HAS_TYPESCRIPT}}|$has_typescript|g" \
        -e "s|{{HAS_PYTHON}}|$has_python|g" \
        -e "s|{{HAS_TESTS}}|$has_tests|g" \
        -e "s|{{FRONTEND_PATH}}|$frontend_path|g" \
        -e "s|{{BACKEND_PATH}}|$backend_path|g" \
        -e "s|{{LANGUAGES_JSON}}|$languages_json|g" \
        -e "s|{{FRAMEWORKS_JSON}}|$frameworks_json|g" \
        "$template_file" > "$output_file"
        
    print_success "Generated: $output_file"
}

# Function to generate pre-commit configuration
generate_precommit_config() {
    print_status "Generating adaptive pre-commit configuration..."
    
    local has_typescript=$(extract_detection_value '.project.has_typescript')
    local has_python=$(extract_detection_value '.project.has_python')
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    
    # Create adaptive pre-commit config
    cat > .pre-commit-config.yaml << 'EOF'
# Adaptive Pre-commit Configuration
# Generated based on detected project structure

repos:
  # Universal hooks (always enabled)
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=1024']
      - id: check-yaml
      - id: check-json

EOF

    # Add TypeScript/JavaScript hooks if detected
    if [[ "$has_typescript" == "true" || -d "$frontend_path" ]]; then
        cat >> .pre-commit-config.yaml << EOF
  # Frontend hooks (TypeScript/JavaScript)
  - repo: local
    hooks:
      - id: eslint-check
        name: ESLint Check
        entry: bash -c 'cd ${frontend_path:-frontend} && npm run lint'
        language: system
        files: '^${frontend_path:-frontend}/.*\.(js|jsx|ts|tsx)$'
        pass_filenames: false

      - id: typescript-check
        name: TypeScript Check
        entry: bash -c 'cd ${frontend_path:-frontend} && npx tsc --noEmit'
        language: system
        files: '^${frontend_path:-frontend}/.*\.(ts|tsx)$'
        pass_filenames: false

EOF
    fi

    # Add Python hooks if detected
    if [[ "$has_python" == "true" || -d "$backend_path" ]]; then
        cat >> .pre-commit-config.yaml << EOF
  # Python hooks
  - repo: https://github.com/psf/black
    rev: 24.10.0
    hooks:
      - id: black
        language_version: python3
        files: '^${backend_path:-.}/.*\.py$'

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ["--profile", "black"]
        files: '^${backend_path:-.}/.*\.py$'

  - repo: https://github.com/pycqa/flake8
    rev: 7.1.1
    hooks:
      - id: flake8
        args: ["--max-line-length=88", "--extend-ignore=E203,W503"]
        files: '^${backend_path:-.}/.*\.py$'

EOF
    fi

    # Add security hooks
    cat >> .pre-commit-config.yaml << 'EOF'
  # Security hooks
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: package-lock.json

EOF

    print_success "Generated adaptive pre-commit configuration"
}

# Function to generate package.json scripts
generate_package_scripts() {
    if [[ ! -f "package.json" ]]; then
        return 0
    fi
    
    print_status "Adding adaptive scripts to package.json..."
    
    local has_frontend=$(extract_detection_value '.project.has_frontend')
    local has_backend=$(extract_detection_value '.project.has_backend')
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    
    # Create temporary script additions based on project structure
    local scripts_to_add='{}'
    
    # Universal scripts
    scripts_to_add=$(echo "$scripts_to_add" | jq '. + {
        "validate": "./scripts/validate-adaptive.sh",
        "quality:check": "./scripts/validate-adaptive.sh",
        "setup:dev": "./setup-dev.sh",
        "precommit:install": "pre-commit install",
        "precommit:run": "pre-commit run --all-files"
    }')
    
    # Frontend scripts
    if [[ "$has_frontend" == "true" ]]; then
        local frontend_prefix=""
        if [[ "$frontend_path" != "." ]]; then
            frontend_prefix="cd $frontend_path && "
        fi
        
        scripts_to_add=$(echo "$scripts_to_add" | jq --arg prefix "$frontend_prefix" '. + {
            "frontend:dev": ($prefix + "npm run dev"),
            "frontend:build": ($prefix + "npm run build"),
            "frontend:lint": ($prefix + "npm run lint"),
            "frontend:lint:fix": ($prefix + "npm run lint:fix"),
            "frontend:type-check": ($prefix + "npx tsc --noEmit"),
            "frontend:test": ($prefix + "npm test")
        }')
    fi
    
    # Backend scripts
    if [[ "$has_backend" == "true" ]]; then
        local backend_prefix=""
        if [[ "$backend_path" != "." ]]; then
            backend_prefix="cd $backend_path && "
        fi
        
        scripts_to_add=$(echo "$scripts_to_add" | jq --arg prefix "$backend_prefix" '. + {
            "backend:dev": ($prefix + "uvicorn app.main:app --reload --host 0.0.0.0 --port 8001"),
            "backend:format": ($prefix + "black . && isort ."),
            "backend:lint": ($prefix + "flake8 . && black --check . && isort --check-only ."),
            "backend:test": ($prefix + "python -m pytest")
        }')
    fi
    
    # Combined scripts for fullstack projects
    if [[ "$has_frontend" == "true" && "$has_backend" == "true" ]]; then
        scripts_to_add=$(echo "$scripts_to_add" | jq '. + {
            "dev": "concurrently \"npm run frontend:dev\" \"npm run backend:dev\"",
            "lint": "npm run frontend:lint && npm run backend:lint",
            "lint:fix": "npm run frontend:lint:fix && npm run backend:format",
            "test": "npm run frontend:test && npm run backend:test"
        }')
    fi
    
    # Merge scripts into package.json
    if command -v jq >/dev/null 2>&1; then
        cp package.json package.json.backup
        jq --argjson new_scripts "$scripts_to_add" '.scripts = (.scripts // {}) + $new_scripts' package.json > package.json.tmp
        mv package.json.tmp package.json
        print_success "Added adaptive scripts to package.json"
    else
        print_warning "jq not found - scripts not added to package.json"
    fi
}

# Function to generate CI workflow
generate_ci_workflow() {
    print_status "Generating adaptive CI/CD workflow..."
    
    # Create .github/workflows directory
    mkdir -p .github/workflows
    
    # Get current phase and project information
    local current_phase="0"
    local phase_description="Baseline & Stabilization"
    
    if [[ -f ".quality-config.yaml" ]]; then
        current_phase=$(python3 -c "
import yaml
try:
    with open('.quality-config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    print(config.get('quality_gates', {}).get('current_phase', 0))
except:
    print(0)
" 2>/dev/null || echo "0")
    fi
    
    # Set phase description
    case "$current_phase" in
        "0") phase_description="Baseline & Stabilization" ;;
        "1") phase_description="Changed-Code-Only Enforcement" ;;
        "2") phase_description="Ratchet & Expand Scope" ;;
        "3") phase_description="Normalize & Harden" ;;
    esac
    
    # Get project detection values for workflow generation
    local has_frontend=$(extract_detection_value '.project.has_frontend')
    local has_backend=$(extract_detection_value '.project.has_backend')
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    
    # Process the CI workflow template with more sophisticated replacements
    if [[ -f "$TEMPLATE_DIR/.github/workflows/quality-adaptive.yml.template" ]]; then
        # Create a temporary processing script for complex template logic
        # Use a simpler sed-based approach that works correctly
        sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
            -e "s|{{PROJECT_TYPE}}|$(extract_detection_value '.project.type')|g" \
            -e "s|{{CURRENT_PHASE}}|$current_phase|g" \
            -e "s|{{PHASE_DESCRIPTION}}|$phase_description|g" \
            -e "s|{{HAS_FRONTEND}}|$has_frontend|g" \
            -e "s|{{HAS_BACKEND}}|$has_backend|g" \
            -e "s|{{FRONTEND_PATH}}|$frontend_path|g" \
            -e "s|{{BACKEND_PATH}}|$backend_path|g" \
            "$TEMPLATE_DIR/.github/workflows/quality-adaptive.yml.template" > .github/workflows/quality-adaptive.yml.tmp
        
        # Process conditional blocks based on current phase
        if [[ "$current_phase" == "0" ]]; then
            # Phase 0: Keep baseline checks, remove higher phase blocks
            sed -e '/{{#IF_PHASE_0}}/d' -e '/{{\/IF_PHASE_0}}/d' \
                -e '/{{#IF_PHASE_1_OR_HIGHER}}/,/{{\/IF_PHASE_1_OR_HIGHER}}/d' \
                -e '/{{#IF_PHASE_2_OR_HIGHER}}/,/{{\/IF_PHASE_2_OR_HIGHER}}/d' \
                .github/workflows/quality-adaptive.yml.tmp > .github/workflows/quality-adaptive.yml
        elif [[ "$current_phase" == "1" ]]; then
            # Phase 1: Keep phase 0 and 1+ blocks, remove 2+ blocks
            sed -e '/{{#IF_PHASE_0}}/,/{{\/IF_PHASE_0}}/d' \
                -e '/{{#IF_PHASE_1_OR_HIGHER}}/d' -e '/{{\/IF_PHASE_1_OR_HIGHER}}/d' \
                -e '/{{#IF_PHASE_2_OR_HIGHER}}/,/{{\/IF_PHASE_2_OR_HIGHER}}/d' \
                .github/workflows/quality-adaptive.yml.tmp > .github/workflows/quality-adaptive.yml
        elif [[ "$current_phase" == "2" ]]; then
            # Phase 2: Keep phase 0, 1+, and 2+ blocks
            sed -e '/{{#IF_PHASE_0}}/,/{{\/IF_PHASE_0}}/d' \
                -e '/{{#IF_PHASE_1_OR_HIGHER}}/d' -e '/{{\/IF_PHASE_1_OR_HIGHER}}/d' \
                -e '/{{#IF_PHASE_2_OR_HIGHER}}/d' -e '/{{\/IF_PHASE_2_OR_HIGHER}}/d' \
                .github/workflows/quality-adaptive.yml.tmp > .github/workflows/quality-adaptive.yml
        else
            # Phase 3 or higher: Keep all blocks
            sed -e '/{{#IF_PHASE_0}}/,/{{\/IF_PHASE_0}}/d' \
                -e '/{{#IF_PHASE_1_OR_HIGHER}}/d' -e '/{{\/IF_PHASE_1_OR_HIGHER}}/d' \
                -e '/{{#IF_PHASE_2_OR_HIGHER}}/d' -e '/{{\/IF_PHASE_2_OR_HIGHER}}/d' \
                .github/workflows/quality-adaptive.yml.tmp > .github/workflows/quality-adaptive.yml
        fi
        
        rm -f .github/workflows/quality-adaptive.yml.tmp
        echo "Adaptive CI workflow generated"
    else
        # Fallback to basic workflow
        cp "$TEMPLATE_DIR/.github/workflows/quality-standardized.yml" .github/workflows/ 2>/dev/null || true
        print_warning "Using fallback CI workflow template"
    fi
}

# Function to create baseline files
create_baseline_files() {
    print_status "Creating baseline files..."
    
    # Create secrets baseline if detect-secrets is available
    if command -v detect-secrets >/dev/null 2>&1; then
        if [[ ! -f ".secrets.baseline" ]]; then
            detect-secrets scan . > .secrets.baseline 2>/dev/null || echo '{}' > .secrets.baseline
            print_success "Created secrets baseline"
        fi
    fi
    
    # Create .gitignore entries for quality tools
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "# Quality gate files" .gitignore; then
            cat >> .gitignore << 'EOF'

# Quality gate files
.quality-config.yaml.bak
.quality-baseline.json
quality-reports/
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
EOF
            print_success "Updated .gitignore with quality gate entries"
        fi
    fi
}

# Main function to generate all configurations
generate_configurations() {
    print_status "Generating adaptive configurations for project..."
    
    get_project_name
    detect_project_structure
    
    # Generate main quality configuration
    if [[ -f "$TEMPLATE_DIR/.quality-config.yaml.template" ]]; then
        process_template "$TEMPLATE_DIR/.quality-config.yaml.template" ".quality-config.yaml"
    else
        print_error "Quality config template not found"
        exit 1
    fi
    
    # Generate other configurations
    generate_precommit_config
    generate_package_scripts
    generate_ci_workflow
    create_baseline_files
    
    print_success "All configurations generated successfully!"
    
    # Show summary
    echo ""
    echo -e "${BLUE}📋 Configuration Summary${NC}"
    echo "========================"
    echo "Project Name: $PROJECT_NAME"
    echo "Project Type: $(extract_detection_value '.project.type')"
    echo "Generated Files:"
    echo "  ✅ .quality-config.yaml"
    echo "  ✅ .pre-commit-config.yaml"
    [[ -f "package.json" ]] && echo "  ✅ package.json (updated scripts)"
    echo "  ✅ .secrets.baseline"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Review and customize .quality-config.yaml as needed"
    echo "2. Run: ./setup-dev.sh to complete setup"
    echo "3. Run: ./scripts/validate-adaptive.sh to test configuration"
}

# Command-line interface
case "${1:-generate}" in
    "generate")
        generate_configurations
        ;;
    "update")
        print_status "Updating existing configuration..."
        generate_configurations
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  generate    Generate new configuration (default)"
        echo "  update      Update existing configuration"
        echo "  help        Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac