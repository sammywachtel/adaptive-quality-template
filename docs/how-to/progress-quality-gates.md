# How to Progress Through Quality Gate Phases

**Task-oriented guide for graduated quality gate adoption without disrupting development**

## Context
The adaptive quality gate system uses 4 phases (0-3) to progressively improve code quality without blocking development. This guide shows how to advance through phases strategically.

## Quick Phase Reference

| Phase | Focus | Validation Scope | When to Use |
|-------|-------|-----------------|-------------|
| **0** | Baseline | Full codebase, prevent regressions | Initial setup, large legacy codebases |
| **1** | New code | Changed files only | Active development, fast iteration |
| **2** | Ratchet | Full repo + coverage improvement | Gradual quality improvement |
| **3** | Strict | Full repo, zero tolerance | Production-ready, new projects |

## Phase 0: Baseline & Stabilization

### Goal
Prevent code quality from getting worse while allowing existing issues.

### Setup
```bash
# Initialize quality gates at Phase 0
./scripts/quality-gate-manager.sh init

# Establish baseline for current code
./scripts/quality-gate-manager.sh baseline
```

### What It Does
- Documents current issues (445 TS errors, 303 ESLint issues, etc.)
- Blocks new issues or regressions
- Allows legacy issues to remain
- Validates full codebase on every run

### Expected Behavior
```bash
./scripts/validate-adaptive.sh

# Output:
# Phase 0: Baseline mode
# ✅ Baseline maintained (no regressions)
# ⚠️ 445 existing TypeScript issues (documented in baseline)
# ⚠️ 303 existing ESLint issues (documented in baseline)
```

### When to Advance
Advance to Phase 1 when:
- ✅ Baseline is stable (no new regressions for 1+ week)
- ✅ Team familiar with quality gate workflow
- ✅ Want faster validation during development

## Phase 1: Changed-Code-Only Enforcement

### Goal
Perfect code quality on new/modified files while leaving legacy code alone.

### Advance to Phase 1
```bash
# Advance from Phase 0
./scripts/quality-gate-manager.sh advance

# Or set directly
./scripts/quality-gate-manager.sh set-phase 1
```

### What Changes
- **Validation**: Only changed files checked (8 seconds vs 3 minutes)
- **Enforcement**: Strict on new code, warnings on legacy
- **Performance**: Sub-10-second feedback for most changes

### Expected Behavior
```bash
# Make changes to 3 files
git status
# Modified: src/file1.ts, src/file2.ts, tests/file1.test.ts

./scripts/validate-adaptive.sh

# Output:
# Phase 1: Changed-files-only mode
# Changed files: 3
# ✅ ESLint: 3 files (strict enforcement)
# ✅ TypeScript: 3 files (strict enforcement)
# ✅ Tests: Related tests for 3 files
# ⚡ Validation completed in 8 seconds
```

### Strategy: Perfect New Code
```bash
# Work on feature
vim src/new-feature.ts

# Quality check (fast!)
./scripts/validate-adaptive.sh  # 8 seconds

# Fix any issues in new code
npm run lint:fix

# Commit (pre-commit hooks run on changed files only)
git add .
git commit -m "Add new feature"
```

### When to Advance
Advance to Phase 2 when:
- ✅ New code consistently passes strict checks
- ✅ Ready to improve legacy code gradually
- ✅ Want to increase test coverage over time

## Phase 2: Ratchet & Expand Scope

### Goal
Gradual improvement across entire codebase with coverage ratcheting.

### Advance to Phase 2
```bash
./scripts/quality-gate-manager.sh advance

# Enable coverage ratchet
./scripts/quality-gate-manager.sh enable coverage-ratchet

# Enable security scanning (optional)
./scripts/quality-gate-manager.sh enable security-scanning
```

### What Changes
- **Validation**: Full repository validation
- **Coverage**: Must maintain or improve (no decreases allowed)
- **Strategy**: Module-by-module improvement campaigns

### Coverage Ratchet Behavior
```bash
# Initial state: 65% coverage
npm run test:coverage
# Coverage: 65%

# Ratchet locks this as minimum
./scripts/quality-gate-manager.sh baseline

# Future changes must maintain or improve
# Coverage drops to 64%
./scripts/validate-adaptive.sh
# ❌ Phase 2: Coverage regression detected (64% < 65%)

# Coverage improves to 67%
./scripts/validate-adaptive.sh
# ✅ Phase 2: Coverage improved (67% > 65%)
# Ratchet updated: new minimum is 67%
```

### Strategy: Module Improvement Campaigns
```bash
# Week 1: Improve auth module
vim src/auth/*.ts
npm run test:coverage  # Coverage: 65% → 72%
git commit -m "Improve auth module coverage"

# Week 2: Improve API module
vim src/api/*.ts
npm run test:coverage  # Coverage: 72% → 78%
git commit -m "Improve API module coverage"

# Ratchet automatically increases with each improvement
```

### When to Advance
Advance to Phase 3 when:
- ✅ Coverage at acceptable level (e.g., 80%+)
- ✅ Most legacy issues resolved
- ✅ Ready for strict production standards

## Phase 3: Normalize & Harden

### Goal
Full strict enforcement, zero technical debt tolerance.

### Advance to Phase 3
```bash
./scripts/quality-gate-manager.sh advance

# Enable all strict features
./scripts/quality-gate-manager.sh enable mypy
./scripts/quality-gate-manager.sh enable strict-typescript
```

### What Changes
- **Enforcement**: All issues blocking, no warnings
- **Scope**: Entire codebase must pass
- **Features**: All optional quality tools enabled

### Expected Behavior
```bash
./scripts/validate-adaptive.sh

# Output:
# Phase 3: Strict enforcement mode
# ✅ ESLint: 0 errors, 0 warnings (full repo)
# ✅ TypeScript: Strict mode, 0 errors (full repo)
# ✅ Tests: 100% passing, 85% coverage (full suite)
# ✅ MyPy: Strict typing, 0 errors (full repo)
# ✅ Security: No vulnerabilities detected
# 🔒 Production-ready quality standards achieved
```

### Production Readiness Checklist
- [ ] Zero ESLint errors/warnings
- [ ] Zero TypeScript errors
- [ ] 100% test pass rate
- [ ] 80%+ test coverage
- [ ] Zero security vulnerabilities
- [ ] MyPy strict typing passes (Python)
- [ ] No pre-commit hook bypasses

### When to Use
Use Phase 3 for:
- New projects (strict from day 1)
- Production-critical services
- Libraries/packages
- Projects requiring compliance

## Phase Management Commands

### Check Current Phase
```bash
./scripts/quality-gate-manager.sh status

# Output:
# Current phase: 1 (Changed-files-only)
# Validation scope: Changed files only
# Next phase: 2 (Ratchet & Expand)
#
# Enabled features:
# - eslint: ✅
# - typescript: ✅
# - unit-tests: ✅
#
# Disabled features:
# - coverage-ratchet: ❌
# - mypy: ❌
# - security-scanning: ❌
```

### Advance Phase
```bash
# Move to next phase
./scripts/quality-gate-manager.sh advance

# Set specific phase
./scripts/quality-gate-manager.sh set-phase 2

# Rollback to previous phase
./scripts/quality-gate-manager.sh rollback
```

### Feature Management
```bash
# Enable feature
./scripts/quality-gate-manager.sh enable coverage-ratchet
./scripts/quality-gate-manager.sh enable security-scanning
./scripts/quality-gate-manager.sh enable mypy

# Disable feature
./scripts/quality-gate-manager.sh disable strict-typescript

# List available features
./scripts/quality-gate-manager.sh features
```

### Baseline Management
```bash
# Establish/update baseline
./scripts/quality-gate-manager.sh baseline

# Check for regressions
./scripts/quality-gate-manager.sh check

# View baseline
cat .quality-baseline.json
```

## Common Scenarios

### Scenario 1: Large Legacy Codebase (445 TS Errors)
**Progression Timeline:**
```bash
# Week 1: Phase 0 - Baseline
./scripts/quality-gate-manager.sh init
./scripts/quality-gate-manager.sh baseline
# Focus: Prevent new errors

# Week 2-8: Phase 1 - Perfect new code
./scripts/quality-gate-manager.sh advance
# Focus: All new code error-free

# Month 3-6: Phase 2 - Gradual improvement
./scripts/quality-gate-manager.sh advance
./scripts/quality-gate-manager.sh enable coverage-ratchet
# Focus: Module-by-module fixes

# Month 6+: Phase 3 - Production ready
./scripts/quality-gate-manager.sh advance
# Focus: Zero technical debt
```

### Scenario 2: New Project (Start Strict)
**Immediate Phase 3:**
```bash
# Initialize at Phase 3
./scripts/quality-gate-manager.sh init
./scripts/quality-gate-manager.sh set-phase 3

# Enable all features
./scripts/quality-gate-manager.sh enable coverage-ratchet
./scripts/quality-gate-manager.sh enable security-scanning
./scripts/quality-gate-manager.sh enable mypy
./scripts/quality-gate-manager.sh enable strict-typescript

# Maintain perfection from day 1
```

### Scenario 3: Rapid Prototyping → Production
**Flexible Progression:**
```bash
# Prototyping (Week 1-2): Phase 0
./scripts/quality-gate-manager.sh set-phase 0
# Fast iteration, document baseline

# Feature Development (Week 3-6): Phase 1
./scripts/quality-gate-manager.sh set-phase 1
# Perfect new code, fast feedback

# Pre-Production (Week 7-8): Phase 2
./scripts/quality-gate-manager.sh set-phase 2
./scripts/quality-gate-manager.sh enable coverage-ratchet
# Improve coverage, fix legacy issues

# Production Launch: Phase 3
./scripts/quality-gate-manager.sh set-phase 3
# Strict enforcement, production ready
```

## Troubleshooting

### Phase Advancement Blocked
**Symptom:** `./scripts/quality-gate-manager.sh advance` fails

**Solutions:**
```bash
# Check current issues
./scripts/validate-adaptive.sh

# View specific blockers
./scripts/quality-gate-manager.sh status

# Options:
# 1. Fix blockers before advancing
# 2. Update baseline to allow specific issues
./scripts/quality-gate-manager.sh baseline
# 3. Force advancement (not recommended)
./scripts/quality-gate-manager.sh set-phase 2 --force
```

### Phase 1 Not Detecting Changes
**Symptom:** Validates full repo instead of changed files

**Solutions:**
```bash
# Check git status
git status

# Verify phase setting
./scripts/quality-gate-manager.sh status

# Debug detection
DEBUG=1 ./scripts/validate-adaptive.sh

# Ensure git tracking
git add .  # Stage changes first
```

### Phase 2 Coverage Ratchet Too Strict
**Symptom:** Can't commit because coverage dropped slightly

**Solutions:**
```bash
# Option 1: Improve coverage
npm run test:coverage
# Add tests to increase coverage

# Option 2: Adjust threshold
vim .quality-config.yaml
# Lower coverage_threshold temporarily

# Option 3: Reset ratchet
./scripts/quality-gate-manager.sh baseline
# Resets to current coverage level

# Option 4: Disable ratchet temporarily
./scripts/quality-gate-manager.sh disable coverage-ratchet
```

## Validation Checklist

After phase advancement:

- [ ] Verify phase: `./scripts/quality-gate-manager.sh status`
- [ ] Test validation: `./scripts/validate-adaptive.sh`
- [ ] Check performance: `time ./scripts/validate-adaptive.sh`
- [ ] Test pre-commit hooks: `pre-commit run --all-files`
- [ ] Verify CI workflow: Push changes and check GitHub Actions
- [ ] Update team: Announce phase change and new expectations

## Related Guides
- [How to Apply Template to Existing Project](./apply-template-to-existing-project.md)
- [How to Configure Test Framework Detection](./configure-test-framework.md)
- [Quality Gate Phase Comparison](../explanation/quality-gate-philosophy.md)
- [Configuration API Reference](../reference/quality-config-api.md)
