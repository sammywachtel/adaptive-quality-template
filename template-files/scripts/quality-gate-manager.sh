#!/bin/bash

# Quality Gate Phase Management Script
# Manages graduated quality gate progression with automatic analysis and recommendations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
QUALITY_CONFIG_FILE=".quality-config.yaml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Helper functions
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_status $BLUE "$1"
    echo "$(printf '=%.0s' {1..50})"
}

print_success() {
    print_status $GREEN "✅ $1"
}

print_error() {
    print_status $RED "❌ $1"
}

print_warning() {
    print_status $YELLOW "⚠️  $1"
}

print_info() {
    print_status $CYAN "ℹ️  $1"
}

# Get current phase from configuration
get_current_phase() {
    if [[ ! -f "$QUALITY_CONFIG_FILE" ]]; then
        echo "0"  # Default to baseline phase
        return
    fi
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml
try:
    with open('$QUALITY_CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f) or {}
    print(config.get('quality_gates', {}).get('current_phase', 0))
except:
    print(0)
" 2>/dev/null || echo "0"
    else
        # Fallback to basic parsing if Python not available
        grep "current_phase:" "$QUALITY_CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' || echo "0"
    fi
}

# Show current phase status and metrics
show_phase_status() {
    local current_phase=$(get_current_phase)
    
    print_header "🎯 Quality Gate Phase Status"
    
    echo ""
    print_status $CYAN "Current Phase: $current_phase"
    
    case "$current_phase" in
        "0")
            print_status $BLUE "Phase 0: Baseline & Stabilization"
            echo "  • Goal: Prevent regressions from documented baseline"
            echo "  • Enforcement: No regressions allowed, legacy issues documented"
            echo "  • Duration: 1-3 days (immediate setup)"
            ;;
        "1") 
            print_status $BLUE "Phase 1: Changed-Code-Only Enforcement"
            echo "  • Goal: Perfect new code, gradual legacy improvement"
            echo "  • Enforcement: Strict quality for modified files only"
            echo "  • Duration: 1-2 weeks (depends on development velocity)"
            ;;
        "2")
            print_status $BLUE "Phase 2: Repository-Wide + Ratcheting"  
            echo "  • Goal: Systematic improvement across entire codebase"
            echo "  • Enforcement: Repository-wide for most tools, coverage ratcheting"
            echo "  • Duration: 2-4 weeks (depends on tech debt)"
            ;;
        "3")
            print_status $BLUE "Phase 3: Full Strict Enforcement"
            echo "  • Goal: Production-ready standards, zero tolerance"
            echo "  • Enforcement: All quality gates blocking, branch protection active"
            echo "  • Duration: Ongoing maintenance"
            ;;
    esac
    
    echo ""
    print_status $CYAN "Available Commands:"
    echo "  • quality-gate-manager.sh advance    → Move to next phase"
    echo "  • quality-gate-manager.sh set-phase N → Jump to specific phase"
    echo "  • quality-gate-manager.sh baseline   → Establish quality baseline"  
    echo "  • quality-gate-manager.sh check      → Check current phase requirements"
    
    # Show next phase info if not at max
    if [[ $current_phase -lt 3 ]]; then
        local next_phase=$((current_phase + 1))
        echo ""
        print_status $YELLOW "Next Phase ($next_phase):"
        case "$next_phase" in
            "1") echo "  → Changed-files-only enforcement (perfect new code)" ;;
            "2") echo "  → Repository-wide enforcement with ratcheting" ;;
            "3") echo "  → Full strict enforcement (production ready)" ;;
        esac
        print_info "Run 'quality-gate-manager.sh advance' to progress"
    else
        echo ""
        print_success "🎉 You're at the highest phase! All quality gates are fully active."
    fi
}

# Main command router
main() {
    case "${1:-status}" in
        "status")
            show_phase_status
            ;;
        "help"|"--help"|"-h")
            echo "Quality Gate Phase Manager"
            echo ""
            echo "COMMANDS:"
            echo "  status      Show current phase and progression information"
            echo "  help        Show this help message"
            echo ""
            echo "COMING SOON:"
            echo "  advance     Move to next phase"
            echo "  set-phase   Set specific phase" 
            echo "  baseline    Establish quality baseline"
            echo "  check       Check current phase requirements"
            ;;
        *)
            print_error "Command not yet implemented: $1"
            print_info "Currently available: status, help"
            print_info "Full implementation coming soon..."
            ;;
    esac
}

# Run main function with all arguments
main "$@"