# Development Guide

## Quality Gates Overview

This project uses an **adaptive quality gate system** with graduated enforcement to ensure code quality without disrupting development velocity.

### 🎛️ Quality Gate Phases

The system supports 4 progressive phases (see `.quality-config.yaml` to check current phase):

**Phase 0: Baseline & Stabilization**
- Documents current code quality baseline
- Prevents regressions from baseline
- Allows legacy issues but blocks new problems
- Focus: Stability

**Phase 1: Changed-Code-Only Enforcement** (⚡ Recommended for large codebases)
- Strict quality on new/modified files only
- Legacy code generates warnings
- **Performance**: Sub-10-second validation vs 2-5 minutes full repo
- Focus: Perfect new code

**Phase 2: Ratchet & Expand Scope**
- Repository-wide enforcement
- Coverage ratchet requires gradual improvement
- Focus: Progressive improvement

**Phase 3: Normalize & Harden**
- Full strict enforcement
- Zero technical debt tolerance
- Focus: Production-ready quality

### 📊 Phase Management
```bash
# Check current phase
./scripts/quality-gate-manager.sh status

# Advance to next phase when ready
./scripts/quality-gate-manager.sh advance

# Set specific phase
./scripts/quality-gate-manager.sh set-phase 1
```

### 🚨 Important: Quality Checks Based on Phase

Quality gates are enforced at multiple levels:

1. **Pre-commit hooks** - Run automatically on every commit (scope varies by phase)
2. **CI/CD pipeline** - Validates all changes on push/PR
3. **Manual checks** - Run locally before committing: `npm run quality:gate`

### Quality Commands

```bash
# Run all quality checks
npm run quality:gate

# Run specific checks
npm run quality:frontend     # Frontend only (ESLint, TypeScript, tests)
npm run quality:backend      # Backend only (Black, isort, flake8, MyPy)
npm run quality:precommit    # Run pre-commit hooks

# Manual hook management
npm run precommit:install    # Install pre-commit hooks
npm run precommit:run        # Run all pre-commit hooks manually
```

## Quick Setup

**New team member? Run this once:**
```bash
./setup-dev.sh  # Comprehensive setup with quality gates
```

**Apply adaptive template to existing project:**
```bash
./setup-new-project.sh /path/to/project
```

This automatically:
- Detects your project type (TypeScript, Python, full-stack, or hybrid)
- Creates isolated environments (Python virtual env if backend detected)
- Installs all dependencies in isolated environments
- Sets up pre-commit hooks and verifies your environment
- Configures quality gates based on detected technologies
- Prevents system-wide package conflicts

## Development Workflow

### 1. Start Development Environment

```bash
# Start both frontend and backend
npm run dev

# OR start them separately
npm run frontend:dev  # Frontend only (port 5173)
npm run backend:dev   # Backend only (port 8001)
```

### 2. Make Your Changes

**For Full-Stack Projects:**
- Edit frontend files (typically `frontend/src/` or `src/`)
- Edit backend files (typically `backend/app/`, `backend/src/`, or `app/`)
- Write tests as you develop (mandatory for all features)

**For Single-Language Projects:**
- Edit source files in detected source directory (`src/`, `app/`, etc.)
- Co-locate tests with source code or in `__tests__/` directories

### 3. Quality Gate Validation

**IMPORTANT: With quality gates enabled, run checks before committing:**

```bash
# Run all quality checks
npm run quality:gate

# Fix any issues reported
# Then commit normally
git add .
git commit -m "Your commit message"
```

**Pre-commit hooks run automatically and MUST pass:**
- ✅ ESLint strict validation (no auto-fixing)
- ✅ TypeScript compilation check
- ✅ Tests for affected files
- ✅ Python formatting and linting
- ✅ Security scanning
- ✅ File hygiene checks

**If hooks fail:**
- Fix the reported issues using quality commands
- Commit again - hooks will re-run
- **Cannot bypass without --no-verify (not recommended)**

### 4. Push and CI Validation

```bash
git push origin feature-branch
```

The CI pipeline validates:
- ✅ ESLint compliance (no auto-fixing)
- ✅ TypeScript compilation
- ✅ All tests pass
- ✅ Code quality standards

## Code Quality Commands

### Linting
```bash
# Check for lint issues
npm run lint

# Auto-fix lint issues
npm run lint:fix

# Run from project root
npm run lint        # Delegates to frontend
npm run lint:fix    # Delegates to frontend
```

### TypeScript
```bash
# Check TypeScript compilation
cd frontend && npx tsc --noEmit

# Via project root
npm run test  # Includes TypeScript check in build process
```

### Python Environment & Formatting
```bash
# Activate backend virtual environment
cd backend && source .venv/bin/activate

# Format Python code
cd backend && source .venv/bin/activate && black . && isort .

# Check Python code formatting
cd backend && source .venv/bin/activate && black --check . && isort --check-only .

# Run Python linting
cd backend && source .venv/bin/activate && flake8

# Run Python type checking
cd backend && source .venv/bin/activate && mypy .

# Install new Python package
cd backend && source .venv/bin/activate && pip install package-name

# Update requirements.txt after adding packages
cd backend && source .venv/bin/activate && pip freeze > requirements.txt
```

### Testing

The template **automatically detects your test framework** (Jest or Vitest) and uses the appropriate commands.

```bash
# Run all tests once (auto-detects framework)
npm test

# Run tests in watch mode (for development)
npm run test:watch

# Run tests with coverage report
npm run test:coverage

# Run specific test
npm test -- path/to/test-file.test.ts
```

#### 🧪 Test Framework Auto-Detection

**Detected Framework: Jest**
```bash
# Phase 0: Runs all tests
npm test

# Phase 1+: Only tests for changed files
npm test -- --findRelatedTests src/changed-file.ts
```

**Detected Framework: Vitest**
```bash
# Phase 0: Runs all tests
npm test

# Phase 1+: Only tests for changed files
npm test -- --run --changed
```

**Check detected framework:**
```bash
# View test framework configuration
cat .quality-config.yaml | grep -A5 "testing:"

# Run validation to see detection output
./scripts/validate-adaptive.sh
```

### Pre-commit Management
```bash
# Manually run all pre-commit hooks
npm run precommit:run

# Reinstall hooks (if needed)
npm run setup:hooks

# Run pre-commit on specific files
pre-commit run --files frontend/src/components/MyComponent.tsx
```

## Development Best Practices

### 1. Test-Driven Development
- Write tests alongside feature development
- Use `npm run test:watch` for interactive testing
- Aim for comprehensive test coverage

### 2. Clean Commits
- Pre-commit hooks ensure clean, consistent code
- Write meaningful commit messages
- Make atomic commits (one logical change per commit)

### 3. Fast Feedback Loop
- Pre-commit hooks provide instant feedback (< 10 seconds)
- Fix issues locally before they reach CI
- Use watch mode for tests and development

### 4. Code Quality Standards
- ESLint enforces consistent code style
- TypeScript ensures type safety
- Tests verify functionality
- All checks run both locally and in CI

## Troubleshooting

### Pre-commit Hooks Not Running
```bash
# Reinstall hooks
./setup-dev.sh

# Or manually
pre-commit install

# Verify hooks are installed
pre-commit run --all-files
```

### CI Failing After Local Success
```bash
# Run the same checks CI uses
npm run lint      # ESLint validation
npx tsc --noEmit  # TypeScript check (from frontend/ if exists)
npm test          # Full test suite

# Check phase configuration
./scripts/quality-gate-manager.sh status

# If still failing, check CI logs for specific errors
```

### Test Framework Detection Issues

**Framework not detected or wrong framework used:**
```bash
# 1. Verify test framework in package.json
cat package.json | grep -E "(jest|vitest)"

# 2. Check detection in config
cat .quality-config.yaml | grep -A5 "testing:"

# 3. Manually set framework in .quality-config.yaml
# Edit testing.unit.framework: "jest" or "vitest"

# 4. Regenerate configuration
./scripts/generate-config.sh update

# 5. Test detection
./scripts/validate-adaptive.sh
```

**Both Jest and Vitest installed:**
```bash
# Detection uses package.json test script
# Override in .quality-config.yaml:
testing:
  unit:
    framework: "vitest"  # or "jest"
```

**Test command fails:**
```bash
# Debug with verbose output
DEBUG=1 ./scripts/validate-adaptive.sh

# For Jest:
npm test -- --verbose

# For Vitest:
npm test -- --run --reporter=verbose
```

### ESLint v9 Migration Issues

**ESLint ignoring configuration:**
```bash
# 1. Check ESLint version
npm list eslint

# 2. If v9+, ensure flat config exists
ls -la eslint.config.mjs eslint.config.js

# 3. If .eslintrc.json exists with ESLint v9, it's ignored
# Generate new config:
./setup-new-project.sh --overwrite-tools

# 4. Remove deprecated config
rm .eslintrc.json .eslintrc.js .eslintrc.yml

# 5. Test linting
npm run lint
```

**TypeScript linting not working with ESLint v9:**
```bash
# Ensure typescript-eslint is installed (not @typescript-eslint/*)
npm install --save-dev typescript-eslint

# Regenerate flat config
./scripts/generate-config.sh update

# Test
npm run lint
```

### Quality Gate Phase Issues

**Validation too slow (Phase 0):**
```bash
# Advance to Phase 1 for changed-files-only
./scripts/quality-gate-manager.sh set-phase 1

# Verify phase
./scripts/quality-gate-manager.sh status

# Test performance
time ./scripts/validate-adaptive.sh
# Should be < 10 seconds for small changes
```

**Phase 1 not detecting changed files:**
```bash
# Check git status
git status

# Run validation with debug
DEBUG=1 ./scripts/validate-adaptive.sh

# Verify git is initialized
git rev-parse --git-dir
```

**Want to skip quality gates temporarily:**
```bash
# ❌ NOT RECOMMENDED: Skip hooks
git commit --no-verify -m "Emergency fix"

# ✅ BETTER: Fix issues or adjust phase
./scripts/quality-gate-manager.sh set-phase 0  # More permissive
# Fix issues
# Then commit normally
```

### Performance Issues
```bash
# Check current phase (affects validation speed)
./scripts/quality-gate-manager.sh status

# Phase 0: Full validation (slower)
# Phase 1: Changed files only (faster)

# For large codebases, use Phase 1:
./scripts/quality-gate-manager.sh set-phase 1
```

### Test Failures
```bash
# Run tests with more details
npm test -- --verbose

# For Jest:
npm test -- --testNamePattern="your test name"
npm test -- --no-coverage --verbose path/to/test.test.ts

# For Vitest:
npm test -- --run --reporter=verbose
npm test -- --run path/to/test.test.ts
```

### Python Virtual Environment Issues
```bash
# Recreate virtual environment
cd backend
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Verify activation
which python  # Should show backend/.venv/bin/python
```

## File Structure Reference

**Adaptive structure varies by project type. Common elements:**

```
your-project/
├── .quality-config.yaml       # Adaptive quality gate configuration
├── .pre-commit-config.yaml    # Pre-commit hook configuration (auto-generated)
├── setup-dev.sh               # One-command environment setup
├── .github/workflows/         # CI validation pipelines (auto-generated)
├── scripts/                   # Quality gate scripts
│   ├── detect-project-type.sh # Project structure detection
│   ├── generate-config.sh     # Configuration management
│   ├── quality-gate-manager.sh # Phase management
│   └── validate-adaptive.sh   # Universal validation
└── package.json               # Root scripts and tooling (if Node.js detected)
```

**Full-Stack Project Additional Structure:**
```
├── frontend/                  # Frontend application (if detected)
│   ├── src/                   # Source code
│   │   ├── components/        # UI components
│   │   │   └── __tests__/     # Component tests
│   │   └── utils/             # Utility functions
│   └── package.json           # Frontend dependencies
├── backend/                   # Backend application (if detected)
│   ├── .venv/                 # Python virtual environment (auto-created)
│   ├── app/ or src/           # Backend application code
│   └── requirements.txt       # Python dependencies (if Python)
```

**Project Type Variations:**
- **TypeScript-only**: Only frontend/ or src/ with TypeScript
- **Python-only**: Only backend/, app/, or src/ with Python files
- **Hybrid**: Detected languages combined with adaptive tooling

## Team Workflow Summary

| Stage | Local (Pre-commit) | CI (GitHub Actions) |
|-------|-------------------|---------------------|
| **Speed** | < 10 seconds | 2-5 minutes |
| **Purpose** | Fix issues before commit | Validate clean code |
| **Actions** | Auto-fix lint, check TS, run tests | Validate only, no fixing |
| **Failure** | Fix locally and re-commit | Fix locally and push |

This hybrid approach ensures:
- ⚡ **Fast feedback** during development
- 🧹 **Clean commit history** without auto-fix commits
- 🔒 **Quality assurance** at every stage
- 🚀 **Efficient CI** that focuses on validation
- 👥 **Consistent code** across the team

## Getting Help

- **Setup Issues**: Run `./setup-dev.sh` again
- **Hook Problems**: Check `.pre-commit-config.yaml` configuration
- **CI Failures**: Compare local commands with CI steps
- **Test Issues**: Use `npm run test:watch` for interactive debugging

Happy coding! 🎵
