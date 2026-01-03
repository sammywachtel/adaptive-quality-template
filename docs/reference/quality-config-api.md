# Configuration API Reference

**Technical reference for `.quality-config.yaml` configuration options**

## File Location
`.quality-config.yaml` - Main adaptive quality gate configuration file (project root)

## Configuration Structure

```yaml
# Top-level sections
quality_gates:     # Phase and progression settings
tools:             # Tool enablement and configuration
testing:           # Test framework configuration
coverage:          # Coverage requirements and ratcheting
security:          # Security scanning configuration
pre_commit:        # Pre-commit hook behavior
ci_cd:             # CI/CD workflow configuration
```

## quality_gates

Controls quality gate phase progression and behavior.

### Fields

#### `current_phase`
**Type:** `integer` (0-3)
**Default:** `0`
**Required:** Yes

Quality gate phase level:
- `0` - Baseline & Stabilization
- `1` - Changed-Code-Only Enforcement
- `2` - Ratchet & Expand Scope
- `3` - Normalize & Harden

**Example:**
```yaml
quality_gates:
  current_phase: 1  # Changed-files-only mode
```

#### `auto_progression`
**Type:** `boolean`
**Default:** `false`
**Required:** No

Automatically advance to next phase when criteria met.

**Example:**
```yaml
quality_gates:
  auto_progression: true  # Auto-advance when ready
```

**Auto-progression criteria:**
- Phase 0 → 1: No regressions for 7 days
- Phase 1 → 2: 95% new code passes strict checks
- Phase 2 → 3: Coverage ≥ 80%, zero critical issues

#### `baseline_file`
**Type:** `string`
**Default:** `.quality-baseline.json`
**Required:** No

Path to baseline file storing documented issues.

**Example:**
```yaml
quality_gates:
  baseline_file: ".baseline/quality.json"
```

#### `allow_degradation`
**Type:** `boolean`
**Default:** `false`
**Required:** No

Allow quality metrics to decrease from baseline (Phase 0 only).

**Example:**
```yaml
quality_gates:
  current_phase: 0
  allow_degradation: false  # Block all regressions
```

### Complete Example
```yaml
quality_gates:
  current_phase: 1
  auto_progression: false
  baseline_file: ".quality-baseline.json"
  allow_degradation: false

  # Phase-specific overrides
  phase_config:
    phase_0:
      strict_mode: false
      warning_as_error: false
    phase_1:
      strict_mode: true
      warning_as_error: false
      changed_files_only: true
    phase_2:
      strict_mode: true
      warning_as_error: true
      coverage_ratchet: true
    phase_3:
      strict_mode: true
      warning_as_error: true
      zero_tolerance: true
```

## tools

Tool enablement and configuration for frontend, backend, and universal tools.

### tools.frontend

Frontend (TypeScript/JavaScript) tool configuration.

#### `enabled`
**Type:** `string` | `boolean`
**Values:** `"auto"` | `true` | `false`
**Default:** `"auto"`

Enable frontend validation.
- `"auto"`: Enable if frontend detected
- `true`: Always enable
- `false`: Always disable

#### `eslint`
ESLint configuration.

**Fields:**
- `enabled` (auto/true/false): Enable ESLint
- `auto_fix` (boolean): Auto-fix issues on commit
- `config_file` (string): Path to ESLint config
- `extensions` (array): File extensions to lint

**Example:**
```yaml
tools:
  frontend:
    enabled: auto
    eslint:
      enabled: true
      auto_fix: true
      config_file: "eslint.config.mjs"
      extensions: [".ts", ".tsx", ".js", ".jsx"]
      rules_severity: "error"  # error, warn, off
```

#### `typescript`
TypeScript compiler configuration.

**Fields:**
- `enabled` (auto/true/false): Enable TypeScript checking
- `strict_mode` (boolean): Use strict compiler options
- `config_file` (string): Path to tsconfig.json
- `emit_errors_only` (boolean): Only show errors, not warnings

**Example:**
```yaml
tools:
  frontend:
    typescript:
      enabled: true
      strict_mode: false  # Enable in Phase 2+
      config_file: "tsconfig.json"
      emit_errors_only: false
```

### tools.backend

Backend (Python) tool configuration.

#### `python`
Python tooling configuration.

**Fields:**
- `black`: Code formatting
- `isort`: Import sorting
- `flake8`: Linting
- `mypy`: Type checking

**Example:**
```yaml
tools:
  backend:
    enabled: auto
    python:
      black:
        enabled: true
        line_length: 88
        target_version: "py311"

      isort:
        enabled: true
        profile: "black"

      flake8:
        enabled: true
        max_line_length: 88
        exclude:
          - "tools/"
          - ".venv/"
          - "migrations/"

      mypy:
        enabled: false  # Enable gradually
        strict: false
        python_version: "3.11"
        ignore_missing_imports: true
        additional_dependencies: []  # Auto-detected
```

### tools.universal

Tools that apply to all project types.

**Fields:**
- `detect_secrets`: Secret scanning
- `trailing_whitespace`: Whitespace cleanup
- `end_of_file_fixer`: EOF newline enforcement
- `check_merge_conflict`: Merge conflict detection

**Example:**
```yaml
tools:
  universal:
    detect_secrets:
      enabled: true
      baseline_file: ".secrets.baseline"

    trailing_whitespace:
      enabled: true

    end_of_file_fixer:
      enabled: true

    check_merge_conflict:
      enabled: true
```

## testing

Test framework and coverage configuration.

### testing.unit

Unit test configuration.

#### `enabled`
**Type:** `string` | `boolean`
**Default:** `"auto"`

Enable unit testing validation.

#### `framework`
**Type:** `string`
**Values:** `"auto"` | `"jest"` | `"vitest"` | `"generic"`
**Default:** `"auto"`

Test framework to use.
- `"auto"`: Detect from package.json
- `"jest"`: Use Jest with `--findRelatedTests`
- `"vitest"`: Use Vitest with `--run --changed`
- `"generic"`: Use npm test (no changed-files support)

#### `changed_files_only`
**Type:** `boolean`
**Default:** `true` (Phase 1+)

Only test files related to changes.

#### `coverage_required`
**Type:** `boolean`
**Default:** `false` (enable Phase 2+)

Require coverage reports.

#### `coverage_threshold`
**Type:** `integer` (0-100)
**Default:** `80`

Minimum coverage percentage required.

**Complete Example:**
```yaml
testing:
  unit:
    enabled: auto
    framework: "vitest"
    changed_files_only: true
    coverage_required: false
    coverage_threshold: 80

    # Framework-specific configuration
    jest_config: "jest.config.js"
    vitest_config: "vitest.config.ts"

    # Custom commands
    custom_commands:
      phase0: "npm test"
      phase1: "npm test -- --changed"
      phase2: "npm run test:coverage"
      phase3: "npm run test:coverage"

  e2e:
    enabled: auto  # Auto-enable if frontend detected
    framework: "auto"  # cypress, playwright
    required_phase: 2  # Only required in Phase 2+
```

## coverage

Coverage ratcheting and threshold configuration.

### Fields

#### `enabled`
**Type:** `boolean`
**Default:** `false`

Enable coverage tracking.

#### `ratchet_enabled`
**Type:** `boolean`
**Default:** `false` (enable Phase 2+)

Enable coverage ratcheting (prevent decreases).

#### `baseline_file`
**Type:** `string`
**Default:** `.coverage-baseline.json`

File storing current coverage baseline.

#### `thresholds`
**Type:** `object`

Coverage thresholds per metric.

**Example:**
```yaml
coverage:
  enabled: true
  ratchet_enabled: true
  baseline_file: ".coverage-baseline.json"

  thresholds:
    lines: 80
    functions: 80
    branches: 75
    statements: 80

  # Ratchet behavior
  ratchet_config:
    allow_decrease: 0.5  # Allow 0.5% decrease
    increase_step: 1.0   # Track 1% improvements
    update_on: "commit"  # Update baseline on commit or phase-advance
```

## security

Security scanning configuration.

### Fields

#### `detect_secrets`
Secret detection configuration.

**Example:**
```yaml
security:
  detect_secrets:
    enabled: true
    baseline_file: ".secrets.baseline"
    exclude_files:
      - "*.lock"
      - "package-lock.json"
    additional_patterns: []

  vulnerability_scanning:
    enabled: false  # npm audit, pip-audit
    fail_on: "high"  # low, moderate, high, critical

  dependency_check:
    enabled: false
    auto_update: false
```

## pre_commit

Pre-commit hook configuration.

### Fields

**Example:**
```yaml
pre_commit:
  enabled: true
  fail_fast: true  # Stop on first failure
  verbose: false   # Show detailed output

  # Phase-based configuration
  phase_behavior:
    phase_0:
      run_on: "all_files"
    phase_1:
      run_on: "changed_files"
    phase_2:
      run_on: "all_files"
    phase_3:
      run_on: "all_files"

  # Performance
  parallel: true
  max_workers: 4
```

## ci_cd

CI/CD workflow configuration.

### Fields

**Example:**
```yaml
ci_cd:
  enabled: true

  # GitHub Actions configuration
  github_actions:
    workflow_file: "quality-standardized.yml"
    trigger_on:
      - push
      - pull_request
    branches:
      - main
      - develop

  # Validation mode
  validation_only: true  # No auto-fixing in CI
  fail_fast: false       # Run all checks

  # Reporting
  comment_on_pr: true    # Post results to PR
  create_check: true     # Create GitHub check
```

## Environment Variables

Configuration values can reference environment variables:

```yaml
tools:
  backend:
    python:
      mypy:
        python_version: "${PYTHON_VERSION:-3.11}"

testing:
  unit:
    framework: "${TEST_FRAMEWORK:-auto}"

coverage:
  thresholds:
    lines: "${COVERAGE_THRESHOLD:-80}"
```

**Usage:**
```bash
export COVERAGE_THRESHOLD=90
./scripts/validate-adaptive.sh
```

## Complete Configuration Example

```yaml
# .quality-config.yaml - Full configuration example

# Quality gate phase management
quality_gates:
  current_phase: 1
  auto_progression: false
  baseline_file: ".quality-baseline.json"

# Tool configuration
tools:
  frontend:
    enabled: auto
    eslint:
      enabled: true
      auto_fix: true
    typescript:
      enabled: true
      strict_mode: false

  backend:
    enabled: auto
    python:
      black:
        enabled: true
        line_length: 88
      mypy:
        enabled: false

  universal:
    detect_secrets:
      enabled: true

# Test framework configuration
testing:
  unit:
    enabled: auto
    framework: "vitest"
    changed_files_only: true
    coverage_required: false
    coverage_threshold: 80

  e2e:
    enabled: auto

# Coverage configuration
coverage:
  enabled: true
  ratchet_enabled: false
  thresholds:
    lines: 80
    functions: 80
    branches: 75
    statements: 80

# Security configuration
security:
  detect_secrets:
    enabled: true

# Pre-commit configuration
pre_commit:
  enabled: true
  fail_fast: true

# CI/CD configuration
ci_cd:
  enabled: true
  validation_only: true
```

## Validation

Validate configuration syntax:

```bash
# Check configuration is valid
./scripts/generate-config.sh validate

# Regenerate from template
./scripts/generate-config.sh update

# View effective configuration
./scripts/generate-config.sh show
```

## Migration

### From Legacy Config

If migrating from older template versions:

```bash
# Backup existing config
cp .quality-config.yaml .quality-config.yaml.backup

# Regenerate with new schema
./scripts/generate-config.sh update --preserve-settings

# Compare changes
diff .quality-config.yaml.backup .quality-config.yaml
```

## Related Documentation
- [How to Progress Through Quality Gate Phases](../how-to/progress-quality-gates.md)
- [How to Configure Test Framework Detection](../how-to/configure-test-framework.md)
- [Script Parameters Reference](./script-parameters.md)
- [Environment Variables Reference](./environment-variables.md)
