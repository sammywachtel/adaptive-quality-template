# Adaptive Quality Gate Template System

🎯 **Universal template that intelligently adapts to any project type** - TypeScript, Python, full-stack, or hybrid projects.

[![Quality Gate](https://img.shields.io/badge/Quality%20Gate-Adaptive-brightgreen)](https://github.com/sammywachtel/adaptive-quality-template)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cross Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/sammywachtel/adaptive-quality-template)

> **⚠️ Work in Progress**: This project is under active development. Features and documentation are being refined and may change.

## 🚀 Key Innovation: Smart Adaptation

This isn't just another template - it's an **intelligent system** that:

- **🔍 Auto-detects** your project structure and technologies
- **⚡ Generates** project-specific configurations dynamically  
- **🎯 Adapts** quality checks to only run relevant tools
- **📈 Scales** from single-language to complex full-stack projects
- **🎛️ Provides** graduated quality gate enforcement (4 phases)

## 🎯 Quick Start

### Apply to Any Existing Project
```bash
# Clone the template
git clone https://github.com/sammywachtel/adaptive-quality-template.git
cd adaptive-quality-template

# Apply to any project (auto-detects type)
./setup-new-project.sh /path/to/your/project
./setup-new-project.sh .                     # For current directory

# With tool configuration options:
./setup-new-project.sh /path/to/project --overwrite-tools  # Replace tool configs with template standards
./setup-new-project.sh /path/to/project                    # Preserve existing tool configs (default)

# Get help and examples:
./setup-new-project.sh --help
```

### Create New Projects  
```bash
# Create with auto-configuration
./create-standardized-project.sh my-app fullstack
./create-standardized-project.sh my-lib typescript  
./create-standardized-project.sh my-api python
```

## ⚙️ Python Configuration Handling

The template intelligently handles existing `pyproject.toml` files with two modes:

### Default: Smart Merge (Preserves Your Settings)
```bash
./setup-new-project.sh
```
**What it preserves:**
- ✅ `[build-system]` and `[project]` sections (never touched)
- ✅ Existing tool configurations and your custom settings
- ✅ Custom tools like `[tool.hatch]`, `[tool.poetry]`, etc.

**What it adds:**
- ➕ Missing tool configurations (isort, coverage, etc.)
- ➕ Additional settings for existing tools (non-conflicting)

### Overwrite Mode: Standardize Tool Configs
```bash
./setup-new-project.sh --overwrite-tools
```
**What it preserves:**
- ✅ `[build-system]` and `[project]` sections (never touched)  
- ✅ Custom tools like `[tool.hatch]`, `[tool.poetry]`, etc.

**What it replaces:**
- 🔄 `[tool.black]`, `[tool.mypy]`, `[tool.isort]` with template standards
- 🔄 `[tool.pytest]`, `[tool.coverage]`, `[tool.flake8]` with template standards

### Example: Your File Before/After

**Before (your existing pyproject.toml):**
```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-package"
version = "1.0.0"

[tool.mypy]
python_version = "3.9"
warn_return_any = false
```

**After with default merge:**
```toml
[build-system]  # ✅ Preserved
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]  # ✅ Preserved
name = "my-package"
version = "1.0.0"

[tool.mypy]  # ✅ Your settings kept, template settings added
python_version = "3.9"        # Your setting preserved
warn_return_any = false       # Your setting preserved
warn_unused_configs = true    # Template setting added

[tool.black]  # ➕ New from template
line-length = 88
target-version = ["py311"]
```

**After with --overwrite-tools:**
```toml
[build-system]  # ✅ Preserved
requires = ["hatchling"] 
build-backend = "hatchling.build"

[project]  # ✅ Preserved
name = "my-package"
version = "1.0.0"

[tool.mypy]  # 🔄 Completely replaced with template standards
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
# ... full template mypy config

[tool.black]  # ➕ Added from template
line-length = 88
target-version = ["py311"]
```

## 🧠 Smart Project Detection

The system automatically detects and configures for:

| Project Type | Detection Criteria | Generated Configuration |
|--------------|-------------------|------------------------|
| **Full-Stack** | `frontend/` + `backend/` | React + FastAPI setup |
| **TypeScript** | `src/` + `.ts` files | ESLint + TypeScript only |
| **Python** | `requirements.txt` or `pyproject.toml` | Black + flake8 + mypy |
| **Hybrid** | Mixed technologies | Adaptive combination |

### Example Detection Output
```bash
$ ./scripts/detect-project-type.sh json
{
  "project_type": "fullstack",
  "has_frontend": true,
  "has_backend": true,
  "languages": ["typescript", "python"],
  "frameworks": ["react", "fastapi"],
  "confidence": "high"
}
```

## 🎛️ Graduated Quality Gate System

### 4-Phase Progression for Zero-Disruption Adoption

**Phase 0: Baseline & Stabilization**
- 📊 Establish quality baseline for current codebase
- 🚫 Prevent any regressions from documented baseline  
- ⚠️ Allow legacy issues but block new problems
- 🎯 Focus: Stability and regression prevention

**Phase 1: Changed-Code-Only Enforcement**  
- ✨ Strict quality enforcement for new/modified files only
- 📊 Legacy code generates warnings but doesn't block
- ⚡ **Performance**: Sub-10-second feedback for large codebases
- 🎯 Focus: Perfect new code, gradual legacy improvement

**Phase 2: Ratchet & Expand Scope**
- 📈 Repository-wide enforcement for most tools
- 📊 Coverage ratchet requires gradual improvement  
- 🎯 Module-by-module improvement campaigns
- 🎯 Focus: Progressive improvement across entire codebase

**Phase 3: Normalize & Harden**
- 🔒 Full strict enforcement across entire codebase
- 🚫 All quality gates blocking, no bypass options
- 🎯 Zero technical debt tolerance
- 🎯 Focus: Production-ready quality standards

### Phase Management Commands
```bash
# Check current phase and status
./scripts/quality-gate-manager.sh status

# Advance to next phase when ready
./scripts/quality-gate-manager.sh advance

# Set specific phase
./scripts/quality-gate-manager.sh set-phase 2

# Establish baseline for current code
./scripts/quality-gate-manager.sh baseline
```

## 🎯 Universal Validation

**Single script that adapts to any project:**

```bash
# Runs only applicable quality checks
./scripts/validate-adaptive.sh

# Phase 1 example: Only validates changed files
./scripts/validate-adaptive.sh  # ⚡ 8 seconds instead of 3 minutes

# Phase 3 example: Full repository validation
./scripts/validate-adaptive.sh  # 🔒 Complete quality enforcement
```

## 📁 Adaptive Project Structure

### Generated Full-Stack Project
```
my-fullstack-app/
├── .quality-config.yaml        # Main adaptive configuration
├── scripts/                    # Universal quality scripts
│   ├── detect-project-type.sh  # Smart project detection
│   ├── generate-config.sh      # Configuration management
│   ├── quality-gate-manager.sh # Phase management
│   └── validate-adaptive.sh    # Universal validation
├── frontend/                   # Auto-detected React TypeScript
│   └── package.json           # Adaptive scripts added
├── backend/                    # Auto-detected FastAPI Python
│   ├── .venv/                 # Isolated Python environment
│   └── requirements.txt       # Python dependencies
├── .pre-commit-config.yaml    # Generated based on detected languages
├── .github/workflows/          # Adaptive CI workflows
└── package.json              # Root scripts (adaptive)
```

### Generated TypeScript-Only Project
```
my-typescript-app/
├── .quality-config.yaml        # Configured for TypeScript only
├── scripts/                    # Same adaptive scripts
├── src/                        # TypeScript source
├── .pre-commit-config.yaml    # Only TypeScript/ESLint hooks
└── package.json              # TypeScript-focused scripts
```

## 🧠 Intelligent MyPy Dependency Detection

The template automatically detects and configures MyPy type checking with project-specific dependencies:

### How It Works
```bash
# During setup, the system scans requirements files for packages that need type stubs
./scripts/detect-mypy-deps.sh requirements.txt

# Example output for a data science project:
# ["types-jsonschema", "numpy", "scikit-learn"]
```

### Supported Auto-Detection
**Type Stub Packages:**
- `requests` → `types-requests`
- `redis` → `types-redis`
- `pyyaml` → `types-pyyaml`
- `jsonschema` → `types-jsonschema`
- `setuptools` → `types-setuptools`

**Scientific Computing:**
- `numpy`, `scikit-learn`, `pandas`, `scipy` (direct dependencies)

### Result: Smart Pre-commit Config
```yaml
# Auto-generated based on your requirements.txt
- repo: https://github.com/pre-commit/mirrors-mypy
  rev: v1.8.0
  hooks:
    - id: mypy
      args: ["--config-file=pyproject.toml"]
      additional_dependencies:
        - types-jsonschema    # ✅ Auto-detected
        - numpy              # ✅ Auto-detected
        - scikit-learn       # ✅ Auto-detected
      files: '^(src|backend|app)/.*\.py$'
```

### Manual Override
If dependencies aren't auto-detected or you need custom packages:
```yaml
# Edit .pre-commit-config.yaml
additional_dependencies:
  - types-custom-package
  - your-internal-library
```

## 🧪 Universal Test Framework Detection

The template automatically detects and configures your test framework (Jest or Vitest) with intelligent fallback handling:

### How It Works
```bash
# During validation, the system detects your test framework configuration
./scripts/validate-adaptive.sh

# Example detection output:
# ✅ Detected test framework: Vitest
# Running: npm test -- --run --changed
```

### Supported Test Frameworks
**Jest (Automatic Detection):**
- Detects `jest` in package.json dependencies
- Uses `--findRelatedTests` for changed-files-only testing
- Provides Jest-specific error fixes: `npm run test -- [file]`

**Vitest (Automatic Detection):**
- Detects `vitest` in package.json dependencies
- Uses `--run --changed` for changed-files-only testing
- Provides Vitest-specific error fixes: `npm run test -- --run [file]`

**Generic Fallback:**
- Works with any test framework via `npm test`
- Graceful degradation if framework not recognized
- Clear error messages with framework-specific commands

### Smart Test Execution
```bash
# Phase 0: Runs all tests
npm test

# Phase 1: Only tests for changed files (Jest)
npm test -- --findRelatedTests src/changed-file.ts

# Phase 1: Only tests for changed files (Vitest)
npm test -- --run --changed

# Manual override: Test specific files
npm test -- --run src/my-test.spec.ts  # Vitest
npm test -- src/my-test.spec.ts        # Jest
```

### Configuration
```yaml
# .quality-config.yaml
testing:
  unit:
    enabled: auto                    # Auto-detects test framework
    framework: auto                  # "jest", "vitest", or "auto"
    changed_files_only: true         # Phase 1+ optimization
    coverage_required: false         # Enable in Phase 2+
```

### Troubleshooting
**If framework detection fails:**
1. Verify test framework in package.json dependencies
2. Check that npm test script is configured
3. Manually set framework in .quality-config.yaml: `framework: "jest"` or `framework: "vitest"`
4. Run validation with debug: `DEBUG=1 ./scripts/validate-adaptive.sh`

**Both Jest and Vitest installed:**
- Detection prioritizes the framework defined in package.json test script
- Override with explicit configuration: `framework: "vitest"`

## 🎨 ESLint v9 Flat Config Auto-Migration

The template automatically handles ESLint v9's new flat config format with zero manual intervention:

### Automatic Version Detection
```bash
# During setup, the system detects your ESLint version
./setup-new-project.sh

# ESLint v9+ → Generates eslint.config.mjs (flat config)
# ESLint v8 → Keeps .eslintrc.json (legacy format)
```

### Generated Flat Config (ESLint v9+)
```javascript
// eslint.config.mjs (automatically generated)
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // Custom rules auto-configured
    },
  },
);
```

### Smart Migration
**Detects deprecated config:**
- Finds existing `.eslintrc.*` files with ESLint v9 installed
- Warns that legacy config is ignored in v9
- Auto-generates `eslint.config.mjs` with TypeScript support
- Suggests removing old config files post-migration

**Package.json updates (v9 compatible):**
```json
{
  "scripts": {
    "lint": "eslint .",         // No --ext flag needed in v9
    "lint:fix": "eslint . --fix"
  }
}
```

### Benefits
- ✅ **Zero manual work** - Automatic version detection and config generation
- ✅ **TypeScript support** - Uses modern `typescript-eslint` package
- ✅ **Future-proof** - Aligned with ESLint's new config system
- ✅ **Backward compatible** - Supports both v8 and v9

### Configuration
The template installs appropriate packages based on ESLint version:
```json
// ESLint v9+ installations
{
  "devDependencies": {
    "eslint": "^9.0.0",
    "typescript-eslint": "^8.0.0"  // Modern flat config package
  }
}
```

### Troubleshooting
**Migration from v8 to v9:**
1. Upgrade ESLint: `npm install --save-dev eslint@latest`
2. Run template setup: `./setup-new-project.sh --overwrite-tools`
3. Template generates new `eslint.config.mjs` automatically
4. Remove old config: `rm .eslintrc.json`
5. Test: `npm run lint`

**Learn more:** [ESLint v9 Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide)

## 📊 Configuration-Driven Behavior

### Main Configuration: `.quality-config.yaml`
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

## 🎯 Real-World Performance Benefits

### Large Codebase Example (music_modes_app)
- **Current issues**: 445 TypeScript errors, 303 ESLint issues, 43 flake8 issues
- **Phase 0**: Documents baseline, prevents regressions
- **Phase 1**: Only validates changed files → **8 seconds** instead of 3+ minutes
- **Phase 2**: Gradual improvement with coverage ratcheting
- **Phase 3**: Full quality enforcement when ready

### Performance Comparison
| Validation Scope | Traditional | Adaptive Phase 1 | Improvement |
|------------------|-------------|------------------|-------------|
| **Full codebase** | 180 seconds | 180 seconds | Same |
| **5 changed files** | 180 seconds | 8 seconds | **95% faster** |
| **Developer workflow** | Painful | Instant feedback | **22x improvement** |

## 🛠️ Technology Stack Support

### Frontend Technologies
- ✅ **React** (18+) with TypeScript/JavaScript
- ✅ **Vue** with TypeScript/JavaScript
- ✅ **Angular** with TypeScript
- ✅ **Svelte/SvelteKit** with TypeScript
- ✅ **Vite, Webpack, Parcel** build tools
- ✅ **Jest, Vitest, Cypress** with automatic framework detection (see [Test Framework Detection](#-universal-test-framework-detection))

### Backend Technologies
- ✅ **FastAPI** (Python 3.11+)
- ✅ **Flask, Django** (Python)
- ✅ **Express.js** (Node.js)
- ✅ **NestJS** (TypeScript)
- ✅ **Custom API frameworks**

### Quality Tools (Auto-Configured)
- ✅ **ESLint** with auto-fix and v9 flat config support (see [ESLint v9 Auto-Migration](#-eslint-v9-flat-config-auto-migration))
- ✅ **TypeScript** compiler with strict mode options
- ✅ **Black, isort, flake8, mypy** for Python with intelligent dependency detection
- ✅ **Prettier** for code formatting
- ✅ **detect-secrets** for security scanning
- ✅ **Pre-commit hooks** with performance optimization

## 🎯 Use Cases

### Perfect For:
- **🏢 Enterprise teams** needing graduated quality adoption
- **📈 Legacy codebases** with quality debt  
- **⚡ Large projects** requiring fast feedback loops
- **🎯 Multiple project types** within same organization
- **🚀 Rapid prototyping** to production-ready transition
- **👥 Mixed-skill teams** with varying quality standards

### Success Stories:
- **Large music theory app**: 445 TS errors → graduated quality improvement
- **Full-stack lyrics platform**: Zero-disruption quality gates adoption  
- **Multiple project templates**: Universal system across diverse tech stacks

## 📚 Comprehensive Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete system architecture and commands
- **[DEVELOPMENT.md](template-files/DEVELOPMENT.md)** - Generated project workflows
- **[Project Detection](scripts/detect-project-type.sh)** - Smart detection logic
- **[Quality Gate Manager](scripts/quality-gate-manager.sh)** - Phase management system

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-improvement`
3. Test on multiple project types
4. Ensure all adaptive validations pass
5. Submit a pull request

### Development Setup
```bash
# Test the template system
./scripts/detect-project-type.sh json
./scripts/validate-adaptive.sh
./setup-new-project.sh /tmp/test-project
```

## 📄 License

MIT License - Use freely for personal and commercial projects.

## 🙏 Acknowledgments

Inspired by the best practices from:
- **Pre-commit** ecosystem for git hooks
- **GitHub Actions** workflow patterns  
- **React/TypeScript** community standards
- **Python** quality tool ecosystem (Black, mypy, flake8)
- **Enterprise DevOps** graduated deployment strategies

---

🚀 **Ready to revolutionize your development workflow?** Start with `./setup-new-project.sh` and experience instant, intelligent quality adaptation!