# Gradle Build Tasks

CLI equivalents for Android Studio's `gradle_build`, `get_assemble_task_for_artifact`, and related build tools.

## 1. Task Discovery

Equivalent to `get_assemble_task_for_artifact` and `get_test_task_for_artifact`.

```bash
# List ALL tasks in the project
./gradlew tasks

# List tasks for a specific module
./gradlew :module:tasks

# Filter by group
./gradlew tasks --group=build
./gradlew tasks --group=verification
./gradlew tasks --group=install

# Show all tasks including internal (verbose)
./gradlew tasks --all

# Show task dependencies
./gradlew :module:assembleDebug --dry-run
```

## 2. Assembling APKs and AABs

### APK
```bash
# Debug APK
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk

# Release APK (requires signing config)
./gradlew assembleRelease
# Output: app/build/outputs/apk/release/app-release.apk

# All variants
./gradlew assemble

# Specific module
./gradlew :module:assembleDebug

# With build flavors (e.g., flavor "paid", type "debug")
./gradlew assemblePaidDebug
```

### AAB (Android App Bundle)
```bash
# Debug bundle
./gradlew bundleDebug
# Output: app/build/outputs/bundle/debug/app-debug.aab

# Release bundle
./gradlew bundleRelease
# Output: app/build/outputs/bundle/release/app-release.aab
```

## 3. Build Variants

```bash
# List all build variants
./gradlew :module:tasks --group=build | grep -E "assemble|bundle"

# Or via Gradle model (prints variant names)
./gradlew :module:printVariants 2>/dev/null || echo "No custom printVariants task"

# Check build types and flavors (try KTS first, then Groovy DSL)
grep -E "buildTypes|productFlavors|flavorDimensions" app/build.gradle.kts 2>/dev/null || \
  grep -E "buildTypes|productFlavors|flavorDimensions" app/build.gradle
```

## 4. Clean Builds

```bash
# Clean build outputs
./gradlew clean

# Clean a specific module
./gradlew :module:clean

# Clean + build (common for CI)
./gradlew clean assembleDebug

# Clean Gradle caches (fixes mysterious build failures)
./gradlew clean --no-build-cache
rm -rf ~/.gradle/caches/build-cache-*
```

## 5. Incremental vs Full Builds

```bash
# Standard incremental build (Gradle decides what to rerun)
./gradlew assembleDebug

# Force rerun all tasks (ignore up-to-date checks)
./gradlew assembleDebug --rerun-tasks

# Use build cache (faster CI)
./gradlew assembleDebug --build-cache

# Disable configuration cache (troubleshooting)
./gradlew assembleDebug --no-configuration-cache

# Parallel execution (usually enabled in gradle.properties)
./gradlew assembleDebug --parallel

# Show build scan (requires Build Scan plugin or Gradle Enterprise)
./gradlew assembleDebug --scan
```

## 6. CI/CD Flags

Always pass these in CI environments:

```bash
# --no-daemon: Don't start/reuse Gradle daemon
# --stacktrace: Full stack trace on failure
# --info: Info-level logging
# -Pkotlin.incremental=false: Disable incremental Kotlin compilation for clean CI
./gradlew assembleDebug \
  --no-daemon \
  --stacktrace \
  --info \
  -Pkotlin.incremental=false
```

Or set in `gradle.properties` for local dev:
```properties
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
```

## 7. Build Performance

```bash
# Profile a build
./gradlew assembleDebug --profile
# Report: build/reports/profile/profile-*.html

# Show task timing without full profile
./gradlew assembleDebug --info 2>&1 | grep "Task.*took"

# Build scan (detailed)
./gradlew assembleDebug --scan

# Check what slows down configuration
./gradlew assembleDebug --configuration-cache-problems=warn
```

## 8. Checking Output Artifacts

```bash
# Find all generated APKs
find . -name "*.apk" -not -path "*/cache/*"

# Find latest APK (macOS)
find . -name "*.apk" -newer ./gradlew -not -path "*/cache/*" | head -5

# Get APK size
du -sh app/build/outputs/apk/debug/app-debug.apk

# Inspect APK contents
unzip -l app/build/outputs/apk/debug/app-debug.apk | head -40

# APK Analyzer alternative (aapt)
$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/aapt dump badging app-debug.apk
```

## 9. Gradle Wrapper

```bash
# Always use the wrapper
./gradlew <task>           # Unix/macOS
gradlew.bat <task>         # Windows

# Check wrapper version
./gradlew --version

# Upgrade Gradle wrapper
./gradlew wrapper --gradle-version 8.12 --distribution-type bin

# Verify wrapper checksum (security)
./gradlew wrapper --gradle-version 8.12 --gradle-distribution-sha256-sum <sha>
```

## 10. Common Build Errors

| Error | Likely Cause | Fix |
|---|---|---|
| `SDK location not found` | Missing `local.properties` | Add `sdk.dir=/path/to/sdk` |
| `Could not resolve` | Missing dependency / wrong repo | Check repos in `settings.gradle.kts` (or `settings.gradle`) |
| `Execution failed for task ':module:mergeDebugResources'` | Duplicate resource | Check for conflicting resource names |
| `Duplicate class` | Two libs provide same class | Add exclusion in `configurations.all {}` |
| `Configuration cache problems` | Unsupported API in build scripts | Disable with `--no-configuration-cache` to diagnose |
| `OutOfMemoryError` | Insufficient heap | Increase in `gradle.properties`: `org.gradle.jvmargs=-Xmx4g` |
| `Unsupported class file major version` | Wrong JDK version | Use JDK 17+ for AGP 8+; set `jvmToolchain(17)` |

## Do / Don't

| Do | Don't |
|---|---|
| Use `./gradlew` (wrapper), not `gradle` | Call system `gradle` — version mismatch |
| Pass `--no-daemon` in CI | Run with daemon in CI (can share stale state) |
| Run `clean` before diagnosing mysterious failures | Always run `clean` in local dev (kills incremental build) |
| Check `tasks --group=build` before guessing task names | Guess task names without `--dry-run` first |
| Use `--stacktrace` to get full error info | Read only the last line of a Gradle failure |
