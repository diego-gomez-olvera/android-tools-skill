# Gradle Project Introspection

CLI equivalents for Android Studio's `get_top_level_sub_projects`, `get_build_file_location`,
`get_source_folders_for_artifact`, `get_gradle_artifact_from_file`, and `gradle_sync`.

## 1. Listing Subprojects

Equivalent to `get_top_level_sub_projects`.

```bash
# List all project modules
./gradlew projects

# List only immediate children
./gradlew projects 2>&1 | grep "--- Project"

# From settings file (fastest, no Gradle startup cost)
# Kotlin DSL
grep "^include" settings.gradle.kts 2>/dev/null || \
  grep "^include" settings.gradle     # Groovy DSL fallback

# Example output (Kotlin DSL)
# include(":app", ":core:data", ":feature:home")
# Example output (Groovy DSL)
# include ':app', ':core:data', ':feature:home'
```

### Map to module paths
```bash
# All module paths → build file locations
./gradlew projects 2>&1 | grep "Project ':'" | sed "s/.*Project '//;s/'$//"
```

## 2. Finding Build Files

Equivalent to `get_build_file_location`.

```bash
# Find all Gradle build files
find . -name "build.gradle.kts" -not -path "*/build/*"
find . -name "build.gradle" -not -path "*/build/*"

# Combined (Kotlin DSL + Groovy DSL)
find . \( -name "build.gradle.kts" -o -name "build.gradle" \) -not -path "*/build/*"

# For a known module name (e.g., ":app")
# Module :app → ./app/build.gradle.kts
echo "app/build.gradle.kts"

# For nested modules (e.g., ":feature:home")
# → ./feature/home/build.gradle.kts

# Verify a module's build file
./gradlew :module:buildEnvironment 2>&1 | head -20
```

## 3. Source Folders

Equivalent to `get_source_folders_for_artifact`.

> **Note:** `./gradlew :module:sourceSets` is a Java/Kotlin plugin task and is
> **not available in Android modules** (AGP does not expose it). Use `find`
> instead — it works on any project without Gradle startup cost.

```bash
# List all source directories for a module (exclude build outputs)
find . -path "*/app/src/*" -type d -not -path "*/build/*"

# Scope to a named module (e.g. :feature:home → feature/home)
find . -path "*/feature/home/src/*" -type d -not -path "*/build/*"

# All modules at once
find . -path "*/src/main" -o -path "*/src/test" -o -path "*/src/androidTest" \
  | grep -v "/build/" | sort

# Verify a specific source root exists
ls app/src/main/java 2>/dev/null || ls app/src/main/kotlin
```

### Common source folder structure (Android-only)
```text
app/src/
├── main/
│   ├── java/           # Kotlin/Java source
│   ├── kotlin/         # Kotlin source (alternative)
│   ├── res/            # Android resources
│   └── AndroidManifest.xml
├── test/               # JVM unit tests
│   └── java/
└── androidTest/        # Instrumented tests
    └── java/
```

### KMP source folder structure
```text
composeApp/src/
├── commonMain/         # Shared Kotlin
├── androidMain/        # Android-specific
├── iosMain/            # iOS-specific
├── commonTest/         # Shared tests
├── androidUnitTest/    # Android JVM tests
└── androidInstrumentedTest/  # Instrumented tests
```

## 4. Dependencies

Equivalent to `get_artifact_consumers` and investigating dependency graph.

```bash
# All dependencies for the debug configuration
./gradlew :module:dependencies --configuration debugRuntimeClasspath

# All configurations (verbose)
./gradlew :module:dependencies

# Specific configuration (common ones)
./gradlew :module:dependencies --configuration implementation
./gradlew :module:dependencies --configuration debugImplementation
./gradlew :module:dependencies --configuration testImplementation
./gradlew :module:dependencies --configuration androidTestImplementation

# Find what depends on a specific artifact (who uses X)
./gradlew :module:dependencies | grep -A 3 "ktor-client-core"

# Dependency insight: why is artifact X in the graph?
./gradlew :module:dependencyInsight \
  --dependency ktor-client-core \
  --configuration debugRuntimeClasspath
```

## 5. Build Environment

```bash
# Gradle/JVM version, plugins applied
./gradlew :module:buildEnvironment

# All resolved plugins
./gradlew :module:buildEnvironment 2>&1 | grep "^\\+"

# Properties for a module
./gradlew :module:properties

# Find specific property
./gradlew :module:properties 2>&1 | grep "android\."
```

## 6. Gradle Model Inspection

Useful when Gradle sync info is needed without the IDE.

```bash
# List tasks by group (all modules)
./gradlew tasks --all 2>&1 | grep -E "^[a-zA-Z]"

# Get available build types
./gradlew :module:tasks 2>&1 | grep -E "assemble|bundle" | grep -v "^--"

# Get all test tasks
./gradlew :module:tasks --group=verification

# Inspect generated code directories (KSP, kapt)
find app/build/generated -type d -maxdepth 4

# Gradle configuration cache state
./gradlew :module:assembleDebug --configuration-cache 2>&1 | grep "Configuration cache"
```

## 7. "Gradle Sync" Equivalent

Android Studio's `gradle_sync` updates its in-memory model. Outside the IDE, you approximate this with:

```bash
# Re-resolve all dependencies (network)
./gradlew dependencies --refresh-dependencies

# Validate build scripts parse correctly
./gradlew --dry-run

# Check if build scripts compile without building
./gradlew :module:assembleDebug --dry-run

# Validate version catalog
./gradlew :generateVersionCatalogAsToml --dry-run 2>/dev/null || true
```

## 8. Locate a File's Owning Module

Equivalent to `get_gradle_artifact_from_file`.

```bash
# Given a file path, find its module by tracing up to the nearest build.gradle.kts
FILE="app/src/main/java/com/example/app/ui/HomeScreen.kt"

# Walk up directories to find build file
dir=$(dirname "$FILE")
while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/build.gradle.kts" ] || [ -f "$dir/build.gradle" ]; then
    echo "Module root: $dir"
    # Convert to Gradle module path
    echo "Gradle path: :$(echo "$dir" | tr '/' ':')"
    break
  fi
  dir=$(dirname "$dir")
done
if [ "$dir" = "." ] || [ "$dir" = "/" ]; then
  echo "No build file found for $FILE"
fi
```

## 9. Settings and Repositories

Projects may use Kotlin DSL (`*.kts`) or Groovy DSL (`*.gradle`).

```bash
# View effective settings (try KTS first, fall back to Groovy)
cat settings.gradle.kts 2>/dev/null || cat settings.gradle

# View effective root build file
cat build.gradle.kts 2>/dev/null || cat build.gradle

# Check which DSL a module uses
ls app/build.gradle.kts app/build.gradle 2>/dev/null

# Check repository configuration
./gradlew :module:buildEnvironment 2>&1 | grep -A 20 "repositories"

# List all local Maven repos (useful for local library dev)
find ~/.m2/repository -name "*.aar" 2>/dev/null | head -10
```

## Do / Don't

| Do | Don't |
|---|---|
| Use `./gradlew projects` to list modules | Manually scan directories for modules |
| Use `./gradlew :module:sourceSets` for source dirs | Hardcode `src/main/java` paths |
| Use `dependencyInsight` to trace why a dep is included | Blindly add `exclude` rules |
| Use `--dry-run` to validate build scripts | Run a full build just to check script syntax |
| Read `settings.gradle.kts` (or `settings.gradle`) directly for include list | Parse Gradle output to find project structure |
