# How to Configure Test Framework Detection

**Task-oriented guide for setting up Jest, Vitest, or custom test framework detection**

## Context
The adaptive template automatically detects Jest or Vitest and uses framework-specific commands for optimal performance. This guide shows how to configure, troubleshoot, and customize test framework detection.

## Quick Reference

| Framework | Auto-Detection | Changed-Files Command |
|-----------|---------------|----------------------|
| **Jest** | `jest` in package.json deps | `--findRelatedTests` |
| **Vitest** | `vitest` in package.json deps | `--run --changed` |
| **Generic** | Fallback | `npm test` |

## Automatic Detection (Default)

### How It Works
1. Template scans `package.json` dependencies
2. Detects `jest` or `vitest` package
3. Configures `.quality-config.yaml` automatically
4. Uses framework-specific flags in Phase 1+

### Verify Detection
```bash
# Check what was detected
cat .quality-config.yaml | grep -A5 "testing:"

# Run validation to see framework in action
./scripts/validate-adaptive.sh

# Should show:
# ✅ Detected test framework: Vitest (or Jest)
```

## Manual Configuration

### Scenario 1: Both Jest and Vitest Installed
**Problem:** Detection picks wrong framework

**Solution:** Explicit configuration in `.quality-config.yaml`
```yaml
testing:
  unit:
    enabled: true
    framework: "vitest"  # or "jest"
    changed_files_only: true
    coverage_required: false
```

### Scenario 2: Custom Test Framework
**Problem:** Using Mocha, Jasmine, or custom framework

**Solution:** Set to generic mode
```yaml
testing:
  unit:
    enabled: true
    framework: "generic"  # Uses npm test
    changed_files_only: false  # Generic doesn't support changed-files
```

### Scenario 3: No Tests Yet
**Problem:** Project doesn't have tests configured

**Solution:** Disable testing temporarily
```yaml
testing:
  unit:
    enabled: false
```

## Configuration Options

### Full Testing Configuration
```yaml
testing:
  unit:
    enabled: auto              # auto, true, false
    framework: auto            # auto, jest, vitest, generic
    changed_files_only: true   # Phase 1+ optimization
    coverage_required: false   # Enable in Phase 2+
    coverage_threshold: 80     # Minimum coverage percentage

  e2e:
    enabled: auto              # Auto-enable if frontend detected
    framework: auto            # cypress, playwright, generic
```

### Framework-Specific Settings

**Jest Configuration:**
```yaml
testing:
  unit:
    framework: "jest"
    jest_config: "jest.config.js"  # Optional: custom config path
    jest_flags:
      - "--coverage"
      - "--verbose"
```

**Vitest Configuration:**
```yaml
testing:
  unit:
    framework: "vitest"
    vitest_config: "vitest.config.ts"  # Optional: custom config path
    vitest_flags:
      - "--coverage"
      - "--reporter=verbose"
```

## Testing in Different Phases

### Phase 0: Full Test Suite
```bash
# Runs all tests regardless of changes
npm test

# Detection output:
# Phase 0: Running all tests
# Test framework: Jest
# Command: npm test
```

### Phase 1: Changed Files Only
```bash
# Only tests affected by changes
npm test

# Detection output:
# Phase 1: Testing changed files only
# Test framework: Vitest
# Command: npm test -- --run --changed
```

**Changed-files detection:**
- **Jest**: `--findRelatedTests src/file1.ts src/file2.ts`
- **Vitest**: `--run --changed`
- **Generic**: Falls back to full suite (no changed-file support)

### Phase 2+: Coverage Requirements
```bash
# Tests must meet coverage threshold
npm test

# With coverage enabled in config:
testing:
  unit:
    coverage_required: true
    coverage_threshold: 80
```

## Common Tasks

### Task: Migrate from Jest to Vitest

**Step 1: Install Vitest**
```bash
npm install --save-dev vitest @vitest/ui
npm uninstall jest @types/jest
```

**Step 2: Update package.json**
```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage"
  }
}
```

**Step 3: Create Vitest Config**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
  },
});
```

**Step 4: Regenerate Template Config**
```bash
# Template auto-detects new framework
./scripts/generate-config.sh update

# Verify detection
cat .quality-config.yaml | grep framework
# Should show: framework: "vitest"
```

**Step 5: Update Tests**
```typescript
// Old Jest syntax (still works in Vitest with globals: true)
import { expect, test } from '@jest/globals';

// New Vitest syntax (recommended)
import { expect, test } from 'vitest';
```

### Task: Add Coverage Requirements

**Step 1: Enable Coverage in Config**
```yaml
# .quality-config.yaml
testing:
  unit:
    coverage_required: true
    coverage_threshold: 80
```

**Step 2: Install Coverage Package**
```bash
# For Vitest
npm install --save-dev @vitest/coverage-v8

# For Jest (usually included)
npm install --save-dev jest
```

**Step 3: Configure Coverage**
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      lines: 80,
      functions: 80,
      branches: 80,
      statements: 80,
    },
  },
});
```

**Step 4: Run Tests with Coverage**
```bash
npm run test:coverage

# Or via quality gate
./scripts/validate-adaptive.sh
```

### Task: Debug Test Framework Detection

**Step 1: Enable Debug Mode**
```bash
DEBUG=1 ./scripts/validate-adaptive.sh
```

**Step 2: Check Detection Logic**
```bash
# View detection output
./scripts/detect-project-type.sh json | jq '.frameworks'

# Check package.json
cat package.json | jq '.dependencies + .devDependencies | keys | map(select(. | test("jest|vitest")))'
```

**Step 3: Verify Configuration**
```bash
# View current config
cat .quality-config.yaml

# Regenerate if needed
./scripts/generate-config.sh update
```

**Step 4: Test Manual Override**
```yaml
# .quality-config.yaml - Add explicit framework
testing:
  unit:
    enabled: true
    framework: "jest"  # Force Jest even if Vitest installed
```

## Troubleshooting

### Issue 1: Wrong Framework Detected
**Symptom:** Detection picks Jest when you want Vitest (or vice versa)

**Solution:**
```bash
# 1. Check what's in package.json
npm list jest vitest

# 2. Manually set in .quality-config.yaml
vim .quality-config.yaml
# Set framework: "vitest"

# 3. Regenerate config
./scripts/generate-config.sh update
```

### Issue 2: Tests Not Running in Phase 1
**Symptom:** Phase 1 doesn't run tests for changed files

**Solution:**
```bash
# 1. Verify phase setting
./scripts/quality-gate-manager.sh status

# 2. Check git status (needs tracked changes)
git status

# 3. Check changed_files_only setting
cat .quality-config.yaml | grep changed_files_only

# 4. Run with debug
DEBUG=1 ./scripts/validate-adaptive.sh
```

### Issue 3: Test Command Fails
**Symptom:** `npm test` fails or uses wrong flags

**Solution:**
```bash
# 1. Check package.json test script
cat package.json | grep -A2 "\"test\""

# 2. Test framework directly
npx jest --version   # or npx vitest --version

# 3. Check for syntax errors in config
npx vitest --config vitest.config.ts  # Test config loads

# 4. Verify framework-specific flags
# Jest:
npm test -- --findRelatedTests src/file.ts

# Vitest:
npm test -- --run --changed
```

### Issue 4: Coverage Not Working
**Symptom:** Coverage reports not generated

**Solution:**
```bash
# 1. Install coverage provider
npm install --save-dev @vitest/coverage-v8  # Vitest
# Jest includes coverage by default

# 2. Add coverage flag to test command
npm test -- --coverage

# 3. Check config
cat vitest.config.ts | grep -A10 coverage

# 4. Verify output directory
ls -la coverage/
```

## Advanced Configuration

### Multi-Framework Monorepo
```yaml
# Root .quality-config.yaml
testing:
  workspaces:
    frontend:
      framework: "vitest"
      config: "frontend/vitest.config.ts"
    backend:
      framework: "jest"
      config: "backend/jest.config.js"
```

### Custom Test Commands
```yaml
testing:
  unit:
    framework: "generic"
    custom_commands:
      phase0: "npm run test:all"
      phase1: "npm run test:changed"
      phase2: "npm run test:coverage"
```

### Parallel Test Execution
```yaml
testing:
  unit:
    framework: "vitest"
    parallel: true
    max_workers: 4
    timeout: 30000  # 30 seconds
```

## Validation Checklist

After configuration changes, verify:

- [ ] Framework detected correctly: `cat .quality-config.yaml | grep framework`
- [ ] Tests run successfully: `npm test`
- [ ] Changed-files detection works: `./scripts/validate-adaptive.sh` (Phase 1+)
- [ ] Coverage generated (if enabled): `ls coverage/`
- [ ] Pre-commit hooks include tests: `pre-commit run --all-files`
- [ ] CI workflow uses correct framework: `cat .github/workflows/quality-standardized.yml`

## Related Guides
- [How to Progress Through Quality Gate Phases](./progress-quality-gates.md)
- [How to Apply Template to Existing Project](./apply-template-to-existing-project.md)
- [Test Framework Support Matrix](../reference/test-framework-support.md)
