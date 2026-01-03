# How to Upgrade ESLint from v8 to v9

**Task-oriented guide for migrating to ESLint v9 flat config format**

## Context
ESLint v9 introduced a new **flat config** format that completely replaces the legacy `.eslintrc.*` files. The adaptive template automatically handles this migration.

## Prerequisites
- Project using ESLint v8 or earlier
- Node.js 16+ installed
- Git repository initialized

## Automatic Migration (Recommended)

### 1. Upgrade ESLint
```bash
cd your-project
npm install --save-dev eslint@latest
```

### 2. Apply Template (Auto-Migration)
```bash
# Template detects ESLint v9 and generates flat config automatically
/path/to/template/setup-new-project.sh . --overwrite-tools
```

### 3. Verify Migration
```bash
# Check for new flat config
ls -la eslint.config.mjs

# Verify ESLint works
npm run lint

# If successful, remove old config
rm .eslintrc.json .eslintrc.js .eslintrc.yml
```

## Manual Migration (If Needed)

### 1. Check Current ESLint Version
```bash
npm list eslint
# If < 9.0.0, upgrade first
npm install --save-dev eslint@latest
```

### 2. Install TypeScript ESLint (for TypeScript projects)
```bash
# ESLint v9 uses new package name
npm install --save-dev typescript-eslint

# Remove old packages (if present)
npm uninstall @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

### 3. Create Flat Config File
**For TypeScript projects**, create `eslint.config.mjs`:
```javascript
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
      // Migrate your custom rules here
    },
  },
);
```

**For JavaScript projects**, create `eslint.config.js`:
```javascript
import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    rules: {
      // Your custom rules
    },
  },
];
```

### 4. Update package.json Scripts
```json
{
  "scripts": {
    "lint": "eslint .",         // Remove --ext flag (not needed in v9)
    "lint:fix": "eslint . --fix"
  }
}
```

### 5. Test the Migration
```bash
# Run linting
npm run lint

# Fix auto-fixable issues
npm run lint:fix

# Check specific files
npm run lint src/myfile.ts
```

### 6. Remove Old Config
```bash
# Only after verifying new config works!
rm .eslintrc.json .eslintrc.js .eslintrc.yml .eslintrc.cjs
```

## Common Migration Issues

### Issue 1: ESLint Ignoring New Config
**Symptom:** ESLint still using old behavior or ignoring rules

**Solution:**
```bash
# 1. Ensure old config is removed
rm .eslintrc.*

# 2. Verify flat config exists
ls eslint.config.mjs

# 3. Check ESLint version
npm list eslint  # Must be 9.0.0+

# 4. Clear cache
rm -rf node_modules/.cache
npm run lint
```

### Issue 2: TypeScript Rules Not Working
**Symptom:** TypeScript-specific rules not enforced

**Solution:**
```bash
# 1. Verify typescript-eslint is installed (NEW package name)
npm list typescript-eslint

# 2. If not installed or old package:
npm install --save-dev typescript-eslint
npm uninstall @typescript-eslint/parser @typescript-eslint/eslint-plugin

# 3. Regenerate config
/path/to/template/scripts/generate-config.sh update
```

### Issue 3: Import Statement Errors
**Symptom:** `Cannot use import statement outside a module`

**Solution:**
```bash
# 1. Use .mjs extension for flat config
mv eslint.config.js eslint.config.mjs

# OR add "type": "module" to package.json
# Then you can use .js extension
```

### Issue 4: Project Service Errors
**Symptom:** `Error: "parserOptions.project" has been deprecated`

**Solution:**
```javascript
// Old (deprecated):
parserOptions: {
  project: './tsconfig.json'
}

// New (ESLint v9):
parserOptions: {
  projectService: true,
  tsconfigRootDir: import.meta.dirname,
}
```

## Validating Migration Success

### Check 1: Config File Format
```bash
# Should see flat config (ESLint v9)
ls eslint.config.mjs

# Should NOT see old config
ls .eslintrc.* 2>/dev/null || echo "✓ Old config removed"
```

### Check 2: Linting Works
```bash
# Should run without errors (warnings OK)
npm run lint

# Should fix issues
npm run lint:fix
```

### Check 3: TypeScript Integration
```bash
# For TypeScript projects, verify type-aware linting
npm run lint src/  # Should catch TypeScript-specific issues
```

### Check 4: Pre-commit Hooks
```bash
# Verify hooks use new config
pre-commit run --all-files

# Should show ESLint running successfully
```

## Configuration Examples

### Minimal JavaScript Config
```javascript
// eslint.config.js
import js from '@eslint/js';

export default [js.configs.recommended];
```

### TypeScript with Custom Rules
```javascript
// eslint.config.mjs
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
      '@typescript-eslint/no-unused-vars': ['error', {
        argsIgnorePattern: '^_'
      }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
  },
);
```

### React with TypeScript
```javascript
// eslint.config.mjs
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  react.configs.flat.recommended,
  {
    settings: {
      react: {
        version: 'detect',
      },
    },
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
  },
);
```

## Rollback Plan

If migration fails and you need to rollback:

### 1. Downgrade ESLint
```bash
npm install --save-dev eslint@8
```

### 2. Restore Old Config
```bash
# Restore from git
git checkout .eslintrc.json

# Or recreate basic config
cat > .eslintrc.json << 'EOF'
{
  "extends": ["eslint:recommended"],
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  }
}
EOF
```

### 3. Remove Flat Config
```bash
rm eslint.config.mjs eslint.config.js
```

### 4. Verify Rollback
```bash
npm run lint
```

## Learn More

- **Official Migration Guide**: https://eslint.org/docs/latest/use/configure/migration-guide
- **Flat Config Specification**: https://eslint.org/docs/latest/use/configure/configuration-files
- **TypeScript ESLint v9**: https://typescript-eslint.io/getting-started

## Related Guides
- [How to Apply Template to Existing Project](./apply-template-to-existing-project.md)
- [How to Configure Test Framework Detection](./configure-test-framework.md)
- [Configuration API Reference](../reference/quality-config-api.md)
