# How to Apply the Template to an Existing Project

**Task-oriented guide for integrating adaptive quality gates into your codebase**

## Prerequisites
- Git repository initialized
- Basic understanding of your project type (TypeScript, Python, or full-stack)
- Commit or stash any uncommitted changes

## Quick Start (5 minutes)

### 1. Clone the Template Repository
```bash
git clone https://github.com/sammywachtel/adaptive-quality-template.git
cd adaptive-quality-template
```

### 2. Apply to Your Project
```bash
# Default: Preserve existing tool configurations
./setup-new-project.sh /path/to/your/project

# Or: Replace tool configs with template standards
./setup-new-project.sh /path/to/your/project --overwrite-tools

# For current directory
./setup-new-project.sh .
```

### 3. Review Generated Files
The template creates/modifies:
- `.quality-config.yaml` - Main configuration
- `.pre-commit-config.yaml` - Git hooks configuration
- `scripts/` - Quality gate management scripts
- `setup-dev.sh` - One-command environment setup
- `.github/workflows/` - CI/CD validation workflows

### 4. Run Initial Setup
```bash
cd /path/to/your/project
./setup-dev.sh
```

### 5. Verify Installation
```bash
# Check project detection
./scripts/detect-project-type.sh

# Run validation
./scripts/validate-adaptive.sh

# Check quality gate phase
./scripts/quality-gate-manager.sh status
```

## Configuration Modes

### Default Mode: Smart Merge
**Preserves your existing settings:**
```bash
./setup-new-project.sh /path/to/project
```

**What it preserves:**
- ✅ Existing `[build-system]` and `[project]` in pyproject.toml
- ✅ Your custom tool configurations
- ✅ Custom package manager configs (hatch, poetry, etc.)

**What it adds:**
- ➕ Missing tool configurations
- ➕ Quality gate scripts
- ➕ Pre-commit hooks
- ➕ CI/CD workflows

### Overwrite Mode: Standardize
**Replaces tool configs with template standards:**
```bash
./setup-new-project.sh /path/to/project --overwrite-tools
```

**What it replaces:**
- 🔄 Black, isort, mypy, flake8 configurations
- 🔄 ESLint, TypeScript configurations
- 🔄 Test framework configurations

**What it preserves:**
- ✅ Build system and project metadata
- ✅ Custom package manager configs

## Common Scenarios

### Scenario 1: Large Codebase with Quality Debt
**Problem:** 445 TypeScript errors, can't fix everything immediately

**Solution:** Start with Phase 0 baseline
```bash
# 1. Apply template
./setup-new-project.sh /path/to/project

# 2. Initialize at Phase 0
./scripts/quality-gate-manager.sh init

# 3. Establish baseline
./scripts/quality-gate-manager.sh baseline

# 4. Develop normally - regressions blocked, legacy allowed
git add . && git commit -m "Add feature"

# 5. Advance to Phase 1 when stable
./scripts/quality-gate-manager.sh advance
```

### Scenario 2: Team with Mixed Tool Preferences
**Problem:** Different team members use different formatters/linters

**Solution:** Use overwrite mode for consistency
```bash
# 1. Get team buy-in on template standards
# 2. Apply with overwrite
./setup-new-project.sh /path/to/project --overwrite-tools

# 3. Run setup
cd /path/to/project && ./setup-dev.sh

# 4. Team members pull changes
git pull
./setup-dev.sh
```

### Scenario 3: Rapid Prototyping to Production
**Problem:** Need quick iteration now, strict quality later

**Solution:** Phase progression strategy
```bash
# 1. Apply template, start at Phase 0
./setup-new-project.sh /path/to/project

# 2. During prototyping: Stay at Phase 0 or disable gates
./scripts/quality-gate-manager.sh set-phase 0

# 3. Before production: Advance through phases
./scripts/quality-gate-manager.sh set-phase 1  # Changed files only
# Fix new code issues
./scripts/quality-gate-manager.sh advance      # Move to Phase 2
# Improve coverage
./scripts/quality-gate-manager.sh advance      # Move to Phase 3
# Full strict enforcement
```

## Troubleshooting

### Template Application Fails
```bash
# Check prerequisites
git rev-parse --git-dir  # Should show .git directory
ls -la package.json      # Or requirements.txt for Python

# Run with debug output
DEBUG=1 ./setup-new-project.sh /path/to/project
```

### Tool Conflicts After Application
```bash
# Regenerate configurations
./scripts/generate-config.sh update

# Check what was detected
./scripts/detect-project-type.sh json

# Manually edit .quality-config.yaml if needed
vim .quality-config.yaml
```

### Pre-commit Hooks Not Working
```bash
# Reinstall hooks
./setup-dev.sh

# Verify installation
pre-commit run --all-files
```

### CI/CD Workflows Not Triggering
```bash
# Ensure workflows directory exists
ls -la .github/workflows/

# Check workflow syntax
cat .github/workflows/quality-standardized.yml

# Push to trigger
git push origin main
```

## Next Steps

After successful application:

1. **Configure Phase** - See [How to Progress Through Quality Gate Phases](./progress-quality-gates.md)
2. **Customize Config** - See [Configuration API Reference](../reference/quality-config-api.md)
3. **Team Onboarding** - Share [Development Guide](../../template-files/DEVELOPMENT.md)
4. **Enable Advanced Features** - Coverage ratcheting, security scanning, etc.

## Related Guides
- [How to Progress Through Quality Gate Phases](./progress-quality-gates.md)
- [How to Upgrade ESLint from v8 to v9](./upgrade-eslint-v9.md)
- [How to Configure Test Framework Detection](./configure-test-framework.md)
