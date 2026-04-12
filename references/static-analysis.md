# Static Analysis

CLI equivalent for Android Studio's `analyze_current_file` tool. Covers Android Lint,
Kotlinter (ktlint), and Detekt.

## 1. Android Lint

### Running lint
```bash
# Lint all variants
./gradlew lint

# Lint specific module
./gradlew :module:lint

# Lint specific variant
./gradlew :module:lintDebug
./gradlew :module:lintRelease

# Lint and fail build on errors (default for release)
./gradlew :module:lintRelease
```

### Reports
```bash
# Reports are generated at:
# HTML: app/build/reports/lint-results-debug.html
# XML:  app/build/reports/lint-results-debug.xml
# SARIF: app/build/reports/lint-results-debug.sarif (if configured)

# Open HTML report (macOS)
open app/build/reports/lint-results-debug.html

# Parse XML for errors only (grep + awk, no python needed)
grep 'severity="Error"' app/build/reports/lint-results-debug.xml | 
  sed 's/.*id="//;s/".*//' | sort | uniq -c | sort -rn
# Full error details:
grep -B 0 -A 3 'severity="Error"' app/build/reports/lint-results-debug.xml
```

### Lint configuration in `build.gradle.kts`
```kotlin
android {
    lint {
        abortOnError = true             // Fail build on errors
        warningsAsErrors = false        // Don't treat warnings as errors
        checkReleaseBuilds = true       // Run on release
        enable += "StopShip"           // Enable specific check
        htmlReport = true
        xmlReport = true
    }
}
```

### Custom lint checks
```bash
# See all available lint checks
$ANDROID_HOME/cmdline-tools/latest/bin/lint --list

# Run specific check only
./gradlew :module:lintDebug -Dlint.checks=HardcodedText,ContentDescription

# Check a single file (standalone lint tool)
$ANDROID_HOME/cmdline-tools/latest/bin/lint 
  --check HardcodedText 
  app/src/main/java/com/example/app/ui/HomeScreen.kt
```

## 2. Kotlinter (ktlint wrapper)

Used in projects with `id("org.jmailen.kotlinter")` plugin.

```bash
# Check formatting (no changes)
./gradlew lintKotlin

# Auto-fix formatting
./gradlew formatKotlin

# Check a specific module
./gradlew :module:lintKotlin
./gradlew :module:formatKotlin

# Reports at:
# app/build/reports/ktlint/
```

### Kotlinter configuration (`.editorconfig` or `build.gradle.kts`)
```kotlin
// build.gradle.kts
kotlinter {
    failBuildWhenCannotAutoFormat = false
    reporters = arrayOf("checkstyle", "plain")
}
```

```ini
# .editorconfig (project root)
[*.{kt,kts}]
indent_size = 4
max_line_length = 120
ktlint_standard_no-wildcard-imports = disabled
```

## 3. Detekt

Advanced static analysis for Kotlin (not built into Android Studio, but common in Android projects).

```bash
# Add to build.gradle.kts:
# plugins { id("io.gitlab.arturbosch.detekt") version "1.23.6" }

# Run detekt
./gradlew detekt

# Run with auto-correct (for formatting rules only)
./gradlew detekt --auto-correct

# Specific module
./gradlew :module:detekt

# Reports at:
# app/build/reports/detekt/detekt.html
# app/build/reports/detekt/detekt.xml
```

### Detekt config (`detekt.yml`)
```yaml
complexity:
  LongMethod:
    threshold: 60
  LongParameterList:
    functionThreshold: 8

style:
  MagicNumber:
    active: true
    ignoreNumbers: ['-1', '0', '1', '2']

naming:
  FunctionNaming:
    functionPattern: '([a-z][a-zA-Z0-9]*)|(`[^`]+`)'  # Allows composable names
```

## 4. Compose-Specific Rules (io.nlopez.compose.rules)

Used in this project via `compose-rules-ktlint`. Checks Compose-specific patterns.

```bash
# Already integrated via kotlinter — just run:
./gradlew lintKotlin

# Rules enforced (examples):
# - ComposableNaming: @Composable functions should be PascalCase
# - CompositionLocalAllowlist: track CompositionLocal usage
# - ModifierMissing: top-level composables should have Modifier param
# - ViewModelInjection: use Hilt/Koin injection, not direct instantiation
```

## 5. Pre-commit Hook Setup

Enforce checks before every commit using a plain Git hook (no third-party tools):

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running ktlint check..."
./gradlew lintKotlin --daemon --quiet

echo "Running Android lint..."
./gradlew :module:lintDebug --daemon --quiet

echo "All checks passed."
```

```bash
chmod +x .git/hooks/pre-commit
```

## 6. Analysis in CI

```bash
# In GitHub Actions / CI pipeline
- name: Run lint
  run: ./gradlew :module:lintDebug --no-daemon

- name: Run ktlint
  run: ./gradlew lintKotlin --no-daemon

- name: Upload lint report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: lint-report
    path: app/build/reports/lint-results-debug.html
```

## Do / Don't

| Do | Don't |
|---|---|
| Run `lintKotlin` for formatting, `lint` for Android issues | Conflate ktlint and Android lint — they check different things |
| Use `.editorconfig` for shared ktlint rules | Hardcode ktlint config in multiple places |
| Fix formatting with `formatKotlin` before review | Manually fix indentation that ktlint would fix automatically |
| Run lint in CI on every PR | Only run lint locally (regressions slip through) |
