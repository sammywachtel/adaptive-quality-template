#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show usage and help
show_help() {
    echo "🚀 Adaptive Quality Gate Template Setup"
    echo "======================================"
    echo ""
    echo "Usage: $0 <target-directory> [options]"
    echo ""
    echo "Arguments:"
    echo "  target-directory     Path to the project directory to setup"
    echo "                      Can be '.' for current directory"
    echo ""
    echo "Options:"
    echo "  --overwrite-tools    Replace existing tool configs (black, mypy, etc.) with template versions"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 .                              # Setup current directory"
    echo "  $0 /path/to/my-project           # Setup specific project"
    echo "  $0 . --overwrite-tools           # Setup with tool standardization"
    echo ""
    echo "Default behavior (Smart Merge):"
    echo "  ✅ Preserves existing [build-system] and [project] sections"
    echo "  ✅ Preserves existing tool configurations, adds only missing ones"
    echo "  ✅ Auto-detects project type and adapts configuration"
    echo ""
    echo "With --overwrite-tools (Standardize):"
    echo "  ✅ Still preserves [build-system] and [project] sections"
    echo "  🔄 Replaces black, mypy, isort, pytest, coverage configs with template versions"
    echo "  ✅ Preserves other custom tools (hatch, poetry, etc.)"
    echo ""
    echo "What gets installed:"
    echo "  📁 Adaptive scripts (detect-project-type.sh, validate-adaptive.sh, etc.)"
    echo "  🔧 Smart pre-commit hooks based on your project type"
    echo "  📝 Quality configuration files (.quality-config.yaml, etc.)"
    echo "  🎯 Graduated quality gate system (4-phase progression)"
}

# Parse command line arguments
OVERWRITE_TOOLS=false
TARGET_DIR=""

# First pass: extract target directory (first non-flag argument)
for arg in "$@"; do
    case $arg in
        --overwrite-tools)
            OVERWRITE_TOOLS=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            # Skip other flags
            ;;
        *)
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$arg"
            fi
            ;;
    esac
done

# Check if target directory was provided
if [[ -z "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} Target directory is required"
    echo ""
    show_help
    exit 1
fi

# Convert to absolute path and validate
if [[ "$TARGET_DIR" == "." ]]; then
    TARGET_DIR="$(pwd)"
else
    original_target="$TARGET_DIR"
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
        echo -e "${RED}[ERROR]${NC} Target directory '$original_target' does not exist"
        exit 1
    }
fi

echo -e "${BLUE}[INFO]${NC} Target directory: $TARGET_DIR"

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

# Check if we're in a valid directory (adaptive - works with any project type)
check_target_directory() {
    # Change to target directory
    cd "$TARGET_DIR" || {
        print_error "Could not access target directory: $TARGET_DIR"
        exit 1
    }
    
    # Check for common project indicators
    if [[ ! -f "package.json" && ! -f "pyproject.toml" && ! -f "requirements.txt" && ! -d "src" ]]; then
        print_error "No project indicators found in: $TARGET_DIR"
        print_status "Looking for: package.json, pyproject.toml, requirements.txt, or src/ directory"
        print_status "Current directory contents:"
        ls -la | head -10
        exit 1
    fi
    
    print_success "Project root detected in $TARGET_DIR - proceeding with adaptive setup"
}

# Copy template files and generate adaptive configurations
setup_adaptive_configuration() {
    print_status "Setting up adaptive quality gate system..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_DIR="$SCRIPT_DIR/template-files"
    
    # Copy adaptive scripts
    mkdir -p scripts
    cp "$TEMPLATE_DIR/scripts/detect-project-type.sh" scripts/
    cp "$TEMPLATE_DIR/scripts/generate-config.sh" scripts/
    cp "$TEMPLATE_DIR/scripts/validate-adaptive.sh" scripts/
    cp "$TEMPLATE_DIR/scripts/quality-gate-manager.sh" scripts/
    chmod +x scripts/*.sh
    print_status "✓ Copied adaptive scripts"
    
    # Copy Python-specific quality tools if Python detected
    local project_type=$(./scripts/detect-project-type.sh type 2>/dev/null || echo "unknown")
    if [[ "$project_type" == *"python"* ]] || [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
        cp "$TEMPLATE_DIR/scripts/quality_check.py" scripts/
        chmod +x scripts/quality_check.py
        print_status "✓ Installed Python quality check script"
        
        # Detect backend path and copy .flake8 configuration
        local backend_path="."
        if [[ -d "backend" && -f "backend/requirements.txt" ]] || [[ -d "backend" && -f "backend/pyproject.toml" ]]; then
            backend_path="backend"
        fi
        
        # Copy .flake8 configuration to the correct backend location
        local flake8_target="$backend_path/.flake8"
        if [[ ! -f "$flake8_target" ]]; then
            cp "$TEMPLATE_DIR/backend/.flake8" "$flake8_target"
            if [[ "$backend_path" == "." ]]; then
                print_status "✓ Installed .flake8 configuration in root (line length = 88)"
            else
                print_status "✓ Installed .flake8 configuration in $backend_path/ (line length = 88)"
            fi
        else
            print_status "✓ Existing .flake8 found in $backend_path/ - preserved"
        fi
    fi
    
    # Generate project-specific configurations
    print_status "Generating adaptive configurations..."
    "$TEMPLATE_DIR/scripts/generate-config.sh"
    
    # Copy additional template files
    cp "$TEMPLATE_DIR/setup-dev.sh" .
    chmod +x setup-dev.sh
    print_status "✓ Copied setup-dev.sh"
    
    cp "$TEMPLATE_DIR/DEVELOPMENT.md" .
    print_status "✓ Copied DEVELOPMENT.md"
    
    # Copy backend files if Python detected
    if [[ -f ".quality-config.yaml" ]]; then
        local has_python=$(python3 -c "
import yaml
with open('.quality-config.yaml', 'r') as f:
    config = yaml.safe_load(f)
print(config.get('project', {}).get('structure', {}).get('has_python', False))
" 2>/dev/null || echo "false")
        
        if [[ "$has_python" == "True" ]]; then
            local backend_path=$(python3 -c "
import yaml
with open('.quality-config.yaml', 'r') as f:
    config = yaml.safe_load(f)
print(config.get('project', {}).get('structure', {}).get('backend_path', 'backend'))
" 2>/dev/null || echo "backend")
            
            # Handle pyproject.toml in backend directory
            if [[ -d "$backend_path" ]]; then
                cp "$TEMPLATE_DIR/backend/requirements-dev.txt" "$backend_path/" 2>/dev/null || true
                
                # Merge pyproject.toml if it exists, otherwise copy
                if [[ -f "$backend_path/pyproject.toml" ]]; then
                    print_status "Merging backend/pyproject.toml configurations..."
                    if [[ "$OVERWRITE_TOOLS" == "true" ]]; then
                        python3 "$TEMPLATE_DIR/scripts/merge-pyproject-toml.py" \
                            "$backend_path/pyproject.toml" \
                            "$TEMPLATE_DIR/backend/pyproject.toml" \
                            "$backend_path/pyproject.toml" \
                            --overwrite-tools
                        print_status "✓ Merged backend/pyproject.toml (preserved [build-system] and [project], replaced tool configs)"
                    else
                        python3 "$TEMPLATE_DIR/scripts/merge-pyproject-toml.py" \
                            "$backend_path/pyproject.toml" \
                            "$TEMPLATE_DIR/backend/pyproject.toml" \
                            "$backend_path/pyproject.toml"
                        print_status "✓ Merged backend/pyproject.toml (preserved existing sections and tool configs)"
                    fi
                else
                    cp "$TEMPLATE_DIR/backend/pyproject.toml" "$backend_path/" 2>/dev/null || true
                    print_status "✓ Copied Python backend configuration"
                fi
            fi
            
            # Also handle root pyproject.toml if it exists
            if [[ -f "pyproject.toml" && ! -f "$backend_path/pyproject.toml" ]]; then
                print_status "Merging root pyproject.toml configurations..."
                if [[ "$OVERWRITE_TOOLS" == "true" ]]; then
                    python3 "$TEMPLATE_DIR/scripts/merge-pyproject-toml.py" \
                        "pyproject.toml" \
                        "$TEMPLATE_DIR/backend/pyproject.toml" \
                        "pyproject.toml" \
                        --overwrite-tools
                    print_status "✓ Merged root pyproject.toml (preserved [build-system] and [project], replaced tool configs)"
                else
                    python3 "$TEMPLATE_DIR/scripts/merge-pyproject-toml.py" \
                        "pyproject.toml" \
                        "$TEMPLATE_DIR/backend/pyproject.toml" \
                        "pyproject.toml"
                    print_status "✓ Merged root pyproject.toml (preserved existing sections and tool configs)"
                fi
            fi
        fi
    fi
    
    print_success "Adaptive configuration setup complete!"
}

# Update package.json with adaptive scripts (done by generate-config.sh)
update_package_json() {
    # The generate-config.sh script already handles package.json updates
    # This function is maintained for compatibility but is now handled adaptively
    
    if [[ -f "package.json" ]]; then
        print_status "Package.json scripts already updated by adaptive configuration"
        print_success "Adaptive scripts added to package.json"
    else
        print_status "No package.json found - skipping npm script updates"
    fi
}

# Install required dependencies (adaptive based on project type)
install_dependencies() {
    print_status "Installing required dependencies..."
    
    # Detect if we have frontend components that need concurrently
    local has_frontend=false
    local project_type=""
    
    if command -v ./scripts/detect-project-type.sh >/dev/null 2>&1; then
        has_frontend=$(./scripts/detect-project-type.sh json 2>/dev/null | jq -r '.project.has_frontend // false' 2>/dev/null || echo "false")
        project_type=$(./scripts/detect-project-type.sh json 2>/dev/null | jq -r '.project.type // "unknown"' 2>/dev/null || echo "unknown")
    fi
    
    # Only install npm dependencies if we have frontend or fullstack project
    if [[ "$has_frontend" == "true" || "$project_type" == "fullstack" || -f "package.json" ]]; then
        # Install concurrently if not already present
        if ! npm list concurrently &> /dev/null; then
            npm install --save-dev concurrently
            print_status "✓ Installed concurrently"
        fi
    else
        print_status "Python-only project detected - skipping npm dependencies"
    fi
    
    print_success "Dependencies installed"
}

# Clean up unnecessary scripts after setup
cleanup_scripts() {
    print_status "Cleaning up unnecessary scripts..."
    
    local scripts_to_remove=()
    
    # Only remove generate-config.sh (most users won't need this after setup)
    # Keep detect-project-type.sh for CI workflow compatibility
    if [[ -f "scripts/generate-config.sh" ]]; then
        scripts_to_remove+=("scripts/generate-config.sh")
    fi
    
    # Remove scripts if any were identified
    if [[ ${#scripts_to_remove[@]} -gt 0 ]]; then
        for script in "${scripts_to_remove[@]}"; do
            rm -f "$script"
            print_status "✓ Removed $(basename "$script") (rarely needed after setup)"
        done
    fi
    
    # Show what's kept and why
    print_status "Keeping essential scripts:"
    [[ -f "scripts/validate-adaptive.sh" ]] && print_status "  ✓ validate-adaptive.sh (core validation)"
    [[ -f "scripts/detect-project-type.sh" ]] && print_status "  ✓ detect-project-type.sh (CI workflow dependency)"
    
    print_success "Script cleanup complete"
}

# Run the setup script
run_setup() {
    print_status "Running development environment setup..."
    ./setup-dev.sh
}

# Main execution
main() {
    echo "🚀 Setting up Adaptive Quality Gate Template..."
    echo "=============================================="
    echo ""
    echo -e "${BLUE}Target:${NC} $TARGET_DIR"
    if [[ "$OVERWRITE_TOOLS" == "true" ]]; then
        echo -e "${BLUE}Mode:${NC} Standardize tool configurations"
    else
        echo -e "${BLUE}Mode:${NC} Smart merge (preserve existing configurations)"
    fi
    echo ""
    
    check_target_directory
    setup_adaptive_configuration
    update_package_json
    install_dependencies
    cleanup_scripts
    
    echo ""
    print_status "Setup complete! Now running development environment setup..."
    echo ""
    
    run_setup
    
    echo ""
    echo "=============================================="
    print_success "🎉 Adaptive Quality Gate Setup Complete!"
    echo ""
    echo -e "${BLUE}What was installed:${NC}"
    echo "✓ Adaptive project detection and configuration"
    echo "✓ Smart pre-commit hooks based on your project"
    echo "✓ Universal validation script (works with any project type)"
    echo "✓ Phase-based quality gate progression system"
    echo "✓ Customizable .quality-config.yaml"
    if [[ "$OVERWRITE_TOOLS" == "true" ]]; then
        echo "✓ Tool configurations (black, mypy, etc.) replaced with template standards"
    else
        echo "✓ Tool configurations merged preserving existing settings"
    fi
    
    if [[ -f ".quality-config.yaml" ]]; then
        local project_type=$(python3 -c "
import yaml
with open('.quality-config.yaml', 'r') as f:
    config = yaml.safe_load(f)
print(config.get('project', {}).get('type', 'unknown'))
" 2>/dev/null || echo "detected")
        echo "✓ Project type: $project_type"
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review and customize: .quality-config.yaml"
    echo "2. Test the setup: ./scripts/validate-adaptive.sh"
    echo "3. View current configuration: ./scripts/detect-project-type.sh"
    echo "4. Start developing with quality gates active!"
    echo ""
    echo -e "${YELLOW}Configuration files:${NC}"
    echo "  📋 .quality-config.yaml - Main configuration (customize as needed)"
    echo "  🔧 .pre-commit-config.yaml - Generated based on your project"
    echo "  📝 DEVELOPMENT.md - Workflow documentation"
    echo ""
    print_success "Happy coding with adaptive quality gates! 🚀"
}

# Run main function
main "$@"