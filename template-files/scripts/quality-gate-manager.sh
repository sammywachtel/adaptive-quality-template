#!/bin/bash

# Quality Gate Manager - Graduated Enforcement System
# Manages phase progression, baseline tracking, and quality gate configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Global configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
CONFIG_FILE=".quality-config.yaml"
BASELINE_FILE=".quality-baseline.json"

# Function to print formatted messages
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══ $1 ═══${NC}"
}

print_section() {
    echo -e "\n${CYAN}▶ $1${NC}"
}

print_status() {
    echo -e "${BLUE}  ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}  ✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}  ❌${NC} $1"
}

print_phase() {
    local phase="$1"
    local description="$2"
    echo -e "${MAGENTA}  📊 Phase $phase:${NC} $description"
}

# Function to read configuration values
read_config() {
    local key="$1"
    local default_value="${2:-}"
    
    if [[ -f "$CONFIG_FILE" ]] && command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
    keys = '$key'.split('.')
    value = config
    for k in keys:
        if isinstance(value, dict):
            value = value.get(k, {})
        else:
            value = {}
    if value == {} or value is None:
        print('$default_value')
    else:
        print(value)
except Exception as e:
    print('$default_value')
" 2>/dev/null
    else
        echo "$default_value"
    fi
}

# Function to update configuration values
update_config() {
    local key="$1"
    local value="$2"
    
    if [[ -f "$CONFIG_FILE" ]] && command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
    
    keys = '$key'.split('.')
    current = config
    for k in keys[:-1]:
        if k not in current:
            current[k] = {}
        current = current[k]
    
    # Convert value to appropriate type
    value = '$value'
    if value.lower() == 'true':
        value = True
    elif value.lower() == 'false':
        value = False
    elif value.isdigit():
        value = int(value)
    
    current[keys[-1]] = value
    
    with open('$CONFIG_FILE', 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    
    print(f'Updated {keys[-1]} to {value}')
except Exception as e:
    print(f'Error updating config: {e}', file=sys.stderr)
    sys.exit(1)
"
    else
        print_error "Cannot update configuration - Python or YAML not available"
        return 1
    fi
}

# Function to get current quality metrics
get_current_metrics() {
    local project_type=$(read_config "project.type" "unknown")
    local has_frontend=$(read_config "project.structure.has_frontend" "false")
    local has_python=$(read_config "project.structure.has_python" "false")
    local frontend_path=$(read_config "project.structure.frontend_path" "frontend")
    local backend_path=$(read_config "project.structure.backend_path" "backend")
    
    local metrics="{}"
    
    # Get frontend metrics if applicable
    if [[ "$has_frontend" == "true" ]]; then
        local eslint_errors=0
        local typescript_errors=0
        
        if [[ -d "$frontend_path" ]]; then
            cd "$frontend_path" 2>/dev/null || true
            
            # Count ESLint errors
            if command -v npm >/dev/null 2>&1 && [[ -f "package.json" ]]; then
                eslint_errors=$(npm run lint 2>&1 | grep -c "error" || echo "0")
            fi
            
            # Count TypeScript errors
            if [[ -f "tsconfig.json" ]]; then
                typescript_errors=$(npx tsc --noEmit 2>&1 | grep -c "error" || echo "0")
            fi
            
            cd "$PROJECT_ROOT"
        fi
        
        metrics=$(echo "$metrics" | jq --arg eslint "$eslint_errors" --arg ts "$typescript_errors" '. + {
            "frontend": {
                "eslint_errors": ($eslint | tonumber),
                "typescript_errors": ($ts | tonumber)
            }
        }')
    fi
    
    # Get backend metrics if applicable
    if [[ "$has_python" == "true" ]]; then
        local flake8_errors=0
        local black_issues=0
        local isort_issues=0
        
        if [[ -d "$backend_path" ]]; then
            cd "$backend_path" 2>/dev/null || true
            
            # Count flake8 errors
            if command -v flake8 >/dev/null 2>&1; then
                flake8_errors=$(flake8 . 2>&1 | wc -l || echo "0")
            fi
            
            # Count Black formatting issues
            if command -v black >/dev/null 2>&1; then
                black_issues=$(black --check --diff . 2>&1 | grep -c "^---" || echo "0")
            fi
            
            # Count isort issues
            if command -v isort >/dev/null 2>&1; then
                isort_issues=$(isort --check-only --diff . 2>&1 | grep -c "^---" || echo "0")
            fi
            
            cd "$PROJECT_ROOT"
        fi
        
        metrics=$(echo "$metrics" | jq --arg flake8 "$flake8_errors" --arg black "$black_issues" --arg isort "$isort_issues" '. + {
            "backend": {
                "flake8_errors": ($flake8 | tonumber),
                "black_issues": ($black | tonumber),
                "isort_issues": ($isort | tonumber)
            }
        }')
    fi
    
    # Add timestamp
    metrics=$(echo "$metrics" | jq --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {
        "timestamp": $timestamp,
        "project_type": "'$project_type'"
    }')
    
    echo "$metrics"
}

# Function to establish baseline
establish_baseline() {
    print_section "Establishing Quality Baseline"
    
    print_status "Scanning current project for quality metrics..."
    local current_metrics=$(get_current_metrics)
    
    # Save baseline
    echo "$current_metrics" | jq '.' > "$BASELINE_FILE"
    
    print_success "Baseline established and saved to $BASELINE_FILE"
    
    # Show baseline summary
    echo ""
    echo -e "${BOLD}Baseline Summary:${NC}"
    
    # Frontend metrics
    local has_frontend=$(echo "$current_metrics" | jq -r '.frontend // empty')
    if [[ -n "$has_frontend" ]]; then
        local eslint_errors=$(echo "$current_metrics" | jq -r '.frontend.eslint_errors // 0')
        local typescript_errors=$(echo "$current_metrics" | jq -r '.frontend.typescript_errors // 0')
        
        echo -e "${YELLOW}Frontend:${NC}"
        echo -e "  ESLint errors: $eslint_errors"
        echo -e "  TypeScript errors: $typescript_errors"
    fi
    
    # Backend metrics
    local has_backend=$(echo "$current_metrics" | jq -r '.backend // empty')
    if [[ -n "$has_backend" ]]; then
        local flake8_errors=$(echo "$current_metrics" | jq -r '.backend.flake8_errors // 0')
        local black_issues=$(echo "$current_metrics" | jq -r '.backend.black_issues // 0')
        local isort_issues=$(echo "$current_metrics" | jq -r '.backend.isort_issues // 0')
        
        echo -e "${YELLOW}Backend:${NC}"
        echo -e "  Flake8 errors: $flake8_errors"
        echo -e "  Black issues: $black_issues"
        echo -e "  Isort issues: $isort_issues"
    fi
    
    echo ""
    print_status "Baseline can be updated anytime with: $0 update-baseline"
}

# Function to check for regressions
check_regressions() {
    if [[ ! -f "$BASELINE_FILE" ]]; then
        print_warning "No baseline found - establishing baseline first"
        establish_baseline
        return 0
    fi
    
    print_section "Checking for Quality Regressions"
    
    local baseline_metrics=$(cat "$BASELINE_FILE")
    local current_metrics=$(get_current_metrics)
    
    local has_regressions=false
    
    # Check frontend regressions
    local baseline_frontend=$(echo "$baseline_metrics" | jq -r '.frontend // empty')
    local current_frontend=$(echo "$current_metrics" | jq -r '.frontend // empty')
    
    if [[ -n "$baseline_frontend" && -n "$current_frontend" ]]; then
        local baseline_eslint=$(echo "$baseline_metrics" | jq -r '.frontend.eslint_errors // 0')
        local current_eslint=$(echo "$current_metrics" | jq -r '.frontend.eslint_errors // 0')
        local baseline_ts=$(echo "$baseline_metrics" | jq -r '.frontend.typescript_errors // 0')
        local current_ts=$(echo "$current_metrics" | jq -r '.frontend.typescript_errors // 0')
        
        if (( current_eslint > baseline_eslint )); then
            print_error "ESLint regression: $current_eslint errors (baseline: $baseline_eslint)"
            has_regressions=true
        else
            print_success "ESLint: $current_eslint errors (baseline: $baseline_eslint)"
        fi
        
        if (( current_ts > baseline_ts )); then
            print_error "TypeScript regression: $current_ts errors (baseline: $baseline_ts)"
            has_regressions=true
        else
            print_success "TypeScript: $current_ts errors (baseline: $baseline_ts)"
        fi
    fi
    
    # Check backend regressions
    local baseline_backend=$(echo "$baseline_metrics" | jq -r '.backend // empty')
    local current_backend=$(echo "$current_metrics" | jq -r '.backend // empty')
    
    if [[ -n "$baseline_backend" && -n "$current_backend" ]]; then
        local baseline_flake8=$(echo "$baseline_metrics" | jq -r '.backend.flake8_errors // 0')
        local current_flake8=$(echo "$current_metrics" | jq -r '.backend.flake8_errors // 0')
        local baseline_black=$(echo "$baseline_metrics" | jq -r '.backend.black_issues // 0')
        local current_black=$(echo "$current_metrics" | jq -r '.backend.black_issues // 0')
        
        if (( current_flake8 > baseline_flake8 )); then
            print_error "Flake8 regression: $current_flake8 errors (baseline: $baseline_flake8)"
            has_regressions=true
        else
            print_success "Flake8: $current_flake8 errors (baseline: $baseline_flake8)"
        fi
        
        if (( current_black > baseline_black )); then
            print_error "Black regression: $current_black issues (baseline: $baseline_black)"
            has_regressions=true
        else
            print_success "Black: $current_black issues (baseline: $baseline_black)"
        fi
    fi
    
    if [[ "$has_regressions" == "true" ]]; then
        echo ""
        print_error "Quality regressions detected!"
        print_status "Fix regressions or update baseline if improvements were made"
        return 1
    else
        echo ""
        print_success "No quality regressions detected"
        return 0
    fi
}

# Function to show current status
show_status() {
    print_header "Quality Gate Status"
    
    # Basic configuration
    local current_phase=$(read_config "quality_gates.current_phase" "0")
    local project_type=$(read_config "project.type" "unknown")
    local has_frontend=$(read_config "project.structure.has_frontend" "false")
    local has_backend=$(read_config "project.structure.has_backend" "false")
    
    echo -e "${BOLD}Project Configuration:${NC}"
    echo -e "  Type: $project_type"
    echo -e "  Frontend: $([[ "$has_frontend" == "true" ]] && echo "✅ Detected" || echo "❌ Not detected")"
    echo -e "  Backend: $([[ "$has_backend" == "true" ]] && echo "✅ Detected" || echo "❌ Not detected")"
    
    echo ""
    echo -e "${BOLD}Current Quality Gate Phase: $current_phase${NC}"
    
    case "$current_phase" in
        "0")
            print_phase "0" "Baseline & Stabilization"
            echo -e "    • Establish quality baseline"
            echo -e "    • Prevent regressions from current state"
            echo -e "    • Mandatory pre-commit hooks"
            echo -e "    • Allow legacy issues with baseline tolerance"
            ;;
        "1")
            print_phase "1" "Changed-Code-Only Enforcement"
            echo -e "    • Strict enforcement for new/modified code"
            echo -e "    • Warnings for unchanged legacy code"
            echo -e "    • Gradual typing adoption"
            echo -e "    • Per-file quality tracking"
            ;;
        "2")
            print_phase "2" "Ratchet & Expand Scope"
            echo -e "    • Repo-wide enforcement for most tools"
            echo -e "    • Coverage ratchet system active"
            echo -e "    • Progressive rule tightening"
            echo -e "    • Module-by-module improvement campaigns"
            ;;
        "3")
            print_phase "3" "Normalize & Harden"
            echo -e "    • All quality gates blocking"
            echo -e "    • No bypass options available"
            echo -e "    • Full strict enforcement"
            echo -e "    • Branch protection rules active"
            ;;
    esac
    
    # Show baseline status
    echo ""
    if [[ -f "$BASELINE_FILE" ]]; then
        local baseline_date=$(jq -r '.timestamp // "unknown"' "$BASELINE_FILE" 2>/dev/null || echo "unknown")
        print_success "Quality baseline established: $baseline_date"
    else
        print_warning "No quality baseline found - run: $0 establish-baseline"
    fi
    
    # Show next steps
    echo ""
    echo -e "${BOLD}Available Actions:${NC}"
    echo -e "  ${CYAN}$0 advance${NC}           - Move to next phase"
    echo -e "  ${CYAN}$0 set-phase N${NC}       - Set specific phase (0-3)"
    echo -e "  ${CYAN}$0 check-regressions${NC} - Check for quality regressions"
    echo -e "  ${CYAN}$0 establish-baseline${NC} - (Re)establish quality baseline"
    echo -e "  ${CYAN}$0 enable FEATURE${NC}    - Enable specific feature"
    echo -e "  ${CYAN}$0 disable FEATURE${NC}   - Disable specific feature"
}

# Function to advance to next phase
advance_phase() {
    local current_phase=$(read_config "quality_gates.current_phase" "0")
    local next_phase=$((current_phase + 1))
    
    if (( next_phase > 3 )); then
        print_warning "Already at maximum phase (3)"
        return 1
    fi
    
    print_section "Advancing to Phase $next_phase"
    
    # Check if ready for advancement
    case "$current_phase" in
        "0")
            if [[ ! -f "$BASELINE_FILE" ]]; then
                print_error "Cannot advance: No baseline established"
                print_status "Run: $0 establish-baseline first"
                return 1
            fi
            
            # Check for regressions
            if ! check_regressions; then
                print_error "Cannot advance: Quality regressions detected"
                print_status "Fix regressions before advancing to Phase 1"
                return 1
            fi
            ;;
        "1")
            print_status "Checking readiness for Phase 2..."
            # Add Phase 1 completion checks here
            ;;
        "2")
            print_status "Checking readiness for Phase 3..."
            # Add Phase 2 completion checks here
            ;;
    esac
    
    # Update phase
    update_config "quality_gates.current_phase" "$next_phase"
    
    # Enable phase-specific features
    case "$next_phase" in
        "1")
            update_config "quality_gates.phases.phase_1.changed_files_only" "true"
            update_config "quality_gates.phases.phase_1.new_code_strict" "true"
            print_status "Enabled changed-files-only enforcement"
            ;;
        "2")
            update_config "quality_gates.phases.phase_2.coverage_ratchet" "true"
            update_config "quality_gates.phases.phase_2.repo_wide_enforcement" "true"
            update_config "tools.backend.python.mypy.enabled" "true"
            print_status "Enabled coverage ratchet and repo-wide enforcement"
            ;;
        "3")
            update_config "quality_gates.phases.phase_3.all_gates_blocking" "true"
            update_config "quality_gates.phases.phase_3.no_bypasses" "true"
            update_config "tools.frontend.typescript.strict_mode" "true"
            print_status "Enabled strict mode and blocking gates"
            ;;
    esac
    
    print_success "Advanced to Phase $next_phase"
    
    # Regenerate configurations for new phase
    print_status "Regenerating configurations for Phase $next_phase..."
    "$SCRIPT_DIR/generate-config.sh" update >/dev/null
    
    print_success "Phase $next_phase activation complete!"
    
    # Show new status
    show_status
}

# Function to set specific phase
set_phase() {
    local target_phase="$1"
    
    if [[ ! "$target_phase" =~ ^[0-3]$ ]]; then
        print_error "Invalid phase: $target_phase (must be 0-3)"
        return 1
    fi
    
    local current_phase=$(read_config "quality_gates.current_phase" "0")
    
    if [[ "$target_phase" == "$current_phase" ]]; then
        print_warning "Already at Phase $target_phase"
        return 0
    fi
    
    print_section "Setting Phase to $target_phase"
    
    # Update phase
    update_config "quality_gates.current_phase" "$target_phase"
    
    # Configure phase-specific settings
    case "$target_phase" in
        "0")
            update_config "quality_gates.phases.phase_0.enforce_baseline" "true"
            update_config "quality_gates.phases.phase_0.allow_legacy_issues" "true"
            ;;
        "1")
            update_config "quality_gates.phases.phase_1.changed_files_only" "true"
            update_config "quality_gates.phases.phase_1.new_code_strict" "true"
            ;;
        "2")
            update_config "quality_gates.phases.phase_2.coverage_ratchet" "true"
            update_config "quality_gates.phases.phase_2.repo_wide_enforcement" "true"
            ;;
        "3")
            update_config "quality_gates.phases.phase_3.all_gates_blocking" "true"
            update_config "quality_gates.phases.phase_3.no_bypasses" "true"
            ;;
    esac
    
    print_success "Phase set to $target_phase"
    
    # Regenerate configurations
    print_status "Regenerating configurations..."
    "$SCRIPT_DIR/generate-config.sh" update >/dev/null
    
    print_success "Phase $target_phase configuration complete!"
}

# Function to enable/disable features
toggle_feature() {
    local action="$1"
    local feature="$2"
    
    if [[ -z "$feature" ]]; then
        print_error "Feature name required"
        echo "Available features: coverage-ratchet, security-scanning, e2e-testing, mypy, strict-typescript"
        return 1
    fi
    
    local value="true"
    [[ "$action" == "disable" ]] && value="false"
    
    case "$feature" in
        "coverage-ratchet")
            update_config "metrics.coverage.ratchet_enabled" "$value"
            ;;
        "security-scanning")
            update_config "tools.security.vulnerability_scanning" "$value"
            ;;
        "e2e-testing")
            update_config "testing.e2e.enabled" "$value"
            ;;
        "mypy")
            update_config "tools.backend.python.mypy.enabled" "$value"
            ;;
        "strict-typescript")
            update_config "tools.frontend.typescript.strict_mode" "$value"
            ;;
        *)
            print_error "Unknown feature: $feature"
            return 1
            ;;
    esac
    
    print_success "${action}d $feature"
    
    # Regenerate configurations
    "$SCRIPT_DIR/generate-config.sh" update >/dev/null
}

# Initialize quality gate system
initialize_system() {
    print_header "Initializing Quality Gate System"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Quality configuration not found"
        print_status "Run: ./scripts/generate-config.sh first"
        return 1
    fi
    
    print_status "Setting up Phase 0 (Baseline & Stabilization)"
    
    # Ensure Phase 0 configuration
    update_config "quality_gates.current_phase" "0"
    update_config "quality_gates.phases.phase_0.enforce_baseline" "true"
    update_config "quality_gates.phases.phase_0.allow_legacy_issues" "true"
    update_config "quality_gates.phases.phase_0.block_regressions" "true"
    
    # Establish baseline if not exists
    if [[ ! -f "$BASELINE_FILE" ]]; then
        establish_baseline
    fi
    
    print_success "Quality Gate system initialized"
    show_status
}

# Main command handler
main() {
    case "${1:-status}" in
        "status")
            show_status
            ;;
        "init"|"initialize")
            initialize_system
            ;;
        "advance")
            advance_phase
            ;;
        "set-phase")
            if [[ -z "$2" ]]; then
                print_error "Phase number required (0-3)"
                exit 1
            fi
            set_phase "$2"
            ;;
        "establish-baseline"|"baseline")
            establish_baseline
            ;;
        "update-baseline")
            establish_baseline
            ;;
        "check-regressions"|"check")
            check_regressions
            ;;
        "enable")
            toggle_feature "enable" "$2"
            ;;
        "disable")
            toggle_feature "disable" "$2"
            ;;
        "rollback")
            local current_phase=$(read_config "quality_gates.current_phase" "0")
            local prev_phase=$((current_phase - 1))
            if (( prev_phase >= 0 )); then
                set_phase "$prev_phase"
            else
                print_warning "Already at minimum phase (0)"
            fi
            ;;
        "help")
            echo "Quality Gate Manager - Graduated Enforcement System"
            echo ""
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  status              Show current quality gate status (default)"
            echo "  init                Initialize quality gate system"
            echo "  advance             Move to next quality gate phase"
            echo "  set-phase N         Set specific phase (0-3)"
            echo "  establish-baseline  Establish quality baseline"
            echo "  check-regressions   Check for quality regressions"
            echo "  enable FEATURE      Enable specific feature"
            echo "  disable FEATURE     Disable specific feature"
            echo "  rollback            Move to previous phase"
            echo "  help                Show this help message"
            echo ""
            echo "Phases:"
            echo "  0  Baseline & Stabilization"
            echo "  1  Changed-Code-Only Enforcement"
            echo "  2  Ratchet & Expand Scope"
            echo "  3  Normalize & Harden"
            echo ""
            echo "Features:"
            echo "  coverage-ratchet, security-scanning, e2e-testing, mypy, strict-typescript"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check prerequisites
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Quality configuration not found: $CONFIG_FILE"
    print_status "Run: ./scripts/generate-config.sh to create configuration"
    exit 1
fi

# Check for required tools
if ! command -v python3 >/dev/null 2>&1; then
    print_error "Python 3 is required for configuration management"
    exit 1
fi

if ! python3 -c "import yaml" 2>/dev/null; then
    print_error "PyYAML is required for configuration management"
    print_status "Install with: pip install PyYAML"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is required for baseline management"
    print_status "Install with: brew install jq (macOS) or apt install jq (Ubuntu)"
    exit 1
fi

# Run main function
main "$@"