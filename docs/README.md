# Documentation Index

Welcome to the Adaptive Quality Gate Template System documentation. This documentation follows the [Diátaxis framework](https://diataxis.fr/) for clear, purpose-oriented content.

## 📚 Documentation Types

### 🎓 Tutorials
*Coming soon* - Step-by-step learning-oriented lessons for beginners.

### 🛠️ How-To Guides (Task-Oriented)

Practical solutions to specific problems:

- **[How to Apply Template to Existing Project](how-to/apply-template-to-existing-project.md)**
  - Apply adaptive quality gates to any project
  - Configuration modes (smart merge vs. overwrite)
  - Common scenarios and troubleshooting

- **[How to Progress Through Quality Gate Phases](how-to/progress-quality-gates.md)**
  - Graduate from Phase 0 (baseline) to Phase 3 (strict)
  - Phase management commands
  - Real-world progression strategies

- **[How to Upgrade ESLint from v8 to v9](how-to/upgrade-eslint-v9.md)**
  - Automatic migration to flat config
  - Manual migration steps
  - Troubleshooting ESLint v9 issues

- **[How to Configure Test Framework Detection](how-to/configure-test-framework.md)**
  - Set up Jest, Vitest, or custom frameworks
  - Debug test framework detection
  - Migrate between frameworks

### 📖 Reference (Information-Oriented)

Technical accuracy and comprehensive details:

- **[Configuration API Reference](reference/quality-config-api.md)**
  - Complete `.quality-config.yaml` specification
  - All configuration fields and options
  - Environment variable support
  - Validation and migration

- **[Test Framework Support Matrix](reference/test-framework-support.md)**
  - Supported frameworks: Jest, Vitest, Pytest
  - Changed-files optimization capabilities
  - Coverage integration
  - Performance comparisons

### 💡 Explanation (Understanding-Oriented)

Design decisions and architectural insights:

- **[Quality Gate Philosophy](explanation/quality-gate-philosophy.md)**
  - Why graduated quality enforcement
  - Design principles and rationale
  - The ratchet mechanism explained
  - Real-world case studies

## 🚀 Quick Start

**New to the template?** Start here:

1. **Understand the concept**: Read [Quality Gate Philosophy](explanation/quality-gate-philosophy.md)
2. **Apply to your project**: Follow [How to Apply Template](how-to/apply-template-to-existing-project.md)
3. **Learn phase progression**: See [How to Progress Through Phases](how-to/progress-quality-gates.md)
4. **Reference when needed**: Check [Configuration API](reference/quality-config-api.md)

## 📂 Project Documentation

Additional documentation outside this structured guide:

- **[Main README](../README.md)** - Project overview and quick start
- **[DEVELOPMENT.md](../template-files/DEVELOPMENT.md)** - Generated project development guide

## 🔍 Finding Information

### By Task
Looking to accomplish something specific? → **How-To Guides**

Examples:
- "I want to apply this template" → [Apply Template](how-to/apply-template-to-existing-project.md)
- "I need to configure tests" → [Configure Test Framework](how-to/configure-test-framework.md)
- "I want to advance phases" → [Progress Through Phases](how-to/progress-quality-gates.md)

### By Topic
Need detailed technical information? → **Reference**

Examples:
- "What does `current_phase` mean?" → [Configuration API](reference/quality-config-api.md#quality_gates)
- "Which test frameworks are supported?" → [Test Framework Support](reference/test-framework-support.md)
- "What are all the config options?" → [Configuration API](reference/quality-config-api.md)

### By Understanding
Want to understand why things work this way? → **Explanation**

Examples:
- "Why graduated phases?" → [Quality Gate Philosophy](explanation/quality-gate-philosophy.md#the-solution-graduated-quality-enforcement)
- "How does the ratchet work?" → [Quality Gate Philosophy](explanation/quality-gate-philosophy.md#the-coverage-ratchet-mechanism)
- "Why changed-files-only?" → [Quality Gate Philosophy](explanation/quality-gate-philosophy.md#the-changed-files-only-innovation)

## 🌟 Recently Added Features

### December 2024 Updates

**Jest/Vitest Auto-Detection** ✨
- Automatic test framework detection
- Framework-specific changed-files optimization
- Smart error messages and fix commands
- See: [Test Framework Support](reference/test-framework-support.md)

**ESLint v9 Flat Config** ✨
- Automatic migration from `.eslintrc.json` to `eslint.config.mjs`
- Version detection and config generation
- Zero manual intervention required
- See: [ESLint v9 Upgrade Guide](how-to/upgrade-eslint-v9.md)

**MyPy Dependency Auto-Detection** ✨
- Scans `requirements.txt` for type stubs
- Auto-configures MyPy with required dependencies
- No manual configuration needed
- See: [Main README - MyPy Detection](../README.md#-intelligent-mypy-dependency-detection)

## 📊 Documentation Coverage

| Category | Status | Documents |
|----------|--------|-----------|
| **Tutorials** | 🔜 Planned | 0 |
| **How-To Guides** | ✅ Complete | 4 |
| **Reference** | ✅ Complete | 2 |
| **Explanation** | ✅ Complete | 1 |

## 🤝 Contributing to Documentation

Found an error or want to improve documentation?

1. **Report issues**: File an issue describing the problem
2. **Suggest improvements**: PRs welcome for typos, clarity, examples
3. **Request topics**: Open an issue requesting new how-to guides or explanations

### Documentation Standards

- **Diátaxis framework**: Organize by purpose (tutorial/how-to/reference/explanation)
- **Update with code**: Documentation changes in same commit as code changes
- **Markdown format**: Use GitHub-flavored Markdown
- **Examples**: Include real, tested examples
- **Links**: Use relative links between documents

## 📚 External Resources

### Template Development
- **Pre-commit hooks**: https://pre-commit.com/
- **GitHub Actions**: https://docs.github.com/en/actions
- **ESLint v9 Migration**: https://eslint.org/docs/latest/use/configure/migration-guide
- **Diátaxis Framework**: https://diataxis.fr/

### Quality Tools
- **Jest**: https://jestjs.io/
- **Vitest**: https://vitest.dev/
- **TypeScript**: https://www.typescriptlang.org/
- **Black**: https://black.readthedocs.io/
- **MyPy**: https://mypy-lang.org/

---

**Documentation Version**: 1.0.0 (January 2025)
**Last Updated**: 2025-01-03
