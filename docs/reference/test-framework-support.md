# Test Framework Support Matrix

**Technical reference for supported test frameworks and their capabilities**

## Supported Frameworks

| Framework | Detection | Changed-Files | Coverage | Auto-Config | Status |
|-----------|-----------|---------------|----------|-------------|--------|
| **Jest** | ✅ Auto | ✅ `--findRelatedTests` | ✅ Built-in | ✅ Yes | Stable |
| **Vitest** | ✅ Auto | ✅ `--run --changed` | ✅ Via @vitest/coverage-v8 | ✅ Yes | Stable |
| **Cypress** | ✅ Auto | ❌ No | ✅ Via @cypress/code-coverage | ⚠️ Manual | Experimental |
| **Playwright** | ✅ Auto | ❌ No | ✅ Built-in | ⚠️ Manual | Experimental |
| **Mocha** | ⚠️ Manual | ❌ No | ✅ Via nyc | ⚠️ Manual | Supported |
| **Jasmine** | ⚠️ Manual | ❌ No | ✅ Via karma | ⚠️ Manual | Supported |
| **Pytest** | ✅ Auto | ✅ Via pytest-testmon | ✅ Via coverage.py | ✅ Yes | Stable |
| **Generic** | ✅ Fallback | ❌ No | ❌ No | ❌ No | Fallback |

## Jest

### Detection Criteria
```json
// package.json
{
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

### Changed-Files Support
**Command:** `--findRelatedTests`

**Example:**
```bash
# Phase 0: All tests
npm test

# Phase 1+: Changed files only
npm test -- --findRelatedTests src/file1.ts src/file2.ts
```

**How it works:**
- Analyzes import/require statements
- Finds tests that import changed files
- Runs minimal test subset

**Limitations:**
- Requires source maps for accurate detection
- May miss tests with dynamic imports

### Coverage Support
**Built-in:** Jest includes coverage via Istanbul

**Configuration:**
```javascript
// jest.config.js
export default {
  collectCoverage: true,
  coverageThreshold: {
    global: {
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },
  },
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
};
```

**Commands:**
```bash
# Run with coverage
npm test -- --coverage

# Coverage report location
open coverage/lcov-report/index.html
```

### Configuration Generated
```yaml
# .quality-config.yaml
testing:
  unit:
    framework: "jest"
    jest_config: "jest.config.js"
    changed_files_only: true
    coverage_required: false
```

### Pre-commit Hook
```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: jest-tests
      name: Jest Tests
      entry: bash -c 'npm test -- --findRelatedTests'
      language: system
      files: '^(src|app)/.*\.(ts|tsx|js|jsx)$'
      pass_filenames: true
```

## Vitest

### Detection Criteria
```json
// package.json
{
  "devDependencies": {
    "vitest": "^1.0.0"
  }
}
```

### Changed-Files Support
**Command:** `--run --changed`

**Example:**
```bash
# Phase 0: All tests
npm test

# Phase 1+: Changed files only
npm test -- --run --changed
```

**How it works:**
- Uses git to detect changed files
- Watches import graph
- Runs affected tests automatically

**Advantages over Jest:**
- Faster change detection
- Better watch mode integration
- Native ESM support

### Coverage Support
**Package:** `@vitest/coverage-v8` or `@vitest/coverage-istanbul`

**Installation:**
```bash
npm install --save-dev @vitest/coverage-v8
```

**Configuration:**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },
  },
});
```

**Commands:**
```bash
# Run with coverage
npm test -- --coverage

# Coverage report location
open coverage/index.html
```

### Configuration Generated
```yaml
# .quality-config.yaml
testing:
  unit:
    framework: "vitest"
    vitest_config: "vitest.config.ts"
    changed_files_only: true
    coverage_required: false
```

### Pre-commit Hook
```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: vitest-tests
      name: Vitest Tests
      entry: bash -c 'npm test -- --run --changed'
      language: system
      files: '^(src|app)/.*\.(ts|tsx|js|jsx)$'
```

## Pytest (Python)

### Detection Criteria
```txt
# requirements.txt
pytest>=7.0.0
```

### Changed-Files Support
**Package:** `pytest-testmon`

**Installation:**
```bash
pip install pytest-testmon
```

**Example:**
```bash
# Phase 0: All tests
pytest

# Phase 1+: Changed files only
pytest --testmon
```

**How it works:**
- Tracks code dependencies
- Stores dependency graph in .testmondata
- Runs only tests affected by changes

### Coverage Support
**Package:** `coverage.py` or `pytest-cov`

**Installation:**
```bash
pip install coverage pytest-cov
```

**Configuration:**
```toml
# pyproject.toml
[tool.pytest.ini_options]
addopts = "--cov=app --cov-report=html --cov-report=term"

[tool.coverage.run]
source = ["app"]
omit = ["*/tests/*", "*/migrations/*"]

[tool.coverage.report]
fail_under = 80
```

**Commands:**
```bash
# Run with coverage
pytest --cov=app --cov-report=html

# Coverage report
open htmlcov/index.html
```

### Configuration Generated
```yaml
# .quality-config.yaml
testing:
  unit:
    framework: "pytest"
    pytest_config: "pyproject.toml"
    changed_files_only: true
    coverage_required: false
```

## Generic Fallback

### When Used
- Framework not recognized
- No test framework installed
- Custom test setup

### Behavior
```bash
# All phases: Run npm test or pytest
npm test  # JavaScript/TypeScript
pytest    # Python
```

### Limitations
- ❌ No changed-files optimization
- ❌ No framework-specific error messages
- ❌ Generic troubleshooting guidance

### Configuration
```yaml
testing:
  unit:
    enabled: true
    framework: "generic"
    custom_commands:
      phase0: "npm test"
      phase1: "npm test"  # Same as phase0
      phase2: "npm run test:coverage"
      phase3: "npm run test:coverage"
```

## Framework Comparison

### Performance: Changed-Files Testing

**Test scenario:** 5 changed files in 1000+ file codebase

| Framework | Phase 0 (All) | Phase 1 (Changed) | Improvement |
|-----------|---------------|-------------------|-------------|
| **Jest** | 180s | 8s | 22.5x faster |
| **Vitest** | 120s | 6s | 20x faster |
| **Pytest** | 90s | 5s | 18x faster |
| **Generic** | 180s | 180s | No improvement |

### Coverage Accuracy

| Framework | Coverage Type | Accuracy | Performance |
|-----------|--------------|----------|-------------|
| **Jest** | Istanbul | High | Fast |
| **Vitest** | V8 or Istanbul | Very High | Very Fast |
| **Pytest** | coverage.py | High | Fast |

### Developer Experience

| Feature | Jest | Vitest | Pytest | Generic |
|---------|------|--------|--------|---------|
| **Watch Mode** | ✅ Good | ✅ Excellent | ⚠️ Limited | ❌ No |
| **Error Messages** | ✅ Good | ✅ Excellent | ✅ Good | ⚠️ Basic |
| **Snapshot Testing** | ✅ Built-in | ✅ Built-in | ⚠️ Via plugin | ❌ No |
| **Parallel Execution** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Manual |
| **TypeScript Support** | ✅ Via ts-jest | ✅ Native | N/A | ⚠️ Manual |

## Migration Guides

### Jest → Vitest

**Benefits:**
- ⚡ 2-5x faster execution
- 🔄 Better watch mode
- 📦 Native ESM support
- 🎯 Better error messages

**Migration steps:** See [How to Configure Test Framework Detection](../how-to/configure-test-framework.md#task-migrate-from-jest-to-vitest)

### Mocha → Jest/Vitest

**Benefits:**
- ✅ Better TypeScript integration
- ✅ Built-in coverage
- ✅ Snapshot testing
- ✅ Changed-files optimization

**Compatibility:**
```javascript
// Mocha syntax (works in Jest/Vitest with globals: true)
describe('Suite', () => {
  it('should work', () => {
    expect(true).toBe(true);
  });
});
```

## Framework Detection Algorithm

### Auto-Detection Process

```bash
# 1. Scan package.json dependencies
FRAMEWORKS=$(cat package.json | jq -r '.devDependencies + .dependencies | keys[]')

# 2. Priority order (first match wins)
if echo "$FRAMEWORKS" | grep -q "vitest"; then
  FRAMEWORK="vitest"
elif echo "$FRAMEWORKS" | grep -q "jest"; then
  FRAMEWORK="jest"
elif echo "$FRAMEWORKS" | grep -q "cypress"; then
  FRAMEWORK="cypress"
elif echo "$FRAMEWORKS" | grep -q "@playwright/test"; then
  FRAMEWORK="playwright"
else
  FRAMEWORK="generic"
fi

# 3. Verify test script exists
if ! cat package.json | jq -e '.scripts.test' > /dev/null; then
  FRAMEWORK="generic"
fi
```

### Manual Override

```yaml
# .quality-config.yaml
testing:
  unit:
    framework: "jest"  # Override auto-detection
```

### Debug Detection

```bash
# View detection logic
DEBUG=1 ./scripts/validate-adaptive.sh

# Check package.json
cat package.json | jq '{
  dependencies: .dependencies | keys,
  devDependencies: .devDependencies | keys,
  scripts: .scripts
}'
```

## Troubleshooting

### Framework Not Detected

**Symptom:** Falls back to generic despite framework installed

**Solutions:**
1. Verify package.json: `npm list jest vitest`
2. Check test script: `cat package.json | jq .scripts.test`
3. Manual override in `.quality-config.yaml`
4. Regenerate config: `./scripts/generate-config.sh update`

### Changed-Files Not Working

**Symptom:** Runs all tests in Phase 1

**Solutions:**
1. Verify git tracking: `git status`
2. Check framework support (must be Jest/Vitest/Pytest)
3. Enable debug: `DEBUG=1 ./scripts/validate-adaptive.sh`
4. Check phase setting: `./scripts/quality-gate-manager.sh status`

### Coverage Reports Missing

**Symptom:** No coverage generated

**Solutions:**
1. Install coverage package:
   - Jest: Built-in
   - Vitest: `npm i --save-dev @vitest/coverage-v8`
   - Pytest: `pip install coverage pytest-cov`
2. Check config: `cat vitest.config.ts | grep coverage`
3. Run with coverage flag: `npm test -- --coverage`
4. Verify output: `ls coverage/`

## Related Documentation
- [How to Configure Test Framework Detection](../how-to/configure-test-framework.md)
- [Configuration API Reference](./quality-config-api.md)
- [Quality Gate Philosophy](../explanation/quality-gate-philosophy.md)
