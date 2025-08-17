# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is an **Adaptive Quality Gate Template System** that intelligently adapts to any project structure (TypeScript, Python, full-stack, or hybrid) and provides graduated quality gate enforcement. The system auto-detects project types and generates appropriate configurations, tools, and workflows.

### Key Innovation: Smart Adaptation
- **Auto-detects** project structure and technologies
- **Generates** project-specific configurations  
- **Adapts** quality checks to only run relevant tools
- **Scales** from single-language to complex full-stack projects

## Key Commands

### Adaptive Template Application
```bash
# Apply adaptive template to any project (auto-detects type)
./setup-new-project.sh

# Create new projects with adaptive configuration
./create-standardized-project.sh [project-name] [project-type]
# Types: fullstack, frontend, backend, typescript, python

# Install PyCharm template
./create-pycharm-template.sh
```

### Project Structure Detection
```bash
# Detect current project structure and technologies
./scripts/detect-project-type.sh

# Get detection results as JSON
./scripts/detect-project-type.sh json

# Get only project type
./scripts/detect-project-type.sh type
```

### Adaptive Configuration Management
```bash
# Generate/regenerate adaptive configurations
./scripts/generate-config.sh

# Update existing configuration
./scripts/generate-config.sh update

# Universal validation (adapts to project type)
./scripts/validate-adaptive.sh

# Run validation for specific components
./scripts/validate-adaptive.sh frontend
./scripts/validate-adaptive.sh backend
./scripts/validate-adaptive.sh security
```

### Quality Gate Management (Generated Projects)
```bash
# Universal validation (adapts to project type and current phase)
./scripts/validate-adaptive.sh     # Run all applicable quality checks
npm run validate                   # Same as above
npm run quality:check              # Same as above

# Phase-based quality gate management
./scripts/quality-gate-manager.sh status       # Show current phase and configuration
./scripts/quality-gate-manager.sh advance      # Move to next quality gate phase
./scripts/quality-gate-manager.sh set-phase 2  # Set specific phase (0-3)
./scripts/quality-gate-manager.sh baseline     # Establish quality baseline
./scripts/quality-gate-manager.sh check        # Check for quality regressions

# Feature management
./scripts/quality-gate-manager.sh enable coverage-ratchet
./scripts/quality-gate-manager.sh enable security-scanning
./scripts/quality-gate-manager.sh disable mypy

# Adaptive development commands (generated based on project structure)
npm run dev                        # Starts detected services
npm run lint:fix                   # Fixes issues in detected languages
npm run test                       # Runs detected test frameworks
```

## Architecture Overview

### Adaptive Template System Structure
```
template-files/
├── scripts/
│   ├── detect-project-type.sh           # Smart project structure detection
│   ├── generate-config.sh               # Adaptive configuration generator
│   └── validate-adaptive.sh             # Universal validation script
├── .quality-config.yaml.template        # User-customizable configuration template
├── setup-dev.sh                         # Enhanced adaptive setup script
└── configs/                             # Language-specific configurations
```

### Generated Adaptive Project Structure
**The structure adapts based on detected project type:**

#### Full-Stack Project
```
project-name/
├── .quality-config.yaml        # Main adaptive configuration
├── scripts/                    # Adaptive quality scripts
│   ├── detect-project-type.sh  # Project structure detection
│   ├── generate-config.sh      # Configuration management
│   └── validate-adaptive.sh    # Universal validation
├── frontend/                   # Auto-detected React TypeScript
│   └── package.json           # Adaptive scripts added
├── backend/                    # Auto-detected FastAPI Python
│   ├── .venv/                 # Isolated Python environment
│   └── requirements.txt       # Python dependencies
├── .pre-commit-config.yaml    # Generated based on detected languages
└── package.json              # Root scripts (adaptive)
```

#### TypeScript-Only Project
```
project-name/
├── .quality-config.yaml        # Configured for TypeScript only
├── scripts/                    # Same adaptive scripts
├── src/                        # TypeScript source
├── .pre-commit-config.yaml    # Only TypeScript/ESLint hooks
└── package.json              # TypeScript-focused scripts
```

#### Python-Only Project  
```
project-name/
├── .quality-config.yaml        # Configured for Python only
├── scripts/                    # Same adaptive scripts
├── app/ or src/               # Python source
├── .pre-commit-config.yaml    # Only Python hooks (Black, flake8, etc.)
└── requirements.txt           # Python dependencies
```

### Adaptive Quality Gate System
The system intelligently activates only relevant tools with graduated enforcement:

- **Smart Detection**: Auto-discovers languages, frameworks, and project structure
- **Adaptive Hooks**: Pre-commit hooks include only relevant tools
- **Universal Validation**: Single script that runs applicable quality checks
- **Graduated Enforcement**: 4-phase progression system (0-3)
- **Baseline Tracking**: Prevents regressions while allowing legacy issues
- **Changed-Files-Only**: Phase 1+ enforces quality only on modified code
- **Configuration-Driven**: All behavior controlled via `.quality-config.yaml`

#### Quality Gate Phases
**Phase 0: Baseline & Stabilization**
- Establish quality baseline for current codebase
- Prevent any regressions from documented baseline
- Allow legacy issues but block new problems
- Focus: Stability and regression prevention

**Phase 1: Changed-Code-Only Enforcement**
- Strict quality enforcement for new/modified files only
- Legacy code generates warnings but doesn't block
- Gradual typing adoption for new code
- Focus: Perfect new code, gradual legacy improvement

**Phase 2: Ratchet & Expand Scope**
- Repository-wide enforcement for most tools
- Coverage ratchet requires gradual improvement
- Module-by-module improvement campaigns
- Focus: Progressive improvement across entire codebase

**Phase 3: Normalize & Harden**
- Full strict enforcement across entire codebase
- All quality gates blocking, no bypass options
- Zero technical debt tolerance
- Focus: Production-ready quality standards

## Technology Stack

### Frontend
- React 18+ with TypeScript
- Vite for fast builds
- ESLint + Prettier for code quality
- Jest/Vitest for testing

### Backend
- FastAPI (Python 3.11+)
- Black + isort for code formatting
- Flake8 + MyPy for linting and type checking
- pytest for testing
- Isolated virtual environments

### Infrastructure
- Pre-commit hooks with auto-fix capabilities
- GitHub Actions CI/CD workflows
- Docker-ready configurations
- Cross-platform compatibility (macOS, Linux, Windows)

## Development Workflow

### For Template Development
1. Modify configurations in `template-files/`
2. Test changes by creating a sample project
3. Update documentation and scripts
4. Ensure PyCharm template compatibility

### For Generated Projects
1. Run `./setup-dev.sh --with-quality-gates` once
2. Develop normally with `npm run dev`
3. Before committing: `npm run quality:gate`
4. Commit (pre-commit hooks auto-run and must pass)
5. Push (CI validates without auto-fixing)

## Configuration Files

### Core Templates
- **`.pre-commit-config.yaml`**: Configures local quality checks with auto-fixing
- **`setup-dev.sh`**: One-command environment setup script
- **`DEVELOPMENT.md`**: Complete workflow guide for generated projects
- **`pyproject.toml`**: Python tool configuration (Black, isort, MyPy)
- **`quality-standardized.yml`**: GitHub Actions workflow

### Project Scripts
All generated projects include standardized npm scripts for:
- Development servers (`npm run dev`)
- Quality checks (`npm run quality:gate`)
- Individual tool execution (`npm run frontend:lint:fix`)
- Environment setup (`npm run setup:dev`)

## Adaptive Configuration System

### Main Configuration File: `.quality-config.yaml`
```yaml
# User-customizable settings
quality_gates:
  current_phase: 0              # 0=Baseline, 1=Changed-only, 2=Ratchet, 3=Strict
  auto_progression: false       # Automatic phase advancement

# Tool enablement (auto-detected but user-overridable)
tools:
  frontend:
    enabled: auto               # auto, true, false
    eslint:
      enabled: auto
      auto_fix: true
    typescript:
      enabled: auto
      strict_mode: false        # Enable in higher phases
      
  backend:
    enabled: auto
    python:
      black:
        enabled: true
      mypy:
        enabled: false          # Enable gradually
        
# Testing configuration        
testing:
  unit:
    enabled: auto
    coverage_required: false    # Enable in Phase 2+
  e2e:
    enabled: auto              # Auto-enable if frontend detected
```

### Project Type Detection Examples
```bash
# TypeScript React project
./scripts/detect-project-type.sh
# Output: frontend-typescript (React detected)

# Python FastAPI project  
./scripts/detect-project-type.sh
# Output: backend-python (FastAPI detected)

# Full-stack project
./scripts/detect-project-type.sh  
# Output: fullstack (frontend/ + backend/ detected)
```

### Adaptive Behavior Examples
- **TypeScript Project**: Only ESLint, TypeScript, Jest hooks and validation
- **Python Project**: Only Black, isort, flake8, pytest hooks and validation  
- **Full-Stack Project**: All tools active, coordinated scripts for both environments
- **Generic Project**: Minimal hooks, universal file checks only

### User Customization
Users can override any auto-detected settings:
```bash
# Edit main configuration
vim .quality-config.yaml

# Regenerate configurations after changes
./scripts/generate-config.sh update

# Test new configuration
./scripts/validate-adaptive.sh
```

## Graduated Quality Gate Workflow

### Initial Setup
```bash
# Apply template to project
./setup-new-project.sh

# Initialize quality gate system (Phase 0)
./scripts/quality-gate-manager.sh init

# Establish baseline for current code quality
./scripts/quality-gate-manager.sh baseline
```

### Development Workflow by Phase

#### Phase 0: Baseline Mode
```bash
# All code validated, regressions blocked
./scripts/validate-adaptive.sh
# Shows: "Phase 0: baseline maintained" or "Phase 0: regression detected"

# When stable, advance to Phase 1
./scripts/quality-gate-manager.sh advance
```

#### Phase 1: Changed-Code-Only
```bash
# Only validates modified files
./scripts/validate-adaptive.sh
# Shows: "Phase 1: 3 changed files validated" or "Phase 1: no changed files"

# Perfect new code, gradual legacy improvement
git add . && git commit  # Pre-commit hooks run on changed files only
```

#### Phase 2: Repository-Wide + Ratcheting
```bash
# Full validation + coverage improvement required
./scripts/validate-adaptive.sh
# Shows: "Phase 2: coverage ratchet check" + full validation

# Enable additional features
./scripts/quality-gate-manager.sh enable coverage-ratchet
./scripts/quality-gate-manager.sh enable security-scanning
```

#### Phase 3: Full Strict Enforcement
```bash
# Zero tolerance, production-ready standards
./scripts/validate-adaptive.sh
# Shows: "Phase 3: strict enforcement" - all gates blocking

# No bypass options, maximum quality assurance
```

### Phase Management
```bash
# View current phase and next steps
./scripts/quality-gate-manager.sh status

# Manual phase control
./scripts/quality-gate-manager.sh set-phase 2
./scripts/quality-gate-manager.sh rollback

# Feature toggle
./scripts/quality-gate-manager.sh enable mypy
./scripts/quality-gate-manager.sh disable strict-typescript
```

## Important Notes

- **Auto-Detection**: Project structure is detected on setup and encoded in `.quality-config.yaml`
- **User Control**: All auto-detected settings can be overridden by editing configuration
- **Universal Scripts**: Same validation and setup scripts work across all project types
- **Graduated Enforcement**: Quality gates can be progressed incrementally without disruption
- **Baseline Protection**: Prevents regressions while allowing documented legacy issues
- **Changed-Files-Only**: Phase 1+ focuses on new/modified code for rapid iteration
- **Backward Compatibility**: Existing projects continue working during template updates
- **Cross-Platform**: All adaptive scripts maintain cross-platform compatibility