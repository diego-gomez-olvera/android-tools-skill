# Version Lookup & Dependency Management

CLI equivalents for Android Studio's `version_lookup` and `get_artifact_consumers` tools.

## 1. Checking Latest Versions

### Gradle Versions Plugin

```bash
# Check if the plugin is already applied
./gradlew tasks --all 2>/dev/null | grep -q dependencyUpdates \
  && echo "plugin present" || echo "plugin missing — see setup below"
```

If missing, add to the **root** `build.gradle.kts`:

```kotlin
plugins {
    id("com.github.ben-manes.versions") version "0.51.0"
}
```

Or via the version catalog (`gradle/libs.versions.toml`):

```toml
[versions]
benManes = "0.51.0"

[plugins]
versions = { id = "com.github.ben-manes.versions", version.ref = "benManes" }
```

```kotlin
// root build.gradle.kts
plugins {
    alias(libs.plugins.versions)
}
```

```bash
# Check for outdated dependencies
./gradlew dependencyUpdates

# Reject non-stable versions (alpha, beta, RC) in version report
./gradlew dependencyUpdates -Drevision=release

# Output as JSON
./gradlew dependencyUpdates --outputFormatter=json
# Report: build/dependencyUpdates/report.json

# Output as plain text
./gradlew dependencyUpdates --outputFormatter=plain
```

### Configure to skip unstable versions
```kotlin
// build.gradle.kts (root)
tasks.withType<DependencyUpdatesTask> {
    rejectVersionIf {
        listOf("alpha", "beta", "rc", "cr", "m", "preview", "b", "ea")
            .any { qualifier -> candidate.version.lowercase().contains(qualifier) }
    }
}
```

## 2. Maven Central / Google Maven Search

```bash
# Search via Maven Central REST API
curl -s "https://search.maven.org/solrsearch/select?q=g:io.ktor+a:ktor-client-core&rows=5&wt=json" \
  | grep -o '"latestVersion":"[^"]*"' | head -1 | sed 's/.*":"\(.*\)"/\1/'

# Check specific artifact on Google Maven
curl -s "https://dl.google.com/dl/android/maven2/androidx/compose/ui/ui/maven-metadata.xml" \
  | grep -E "<latest>|<release>" | head -5

# Check artifact version on Maven Central
# URL pattern: https://repo1.maven.org/maven2/<group>/<artifact>/maven-metadata.xml
# Example for Ktor:
curl -s "https://repo1.maven.org/maven2/io/ktor/ktor-client-core/maven-metadata.xml" \
  | grep "<release>" | head -1

# Compose BOM versions
curl -s "https://dl.google.com/dl/android/maven2/androidx/compose/compose-bom/maven-metadata.xml" \
  | grep "<release>"
```

### Helper function
```bash
# Add to ~/.zshrc or ~/.bashrc
maven_latest() {
  local group artifact
  IFS=: read -r group artifact <<< "$1"
  group_path=$(echo "$group" | tr '.' '/')
  curl -s "https://repo1.maven.org/maven2/$group_path/$artifact/maven-metadata.xml" \
    | grep -E "<release>|<latest>" | head -1 | sed 's/.*<[^>]*>//;s/<.*//'
}

# Usage:
maven_latest "io.ktor:ktor-client-core"
maven_latest "com.squareup.okhttp3:okhttp"
```

## 3. Dependency Tree

### View the full dependency tree
```bash
# Full tree for debug runtime classpath
./gradlew :module:dependencies --configuration debugRuntimeClasspath

# Compact tree (less verbose)
./gradlew :module:dependencies --configuration debugRuntimeClasspath 2>&1 | head -100

# All configurations
./gradlew :module:dependencies
```

### Find who brings in a specific dependency (`get_artifact_consumers`)
```bash
# Find what pulls in a transitive dependency
./gradlew :module:dependencyInsight \
  --dependency okhttp \
  --configuration debugRuntimeClasspath

# More specific
./gradlew :module:dependencyInsight \
  --dependency com.squareup.okhttp3:okhttp \
  --configuration debugRuntimeClasspath

# Example output:
# com.squareup.okhttp3:okhttp:4.12.0
# \--- com.squareup.retrofit2:retrofit:2.11.0
#      \--- implementation
```

### Find all consumers of a library across modules
```bash
# Search across all modules
for module in $(./gradlew projects 2>&1 | grep "Project ':'" | sed "s/.*Project '//;s/'$//"); do
  result=$(./gradlew "$module:dependencyInsight" --dependency okhttp \
    --configuration debugRuntimeClasspath 2>&1 | grep -v "^$")
  if echo "$result" | grep -q "okhttp"; then
    echo "=== $module ==="; echo "$result" | head -10
  fi
done
```

## 4. Dependency Conflicts

```bash
# Detect version conflicts (force resolution failure on conflict)
# In build.gradle.kts:
# configurations.all { resolutionStrategy { failOnVersionConflict() } }

# Force a specific version
./gradlew :module:dependencies --configuration debugRuntimeClasspath 2>&1 \
  | grep -E "FAILED|conflict|selected"

# Common conflict resolution in build.gradle.kts:
configurations.all {
    resolutionStrategy {
        force("com.squareup.okhttp3:okhttp:4.12.0")
        eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion(libs.versions.kotlin.get())
            }
        }
    }
}
```

## 5. Version Catalog Management

```bash
# View current versions
cat gradle/libs.versions.toml

# Check for BOM-managed versions (no version.ref needed in [libraries])
# Compose BOM, Firebase BOM, etc. handle transitive versions automatically

# Validate version catalog format
./gradlew :generateVersionCatalogAsToml --dry-run 2>/dev/null || \
  ./gradlew dependencies --configuration classpath 2>&1 | head -20

# Find all places a library version is referenced (KTS and Groovy DSL)
grep -r "libs\\.versions\\.kotlin" --include="*.kts" --include="*.gradle" .
grep -r "libs\\.kotlin" --include="*.kts" --include="*.gradle" .
```

## 6. SDK Manager (Android SDK Versions)

```bash
# List installed SDK packages
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list_installed

# List available packages
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list | head -50

# Install a specific SDK
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-35"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;35.0.0"

# Update all installed
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --update

# Accept all licenses
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses
```

## 7. Kotlin & AGP Compatibility

Check compatibility matrices before upgrading:

```bash
# Current versions in this project
./gradlew --version | grep Kotlin
grep "kotlin\|agp" gradle/libs.versions.toml

# Compatibility check (open in browser)
# Kotlin ↔ Compose: https://developer.android.com/jetpack/androidx/releases/compose-kotlin
# AGP ↔ Gradle: https://developer.android.com/build/releases/gradle-plugin#updating-gradle
# AGP ↔ Kotlin: Check AGP release notes for bundled Kotlin version (AGP 9+)
```

## Do / Don't

| Do | Don't |
|---|---|
| Use `dependencyUpdates` plugin for structured version reports | Manually check Maven Central for each dependency |
| Use `dependencyInsight` to trace why a transitive dep is included | Add `exclude` rules blindly without tracing the source |
| Pin versions via `resolutionStrategy.force()` only when conflict requires it | Pin all transitive versions (prevents automatic security updates) |
| Use BOM (Bill of Materials) for Compose, Firebase — managed as a unit | Mix BOM-managed and manually-versioned artifacts of the same group |
| Check Kotlin ↔ AGP compatibility before upgrading | Upgrade Kotlin and AGP independently without checking compatibility |
