# Code Search & Navigation

CLI equivalents for Android Studio's `code_search`, `find_files`, `find_usages`, and `resolve_symbol` tools.

**Tool preference order:**
1. `git grep` — generally available in any Android project, automatically respects `.gitignore` (no `--exclude-dir=build` needed), searches only tracked files.
2. `rg` (ripgrep) — fastest option if installed; also respects `.gitignore`.
3. `grep` — POSIX fallback; requires explicit `--exclude-dir=build`.

The examples below use `grep` for broad compatibility. Equivalent `git grep` and `rg` forms are shown inline.

## 1. Finding Files

Equivalent to `find_files`.

```bash
# Find by filename (exclude build directories)
find . -name "HomeScreen.kt" -not -path "*/build/*"
find . -name "*ViewModel*.kt" -not -path "*/build/*"
find . -name "build.gradle.kts" -not -path "*/build/*"

# Find by extension — Kotlin, Java, or both
find . -name "*.kt" -not -path "*/build/*"
find . -name "*.java" -not -path "*/build/*"
find . \( -name "*.kt" -o -name "*.java" \) -not -path "*/build/*"

# Find by partial path
find . -path "*/ui/screens/*" -name "*.kt" -not -path "*/build/*"

# Case-insensitive
find . -iname "*home*" \( -name "*.kt" -o -name "*.java" \) -not -path "*/build/*"
```

> **With ripgrep/fd (faster, respects .gitignore):**
> `rg --files | grep "HomeScreen.kt"` or `fd -e kt -e java HomeScreen`

## 2. Searching Code Content

Equivalent to `code_search`.

The project uses Kotlin primarily. Legacy Java files (`*.java`) may also be present — always include both when searching the full codebase.

```bash
# Search Kotlin files
grep -rn "SomeFunction" --include="*.kt" app/src

# Search Java files
grep -rn "SomeFunction" --include="*.java" app/src

# Search both Kotlin and Java (full source search)
grep -rn "SomeFunction" --include="*.kt" --include="*.java" app/src

# Case-insensitive across both
grep -rni "homescreen" --include="*.kt" --include="*.java" app/src

# Multiple file types including build scripts
grep -rn "TODO" --include="*.kt" --include="*.java" --include="*.kts" app/

# Show context around match (3 lines before/after)
grep -rn -C 3 "StateFlow" --include="*.kt" app/src/main

# Search in specific directory only
grep -rn "receiptParser" --include="*.kt" --include="*.java" app/src/main/java
```

### Useful flags
```bash
# Show only file paths (no content)
grep -rl "LazyColumn" --include="*.kt" --include="*.java" app/src

# Count matches per file
grep -rc "StateFlow" --include="*.kt" --include="*.java" app/src | grep -v ":0$"

# Files NOT containing pattern
grep -rL "TODO" --include="*.kt" app/src

# Fixed string (no regex)
grep -rn -F "val state = " --include="*.kt" app/src

# Exclude build directories
grep -rn "pattern" --include="*.kt" --include="*.java" --exclude-dir=build app/src
```

> **With git grep:** `git grep -n "LazyColumn" -- '*.kt' '*.java'`
> **With ripgrep:** `rg "LazyColumn" -t kt -t java app/src`

## 3. Finding Usages

Equivalent to `find_usages` — find all references to a symbol.

```bash
# Find usages of a function/class/variable — search both Kotlin and Java
grep -rn -w "ReceiptParser" --include="*.kt" --include="*.java" app/src

# Find all usages across the whole project
grep -rn -w "ReceiptParser" --include="*.kt" --include="*.java" .

# Find usages excluding the declaration
grep -rn -w "ReceiptParser" --include="*.kt" --include="*.java" . \
  | grep -v "class ReceiptParser"

# Find usages in imports (Kotlin and Java share the same import pattern)
grep -rn "import.*ReceiptParser" --include="*.kt" --include="*.java" .

# Find callers of a function
grep -rn -w "parseReceipt" --include="*.kt" --include="*.java" .

# Find implementations of an interface (Kotlin style)
grep -rn ": ReceiptParser" --include="*.kt" .

# Find implementations of an interface (Java style)
grep -rn "implements ReceiptParser" --include="*.java" .
```

### Find all overrides
```bash
# Kotlin overrides
grep -rn "override fun parseReceipt" --include="*.kt" .

# Java overrides
grep -rn "@Override" -A 1 --include="*.java" . | grep "parseReceipt"

# Find all classes implementing an interface (both languages)
grep -rn ": SomeInterface" --include="*.kt" . | grep "class "
grep -rn "implements SomeInterface" --include="*.java" .
```

> **With git grep:** `git grep -n -w "ReceiptParser" -- '*.kt' '*.java'`
> **With ripgrep:** `rg -w "ReceiptParser" -t kt -t java`

## 4. Symbol Resolution

Equivalent to `resolve_symbol`. Full symbol resolution requires a Language Server (LSP). Without one, use pattern-matching:

### Find the declaration of a symbol
```bash
# Kotlin class declaration
grep -rn "^class ReceiptParser\|^data class ReceiptParser\|^sealed class ReceiptParser" --include="*.kt" .

# Java class declaration
grep -rn "class ReceiptParser" --include="*.java" .

# Kotlin function declaration
grep -rn "fun parseReceipt" --include="*.kt" . | grep -v "override"

# Java method declaration
grep -rn "parseReceipt(" --include="*.java" . | grep -v "//"

# Kotlin val/var declaration
grep -rn "val receiptParser\|var receiptParser" --include="*.kt" .

# Kotlin interface declaration
grep -rn "^interface ReceiptParser" --include="*.kt" .

# Java interface declaration
grep -rn "interface ReceiptParser" --include="*.java" .

# General Kotlin top-level declaration
grep -rn "^\(class\|data class\|sealed class\|interface\|object\|fun\|val\|var\|enum class\|typealias\) ReceiptParser" --include="*.kt" .
```

> **Full LSP** — for true go-to-definition in terminal editors (Neovim, Helix, Zed), install
> [kotlin-language-server](https://github.com/fwcd/kotlin-language-server/releases).

## 5. Project-Wide Refactoring Patterns

### Rename a symbol across files
```bash
# Preview all occurrences first (Kotlin + Java)
grep -rn -w "OldName" --include="*.kt" --include="*.java" .

# Replace in Kotlin files (macOS: requires empty string for -i)
find . -name "*.kt" -not -path "*/build/*" \
  -exec sed -i '' 's/\bOldName\b/NewName/g' {} +

# Replace in Java files too
find . -name "*.java" -not -path "*/build/*" \
  -exec sed -i '' 's/\bOldName\b/NewName/g' {} +

# Or both at once with perl (cross-platform)
find . \( -name "*.kt" -o -name "*.java" \) -not -path "*/build/*" \
  -exec perl -pi -e 's/\bOldName\b/NewName/g' {} +
```

### Find all TODOs and FIXMEs
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.kt" --include="*.java" --include="*.kts" .

# With context
grep -rn -C 1 "TODO" --include="*.kt" --include="*.java" .

# Count by file
grep -rc "TODO" --include="*.kt" --include="*.java" . | grep -v ":0$" | sort -t: -k2 -rn | head -20
```

## 6. XML / Manifest / Resource Search

```bash
# Search in AndroidManifest.xml
grep -n "android:name" app/src/main/AndroidManifest.xml

# Search in layout/resource files
grep -rn "android:id" --include="*.xml" app/src/main/res

# Find a color or string resource
grep -rn "color_primary" --include="*.xml" app/src/main/res
grep -rn "app_name" --include="*.xml" app/src/main/res

# Find resource usages in Kotlin
grep -rn "R\.color\.color_primary" --include="*.kt" .
grep -rn "R\.string\.app_name" --include="*.kt" .
```

## 7. Gradle / Build Script Search

The project may use Kotlin DSL (`*.kts`) or Groovy DSL (`*.gradle`) build scripts.

```bash
# Search in Kotlin DSL build files
grep -rn "ktor" --include="*.kts" .

# Search in Groovy DSL build files
grep -rn "ktor" --include="*.gradle" .

# Search both DSL flavors at once
grep -rn "ktor" --include="*.kts" --include="*.gradle" .

# Find plugin usage (Kotlin DSL)
grep -rn "id(" --include="*.kts" .

# Find plugin usage (Groovy DSL)
grep -rn "apply plugin\|id '" --include="*.gradle" .

# Find dependency declarations (search whichever build file exists)
grep -n "implementation\|api\|runtimeOnly" app/build.gradle.kts 2>/dev/null || \
  grep -n "implementation\|api\|runtimeOnly" app/build.gradle

# Find a library in version catalog
grep -n "ktor" gradle/libs.versions.toml
```

## 8. Search Shortcuts

```bash
# Add to ~/.zshrc for Android development
# Searches Kotlin + Java source files
alias srcsearch='grep -rn --include="*.kt" --include="*.java" --exclude-dir=build'
alias ktsearch='grep -rn --include="*.kt" --include="*.kts" --exclude-dir=build'
alias xmlsearch='grep -rn --include="*.xml" --exclude-dir=build'

# Find class by name (Kotlin or Java)
kclass() {
  grep -rn -w "class $1\|interface $1\|object $1" --include="*.kt" --exclude-dir=build .
  grep -rn -w "class $1\|interface $1" --include="*.java" --exclude-dir=build .
}

# Find function/method by name (Kotlin or Java)
kfun() {
  grep -rn -w "fun $1" --include="*.kt" --exclude-dir=build .
  grep -rn -w "$1(" --include="*.java" --exclude-dir=build . | grep -v "//"
}

# Usage:
# kclass "ReceiptParser"
# kfun "parseReceipt"
```

## Do / Don't

| Do | Don't |
|---|---|
| Include both `--include="*.kt"` and `--include="*.java"` for full source search | Search only `*.kt` and miss legacy Java callers/implementors |
| Use `grep -w` for exact symbol match | Use bare `grep` without `-w` (matches substrings like `Parser` in `ReceiptParserUtil`) |
| Use `grep -rl` to get file list before editing | Blindly run replace on all files |
| Search both `*.kts` and `*.gradle` when looking in build scripts | Assume all build scripts use Kotlin DSL — projects may mix both |
| Prefer `git grep` — `.gitignore` excludes `build/` automatically | Use bare `grep -r` without `--exclude-dir=build` (pollutes results with generated files) |
| Preview with `grep` before any rename | Run `sed` replace without previewing first |
| Use `find` + `grep` for complex multi-step searches | Pipe deeply nested commands without testing each step |
