#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    # Check for common project indicators
    if [[ ! -f "package.json" && ! -f "pyproject.toml" && ! -f "requirements.txt" && ! -d "src" ]]; then
        print_error "No project indicators found. Please run this script from your project root directory."
        print_status "Looking for: package.json, pyproject.toml, requirements.txt, or src/ directory"
        exit 1
    fi
    
    print_success "Project root detected - proceeding with adaptive setup"
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
    chmod +x scripts/*.sh
    print_status "✓ Copied adaptive scripts"
    
    # Generate project-specific configurations
    print_status "Generating adaptive configurations..."
    ./scripts/generate-config.sh
    
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
            
            if [[ -d "$backend_path" ]]; then
                cp "$TEMPLATE_DIR/backend/requirements-dev.txt" "$backend_path/" 2>/dev/null || true
                cp "$TEMPLATE_DIR/backend/pyproject.toml" "$backend_path/" 2>/dev/null || true
                print_status "✓ Copied Python backend configuration"
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

# Install required dependencies
install_dependencies() {
    print_status "Installing required dependencies..."
    
    # Install concurrently if not already present
    if ! npm list concurrently &> /dev/null; then
        npm install --save-dev concurrently
        print_status "✓ Installed concurrently"
    fi
    
    print_success "Dependencies installed"
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
    
    check_target_directory
    setup_adaptive_configuration
    update_package_json
    install_dependencies
    
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