# Testing from CLI

CLI equivalents for Android Studio's `get_test_task_for_artifact` and `get_test_artifacts_for_sub_project` tools.

## 1. Discovering Test Tasks

```bash
# List all verification/test tasks
./gradlew tasks --group=verification

# Module-specific
./gradlew :module:tasks --group=verification

# All test tasks across all modules
./gradlew tasks --all | grep -i test
```

Common test tasks per module:

| Task | What it runs |
|---|---|
| `test` | All JVM unit tests |
| `testDebugUnitTest` | Unit tests for debug variant |
| `testReleaseUnitTest` | Unit tests for release variant |
| `connectedAndroidTest` | All instrumented tests (requires device) |
| `connectedDebugAndroidTest` | Instrumented tests for debug variant |
| `createDebugCoverageReport` | JaCoCo coverage for debug unit tests |

## 2. Unit Tests (JVM)

No device required. Runs on the development machine.

```bash
# Run all unit tests in all modules
./gradlew test

# Run unit tests for a specific module
./gradlew :module:test

# Run for specific variant
./gradlew :module:testDebugUnitTest
./gradlew :module:testReleaseUnitTest

# Run and continue on failure (don't stop at first failure)
./gradlew test --continue

# Run and see output in terminal (not just in report)
./gradlew test --info

# Rerun tests even if up-to-date
./gradlew test --rerun-tasks
```

### Filter tests
```bash
# Run a specific test class
./gradlew :module:test --tests "com.example.app.MyViewModelTest"

# Run a specific test method
./gradlew :module:test --tests "com.example.app.MyViewModelTest.testLoginSuccess"

# Run tests matching a pattern
./gradlew :module:test --tests "*.ViewModelTest"
./gradlew :module:test --tests "com.example.app.*"

# Run tests by annotation (requires custom filtering — use class/method name instead)
```

### Test reports
```bash
# HTML report location
open app/build/reports/tests/testDebugUnitTest/index.html

# XML results (JUnit format — used by CI)
ls app/build/test-results/testDebugUnitTest/*.xml

# Parse XML for failures (grep + awk, no python needed)
find app/build/test-results -name "*.xml" -exec \
  grep -l "failure" {} \; | while read f; do
    echo "=== $f ==="
    grep -A 2 "<failure" "$f" | head -20
done
```

## 3. Instrumented Tests (Android Device)

Requires a connected device or running emulator.

```bash
# Run all instrumented tests (all connected devices)
./gradlew connectedAndroidTest

# Specific module
./gradlew :module:connectedAndroidTest
./gradlew :module:connectedDebugAndroidTest

# Target a specific device
adb -s <serial> shell echo "verify device"
./gradlew :module:connectedDebugAndroidTest   # Gradle uses ANDROID_SERIAL or only device

# Force target device via environment variable
ANDROID_SERIAL=<serial> ./gradlew :module:connectedDebugAndroidTest
```

### Filter instrumented tests
```bash
# Run specific class
./gradlew :module:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.example.app.MyInstrumentedTest

# Run specific method
./gradlew :module:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.example.app.MyInstrumentedTest#testFeature

# Run by annotation
./gradlew :module:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.annotation=com.example.app.SmokeTest

# Exclude by annotation
./gradlew :module:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.notAnnotation=com.example.app.LargeTest
```

### Run tests via ADB directly
```bash
# Find test runner
adb shell pm list instrumentation | grep com.example.app

# Run via am instrument
adb shell am instrument -w \
  -e class com.example.app.MyInstrumentedTest \
  com.example.app.test/androidx.test.runner.AndroidJUnitRunner

# Run specific method
adb shell am instrument -w \
  -e class com.example.app.MyInstrumentedTest#testFeature \
  com.example.app.test/androidx.test.runner.AndroidJUnitRunner
```

### Instrumented test reports
```bash
# HTML report
open app/build/reports/androidTests/connected/debug/index.html

# XML results
ls app/build/outputs/androidTest-results/connected/debug/*.xml
```

## 4. Emulator Management (for CI/testing without Android Studio)

```bash
# List available AVDs
$ANDROID_HOME/emulator/emulator -list-avds

# Start an emulator headless
$ANDROID_HOME/emulator/emulator -avd Pixel_6_API_34 -no-window -no-audio &

# Wait for emulator to boot
adb wait-for-device
adb shell 'while [ -z "$(getprop sys.boot_completed)" ]; do sleep 1; done'
echo "Emulator ready"

# Create an AVD from CLI
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n "test_device" \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_6"

# Install system image
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
  "system-images;android-34;google_apis;x86_64"
```

## 5. Test Coverage

```bash
# Enable coverage in build.gradle.kts:
# android { buildTypes { debug { enableUnitTestCoverage = true } } }

# Generate JaCoCo coverage report
./gradlew createDebugCoverageReport     # Instrumented
./gradlew testDebugUnitTestCoverage     # Unit tests (AGP 7.3+)

# Report location
open app/build/reports/coverage/androidTest/debug/connected/index.html
```

## 6. Screenshot / UI Tests

```bash
# Paparazzi (JVM screenshot tests, no device needed)
./gradlew :module:recordPaparazziDebug     # Record golden images
./gradlew :module:verifyPaparazziDebug     # Verify against goldens

# Roborazzi (Robolectric-based screenshot tests)
./gradlew :module:recordRoborazziDebug
./gradlew :module:verifyRoborazziDebug

# Espresso + screencap integration (on device)
adb exec-out screencap -p > before_test.png
./gradlew :module:connectedDebugAndroidTest
adb exec-out screencap -p > after_test.png
```

## 7. CI Test Pipeline

```yaml
# GitHub Actions example
- name: Run unit tests
  run: ./gradlew test --no-daemon --continue

- name: Upload test results
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: unit-test-results
    path: "**/build/test-results/**/*.xml"

- name: Start emulator
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 34
    script: ./gradlew connectedAndroidTest --no-daemon
```

## 8. Test Sharding

Split instrumented tests across multiple devices or CI runners for faster feedback.

### ADB-level sharding
```bash
# Shard into N parts, run shard index I (0-based)
adb shell am instrument -w \
  -e numShards 4 \
  -e shardIndex 0 \
  com.example.app.test/androidx.test.runner.AndroidJUnitRunner

# Shard 2 of 4
adb shell am instrument -w \
  -e numShards 4 \
  -e shardIndex 1 \
  com.example.app.test/androidx.test.runner.AndroidJUnitRunner
```

### Gradle-level sharding
```bash
# Pass sharding args through Gradle
./gradlew :module:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.numShards=4 \
  -Pandroid.testInstrumentationRunnerArguments.shardIndex=0
```

### CI matrix example (GitHub Actions)
```yaml
strategy:
  matrix:
    shard: [0, 1, 2, 3]
steps:
  - name: Run shard ${{ matrix.shard }}
    run: |
      ./gradlew :module:connectedDebugAndroidTest \
        -Pandroid.testInstrumentationRunnerArguments.numShards=4 \
        -Pandroid.testInstrumentationRunnerArguments.shardIndex=${{ matrix.shard }}
```

### Android Test Orchestrator
Runs each test in isolation (separate `Instrumentation` invocation). Slower but prevents shared state issues.

```kotlin
// build.gradle.kts
android {
    defaultConfig {
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
```

```bash
# Install orchestrator APKs on device
adb install -r orchestrator.apk
adb install -r test-services.apk

# Or let Gradle handle it (recommended)
./gradlew :module:connectedDebugAndroidTest
```

## 9. Accessibility Tests

Two complementary approaches that run on the JVM — no device required.

### Compose semantic assertions

Queries Compose's semantic tree directly (what TalkBack actually reads), not
the View layer. More reliable than `uiautomator dump` for Compose UI.

```kotlin
// build.gradle.kts
androidTestImplementation("androidx.compose.ui:ui-test-junit4")
```

```kotlin
@get:Rule val rule = createComposeRule()

@Test
fun nameField_hasAccessibilityLabel() {
    rule.setContent {
        HelloWorldScreen(uiState = GreetingUiState(), onNameChange = {})
    }

    // Verify the text field is labelled
    rule.onNode(hasSetTextAction())
        .assert(hasContentDescription("Your name") or hasText("Your name"))

    // Print full semantic tree to logcat for debugging (tag: "A11Y")
    rule.onRoot().printToLog("A11Y")
}
```

Useful matchers: `hasContentDescription()`, `hasClickAction()`,
`hasSetTextAction()`, `isEnabled()`, `isFocusable()`, `isNotEnabled()`.

### Accessibility Testing Framework (ATF)

Automatically audits every UI interaction in your test for common issues:
missing labels, insufficient touch target size, low contrast, duplicate
descriptions. No extra assertions needed — violations fail the test.

```kotlin
// build.gradle.kts
androidTestImplementation(
    "com.google.android.apps.common.testing.accessibility.framework:accessibility-test-framework:4.1.1"
)
```

```kotlin
@get:Rule val rule = createAndroidComposeRule<MainActivity>()

@Before
fun enableAtf() {
    AccessibilityChecks.enable().setRunChecksFromRootView(true)
}

@Test
fun mainScreen_passesAccessibilityChecks() {
    // ATF runs automatically on every action (click, scroll, etc.)
    // Any violation throws an exception with a clear description
    rule.onNodeWithText("Your name").performClick()
}
```

### Run and report

```bash
# Run accessibility tests (no device needed)
./gradlew :module:testDebugUnitTest --tests "*.AccessibilityTest"

# Run all unit tests including accessibility
./gradlew :module:testDebugUnitTest

# Reports
open app/build/reports/tests/testDebugUnitTest/index.html

# CI — upload results
# - name: Upload test results
#   if: always()
#   uses: actions/upload-artifact@v4
#   with:
#     name: accessibility-test-results
#     path: "**/build/test-results/**/*.xml"
```

### Compose label caveat

`uiautomator dump` (and `skill-scripts/check-accessibility.sh`) reads the View layer.
A Compose `OutlinedTextField` with `label = { Text("…") }` will appear
unlabelled in the dump but IS correctly labelled in the semantic tree.
Use semantic assertions above to verify Compose fields — not the dump script.

## Do / Don't

| Do | Don't |
|---|---|
| Run unit tests without a device | Use instrumented tests for pure logic — use unit tests |
| Use `--continue` to see all failures at once | Stop at first test failure during diagnosis |
| Filter by class/method name to iterate fast | Rerun the full suite every edit cycle |
| Use Paparazzi/Roborazzi for screenshot tests without a device | Use connected screenshot tests in CI (flaky, slow) |
| Use `ANDROID_SERIAL` for multi-device CI | Let Gradle pick a random device with multiple connected |
| Use sharding for large test suites in CI | Run 500+ tests on a single emulator — use 4+ shards |
| Use Test Orchestrator for flaky test isolation | Share state between tests via static variables |
| Use ATF + semantic assertions for Compose accessibility | Use `uiautomator dump` to check Compose UI labels |
