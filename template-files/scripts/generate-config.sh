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
# Allow TEMPLATE_DIR to be passed as environment variable, otherwise derive from script location
TEMPLATE_DIR="${TEMPLATE_DIR:-$(dirname "$SCRIPT_DIR")}"
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

# Enhanced template processing with phase awareness
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
    local has_javascript=$(to_lowercase_bool "$(extract_detection_value '.project.has_javascript')")
    local has_tests=$(to_lowercase_bool "$(extract_detection_value '.project.has_tests')")
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    local languages_json=$(echo "$PROJECT_DETECTION" | jq -c '.languages')
    local frameworks_json=$(echo "$PROJECT_DETECTION" | jq -c '.frameworks')
    
    # Phase-aware variables - determine initial phase and recommendation
    local initial_phase="0"
    local recommended_phase="0"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Skip expensive project analysis during initial setup to avoid hangs on large projects
    # The analyze command runs flake8, tsc, and eslint which can take minutes on large codebases
    # Users can run analysis later with: ./scripts/quality-gate-manager.sh analyze
    # For initial setup, always use Phase 0 (baseline mode)
    print_status "Using Phase 0 (Baseline Mode) for initial setup"
    
    # For new projects, we might want to start at the recommended phase
    # For existing projects, always start at Phase 0 for safety
    if [[ ! -f ".quality-config.yaml" ]]; then
        # New setup - can use recommended phase as initial
        initial_phase="$recommended_phase"
    else
        # Existing project - keep current phase
        if command -v python3 >/dev/null 2>&1; then
            initial_phase=$(python3 -c "
import yaml
try:
    with open('.quality-config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    print(config.get('quality_gates', {}).get('current_phase', 0))
except:
    print(0)
" 2>/dev/null || echo "0")
        fi
    fi
    
    # Enhanced template processing with all variables
    sed \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{HAS_FRONTEND}}|$has_frontend|g" \
        -e "s|{{HAS_BACKEND}}|$has_backend|g" \
        -e "s|{{HAS_TYPESCRIPT}}|$has_typescript|g" \
        -e "s|{{HAS_PYTHON}}|$has_python|g" \
        -e "s|{{HAS_JAVASCRIPT}}|$has_javascript|g" \
        -e "s|{{HAS_TESTS}}|$has_tests|g" \
        -e "s|{{FRONTEND_PATH}}|$frontend_path|g" \
        -e "s|{{BACKEND_PATH}}|$backend_path|g" \
        -e "s|{{LANGUAGES_JSON}}|$languages_json|g" \
        -e "s|{{FRAMEWORKS_JSON}}|$frameworks_json|g" \
        -e "s|{{INITIAL_PHASE}}|$initial_phase|g" \
        -e "s|{{RECOMMENDED_PHASE}}|$recommended_phase|g" \
        -e "s|{{TIMESTAMP}}|$timestamp|g" \
        "$template_file" > "$output_file"
        
    print_success "Generated: $output_file"
    
    # Show phase information if this is the quality config
    if [[ $(basename "$output_file") == ".quality-config.yaml" ]]; then
        print_status "Phase Configuration:"
        echo "  • Initial Phase: $initial_phase"
        echo "  • Recommended Phase: $recommended_phase" 
        echo "  • Project Type: $project_type"
    fi
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
        # Determine the correct working directory and file pattern
        local work_dir="${frontend_path}"
        local file_pattern='.*\.(js|jsx|ts|tsx)$'
        local ts_pattern='.*\.(ts|tsx)$'

        # If frontend is at root (.), don't add path prefix to patterns
        if [[ "$frontend_path" == "." ]]; then
            work_dir="."
        else
            # For subdirectories, include path in pattern for pre-commit filtering
            file_pattern="^${frontend_path}/.*\.(js|jsx|ts|tsx)$"
            ts_pattern="^${frontend_path}/.*\.(ts|tsx)$"
        fi

        cat >> .pre-commit-config.yaml << EOF
  # Frontend hooks (TypeScript/JavaScript)
  - repo: local
    hooks:
      - id: eslint-check
        name: ESLint Check
        entry: bash -c 'cd ${work_dir} && npm run lint'
        language: system
        files: '${file_pattern}'
        pass_filenames: false

      - id: typescript-check
        name: TypeScript Check
        entry: bash -c 'cd ${work_dir} && npx tsc --noEmit'
        language: system
        files: '${ts_pattern}'
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

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/pycqa/flake8
    rev: 7.1.1
    hooks:
      - id: flake8
        args: ["--max-line-length=88", "--extend-ignore=E203,W503"]
        exclude: '^(tools/|demo/|\.local_docs/)'

EOF

        # Detect MyPy dependencies dynamically
        if [[ -f "$SCRIPT_DIR/detect-mypy-deps.sh" ]]; then
            local mypy_deps_json=$("$SCRIPT_DIR/detect-mypy-deps.sh" 2>/dev/null || echo "[]")
            local deps_count=$(echo "$mypy_deps_json" | jq 'length' 2>/dev/null || echo "0")

            # Detect pyproject.toml location for MyPy config
            local mypy_config_arg=""
            if [[ -f "pyproject.toml" ]]; then
                mypy_config_arg='["--config-file=pyproject.toml"]'
            elif [[ -f "backend/pyproject.toml" ]]; then
                mypy_config_arg='["--config-file=backend/pyproject.toml"]'
            elif [[ -f "src/pyproject.toml" ]]; then
                mypy_config_arg='["--config-file=src/pyproject.toml"]'
            else
                mypy_config_arg='[]'  # Let MyPy find config automatically
            fi

            # Always enable MyPy for Python projects to match CI behavior
            if [[ "$deps_count" -gt 0 ]]; then
                print_status "Detected $deps_count MyPy dependencies - enabling MyPy hook"

                # Convert JSON array to YAML array format
                local mypy_deps_yaml=$(echo "$mypy_deps_json" | jq -r '.[]' | sed 's/^/          - /')

                cat >> .pre-commit-config.yaml << EOF
  # MyPy type checking (auto-configured based on requirements)
  # Note: Enabled by default to match CI behavior
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
        args: $mypy_config_arg
        additional_dependencies:
$mypy_deps_yaml
        files: '^(src|backend|app)/.*\.py$'

EOF
            else
                # Enable MyPy but with empty dependencies (user must add manually)
                print_status "No MyPy dependencies auto-detected - enabling with empty dependencies"
                cat >> .pre-commit-config.yaml << EOF
  # MyPy type checking
  # Note: Enabled by default to match CI behavior. Add project-specific dependencies below.
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
        args: $mypy_config_arg
        additional_dependencies: []
        # Common dependencies to add: pydantic, fastapi, httpx, types-*, numpy, etc.
        files: '^(src|backend|app)/.*\.py$'

EOF
            fi
        else
            print_warning "MyPy dependency detection script not found"
        fi
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

        # Add base lint/lint:fix scripts for root-level or frontend directory
        # Note: ESLint v9 flat config doesn't use --ext flag, file patterns are in config
        scripts_to_add=$(echo "$scripts_to_add" | jq --arg prefix "$frontend_prefix" '. + {
            "lint": ($prefix + "eslint ."),
            "lint:fix": ($prefix + "eslint . --fix"),
            "type-check": ($prefix + "tsc --noEmit"),
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

# Advanced phase-aware CI/CD workflow generation
generate_ci_workflow() {
    print_status "Generating phase-aware CI/CD workflow..."
    
    # Create .github/workflows directory
    mkdir -p .github/workflows
    
    # Get current phase and project information
    local current_phase="0"
    local phase_description="Baseline & Stabilization"
    local recommended_phase="0"
    
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

        recommended_phase=$(python3 -c "
import yaml
try:
    with open('.quality-config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    print(config.get('quality_gates', {}).get('recommended_phase', 0))
except:
    print(0)
" 2>/dev/null || echo "0")
    fi
    
    # Set phase description and get current timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$current_phase" in
        "0") phase_description="Baseline & Stabilization" ;;
        "1") phase_description="Changed-Code-Only Enforcement" ;;
        "2") phase_description="Repository-Wide + Ratcheting" ;;
        "3") phase_description="Full Strict Enforcement" ;;
    esac
    
    print_status "Current phase: $current_phase ($phase_description)"
    
    # Get project detection values for workflow generation
    local project_type=$(extract_detection_value '.project.type')
    local has_frontend=$(extract_detection_value '.project.has_frontend')
    local has_backend=$(extract_detection_value '.project.has_backend')
    local has_typescript=$(extract_detection_value '.project.has_typescript')
    local has_python=$(extract_detection_value '.project.has_python')
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    
    # Choose the appropriate workflow template based on phase
    local workflow_template=""
    local workflow_name=""
    
    # Phase-specific workflow selection
    case "$current_phase" in
        "0")
            workflow_template="quality-adaptive-phase0.yml.template"
            workflow_name="quality-adaptive-phase0.yml"
            ;;
        "1") 
            workflow_template="quality-adaptive-phase1.yml.template"
            workflow_name="quality-adaptive-phase1.yml"
            ;;
        "2")
            workflow_template="quality-adaptive-phase2.yml.template" 
            workflow_name="quality-adaptive-phase2.yml"
            ;;
        "3")
            workflow_template="quality-adaptive-phase3.yml.template"
            workflow_name="quality-adaptive-phase3.yml"
            ;;
        *)
            workflow_template="quality-adaptive.yml.template"
            workflow_name="quality-adaptive.yml"
            ;;
    esac
    
    # Generate the main adaptive workflow
    local template_found=false
    
    # Try phase-specific template first
    if [[ -f "$TEMPLATE_DIR/.github/workflows/$workflow_template" ]]; then
        template_found=true
        print_status "Using phase-specific template: $workflow_template"
        
        # Process the phase-specific template
        process_phase_workflow_template "$TEMPLATE_DIR/.github/workflows/$workflow_template" ".github/workflows/$workflow_name"
    fi
    
    # Fallback to master adaptive template
    if [[ $template_found == false && -f "$TEMPLATE_DIR/.github/workflows/quality-adaptive.yml.template" ]]; then
        template_found=true
        workflow_name="quality-adaptive.yml"  # Update workflow name for cleanup
        print_status "Using master adaptive template with phase conditionals"

        # Process the master template with phase-aware conditionals
        process_master_adaptive_template "$TEMPLATE_DIR/.github/workflows/quality-adaptive.yml.template" ".github/workflows/quality-adaptive.yml"
    fi
    
    # Last fallback to basic workflow
    if [[ $template_found == false ]]; then
        if [[ -f "$TEMPLATE_DIR/.github/workflows/quality-standardized.yml" ]]; then
            workflow_name="quality-standardized.yml"  # Update workflow name for cleanup
            cp "$TEMPLATE_DIR/.github/workflows/quality-standardized.yml" .github/workflows/
            print_warning "Using fallback standardized workflow template"
        else
            # Generate a basic workflow from scratch
            workflow_name="quality-basic.yml"  # Update workflow name for cleanup
            generate_basic_workflow ".github/workflows/quality-basic.yml"
            print_warning "Generated basic workflow - no templates found"
        fi
    fi
    
    # Clean up any old workflow files if we're switching phases
    cleanup_old_workflow_files "$workflow_name"
}

# Function to process phase-specific workflow templates
process_phase_workflow_template() {
    local template_file="$1"
    local output_file="$2"
    
    # Get all necessary variables for substitution
    local project_type=$(extract_detection_value '.project.type')
    local has_frontend=$(extract_detection_value '.project.has_frontend')
    local has_backend=$(extract_detection_value '.project.has_backend') 
    local has_typescript=$(extract_detection_value '.project.has_typescript')
    local has_python=$(extract_detection_value '.project.has_python')
    local has_tests=$(extract_detection_value '.project.has_tests')
    local frontend_path=$(extract_detection_value '.project.frontend_path')
    local backend_path=$(extract_detection_value '.project.backend_path')
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get current phase info
    local current_phase="0"
    local recommended_phase="0"
    local phase_description="Baseline & Stabilization"

    if [[ -f ".quality-config.yaml" ]]; then
        current_phase=$(python3 -c "import yaml; print(yaml.safe_load(open('.quality-config.yaml')).get('quality_gates', {}).get('current_phase', 0))" 2>/dev/null || echo "0")
        recommended_phase=$(python3 -c "import yaml; print(yaml.safe_load(open('.quality-config.yaml')).get('quality_gates', {}).get('recommended_phase', 0))" 2>/dev/null || echo "0")
    fi

    # Set phase description based on current phase
    case "$current_phase" in
        "0") phase_description="Baseline & Stabilization" ;;
        "1") phase_description="Changed-Code-Only Enforcement" ;;
        "2") phase_description="Repository-Wide + Ratcheting" ;;
        "3") phase_description="Full Strict Enforcement" ;;
    esac

    # Perform comprehensive variable substitution
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{CURRENT_PHASE}}|$current_phase|g" \
        -e "s|{{RECOMMENDED_PHASE}}|$recommended_phase|g" \
        -e "s|{{PHASE_DESCRIPTION}}|$phase_description|g" \
        -e "s|{{TIMESTAMP}}|$timestamp|g" \
        -e "s|{{HAS_FRONTEND}}|$has_frontend|g" \
        -e "s|{{HAS_BACKEND}}|$has_backend|g" \
        -e "s|{{HAS_TYPESCRIPT}}|$has_typescript|g" \
        -e "s|{{HAS_PYTHON}}|$has_python|g" \
        -e "s|{{HAS_TESTS}}|$has_tests|g" \
        -e "s|{{FRONTEND_PATH}}|$frontend_path|g" \
        -e "s|{{BACKEND_PATH}}|$backend_path|g" \
        "$template_file" > "$output_file"
        
    print_success "Generated phase-aware workflow: $output_file"
}

# Function to process master adaptive template with phase conditionals
process_master_adaptive_template() {
    local template_file="$1" 
    local output_file="$2"
    
    # Get current phase and project structure info
    local current_phase="0"
    local has_frontend="false"
    local has_backend="false"

    if [[ -f ".quality-config.yaml" ]]; then
        current_phase=$(python3 -c "import yaml; print(yaml.safe_load(open('.quality-config.yaml')).get('quality_gates', {}).get('current_phase', 0))" 2>/dev/null || echo "0")
        has_frontend=$(python3 -c "import yaml; print(str(yaml.safe_load(open('.quality-config.yaml')).get('project', {}).get('structure', {}).get('has_frontend', False)).lower())" 2>/dev/null || echo "false")
        has_backend=$(python3 -c "import yaml; print(str(yaml.safe_load(open('.quality-config.yaml')).get('project', {}).get('structure', {}).get('has_backend', False)).lower())" 2>/dev/null || echo "false")
    fi

    print_status "Processing master template for Phase $current_phase (frontend: $has_frontend, backend: $has_backend)..."

    # Use Python for sophisticated template processing with conditionals
    python3 << EOF
import re
import sys

# Read template
try:
    with open("$template_file", 'r') as f:
        content = f.read()
except Exception as e:
    print(f"Error reading template: {e}")
    sys.exit(1)

current_phase = $current_phase
has_frontend = '$has_frontend' == 'true'
has_backend = '$has_backend' == 'true'

# Process phase conditionals
def process_conditionals(content, phase, has_frontend, has_backend):
    # Process {{#IF_PHASE_X}} ... {{/IF_PHASE_X}} blocks
    for p in range(4):  # Phases 0-3
        pattern = r'{{#IF_PHASE_%d}}(.*?){{/IF_PHASE_%d}}' % (p, p)
        if p == phase:
            # Keep content for current phase
            content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
        else:
            # Remove content for other phases
            content = re.sub(pattern, '', content, flags=re.DOTALL)

    # Process {{#IF_PHASE_X_OR_HIGHER}} (more readable alias for GTE)
    for p in range(4):
        pattern = r'{{#IF_PHASE_%d_OR_HIGHER}}(.*?){{/IF_PHASE_%d_OR_HIGHER}}' % (p, p)
        if phase >= p:
            content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
        else:
            content = re.sub(pattern, '', content, flags=re.DOTALL)

    # Process {{#IF_PHASE_GTE_X}} (greater than or equal) blocks
    for p in range(4):
        pattern = r'{{#IF_PHASE_GTE_%d}}(.*?){{/IF_PHASE_GTE_%d}}' % (p, p)
        if phase >= p:
            content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
        else:
            content = re.sub(pattern, '', content, flags=re.DOTALL)

    # Process {{#IF_PHASE_LTE_X}} (less than or equal) blocks
    for p in range(4):
        pattern = r'{{#IF_PHASE_LTE_%d}}(.*?){{/IF_PHASE_LTE_%d}}' % (p, p)
        if phase <= p:
            content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
        else:
            content = re.sub(pattern, '', content, flags=re.DOTALL)

    # Process {{#IF_HAS_FRONTEND}} blocks
    pattern = r'{{#IF_HAS_FRONTEND}}(.*?){{/IF_HAS_FRONTEND}}'
    if has_frontend:
        content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    else:
        content = re.sub(pattern, '', content, flags=re.DOTALL)

    # Process {{#IF_HAS_BACKEND}} blocks
    pattern = r'{{#IF_HAS_BACKEND}}(.*?){{/IF_HAS_BACKEND}}'
    if has_backend:
        content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    else:
        content = re.sub(pattern, '', content, flags=re.DOTALL)

    return content

# Process the template
processed_content = process_conditionals(content, current_phase, has_frontend, has_backend)

# Write processed template
try:
    with open("${output_file}.tmp", 'w') as f:
        f.write(processed_content)
    print("✅ Template conditionals processed successfully")
except Exception as e:
    print(f"❌ Error writing processed template: {e}")
    sys.exit(1)
EOF
    
    if [[ $? -eq 0 ]]; then
        # Now do variable substitutions on the processed template
        process_phase_workflow_template "${output_file}.tmp" "$output_file"
        rm -f "${output_file}.tmp"
    else
        # Fallback to simple substitution
        print_warning "Python conditional processing failed - using simple substitution"
        process_phase_workflow_template "$template_file" "$output_file"
    fi
}

# Function to generate a basic workflow when no templates are found
generate_basic_workflow() {
    local output_file="$1"
    
    local project_type=$(extract_detection_value '.project.type')
    local has_frontend=$(extract_detection_value '.project.has_frontend')
    local has_backend=$(extract_detection_value '.project.has_backend')
    
    cat > "$output_file" << EOF
# Auto-generated Basic Quality Workflow
# Project: $PROJECT_NAME ($project_type)
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

name: Quality Gates (Basic)

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    name: Quality Validation
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        
      - name: Setup Environment
        uses: actions/setup-node@v4
        if: $has_frontend == 'true'
        with:
          node-version: 20
          cache: 'npm'
          
      - name: Setup Python
        uses: actions/setup-python@v5
        if: $has_backend == 'true'
        with:
          python-version: 3.11
          
      - name: Install Dependencies
        run: |
          pip install pre-commit
          pre-commit install-hooks
          
      - name: Run Quality Checks
        run: |
          if [[ -f "./scripts/validate-adaptive.sh" ]]; then
            ./scripts/validate-adaptive.sh
          else
            pre-commit run --all-files
          fi
EOF

    print_success "Generated basic quality workflow"
}

# Function to clean up old workflow files when switching phases
cleanup_old_workflow_files() {
    local current_workflow="$1"
    
    # List of potential old workflow files
    local old_workflows=(
        "quality-adaptive.yml"
        "quality-adaptive-phase0.yml"
        "quality-adaptive-phase1.yml"
        "quality-adaptive-phase2.yml" 
        "quality-adaptive-phase3.yml"
        "quality-basic.yml"
    )
    
    local cleaned=false
    for workflow in "${old_workflows[@]}"; do
        if [[ "$workflow" != "$current_workflow" && -f ".github/workflows/$workflow" ]]; then
            rm -f ".github/workflows/$workflow"
            cleaned=true
        fi
    done
    
    if [[ $cleaned == true ]]; then
        print_status "Cleaned up old workflow files"
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