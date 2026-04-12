---
name: android-tools-skill
license: MIT
description: >
  Android development tooling skill — ADB, Gradle CLI, static analysis, testing,
  deploy, and project introspection outside Android Studio.
  ONLY activate when the user writes the exact string "@android-tools-skill" or
  "android-tools-skill" in their message. Do NOT activate for "@tools", "@android-tools",
  "/tools", or any generic Android or tooling keyword — those belong to Android Studio
  built-ins. This skill must never be triggered by keyword matching.
metadata:
  version: "1.0"
---

# Android Tools — CLI Equivalents for Android Studio Tools

This skill gives AI coding agents production-grade knowledge of the Android
development toolchain **outside Android Studio**: ADB, Gradle CLI, lint, ktlint,
unit & instrumented tests, device deployment, project introspection, dependency
management, and code search. Every capability maps to an Android Studio built-in
tool and has a verified CLI equivalent.

## Tool Mapping (Studio → CLI)

| Android Studio Tool | CLI Equivalent | Reference |
|---|---|---|
| `adb_shell_input` | `adb shell input <type> <args>` | [adb-device.md](references/adb-device.md) |
| `take_screenshot` | `adb exec-out screencap -p > shot.png` | [adb-device.md](references/adb-device.md) |
| `ui_state` | `adb shell uiautomator dump` | [adb-device.md](references/adb-device.md) |
| `deploy` | `./gradlew installDebug` or `adb install` | [deploy.md](references/deploy.md) |
| `read_logcat` | `adb logcat` | [adb-logging.md](references/adb-logging.md) |
| `gradle_build` | `./gradlew <task>` | [gradle-build.md](references/gradle-build.md) |
| `get_assemble_task_for_artifact` | `./gradlew tasks --group=build` | [gradle-build.md](references/gradle-build.md) |
| `get_top_level_sub_projects` | `./gradlew projects` | [gradle-project.md](references/gradle-project.md) |
| `get_build_file_location` | `./gradlew <module>:buildEnvironment` | [gradle-project.md](references/gradle-project.md) |
| `get_source_folders_for_artifact` | `find . -path "*/<module>/src/*" -type d -not -path "*/build/*"` | [gradle-project.md](references/gradle-project.md) |
| `get_test_task_for_artifact` | `./gradlew tasks --group=verification` | [testing.md](references/testing.md) |
| `get_test_artifacts_for_sub_project` | `./gradlew <module>:tasks` | [testing.md](references/testing.md) |
| `get_artifact_consumers` | `./gradlew :module:dependencyInsight --dependency <artifact>` | [version-lookup.md](references/version-lookup.md) |
| `analyze_current_file` | `./gradlew lint` | [static-analysis.md](references/static-analysis.md) |
| `version_lookup` | `./gradlew dependencyUpdates` | [version-lookup.md](references/version-lookup.md) |
| `code_search` | `git grep -n <pattern> -- '*.kt' '*.java'` | [code-search.md](references/code-search.md) |
| `find_files` | `find . -name <name> -not -path "*/build/*"` | [code-search.md](references/code-search.md) |
| `find_usages` | `git grep -n -w <symbol> -- '*.kt' '*.java'` | [code-search.md](references/code-search.md) |
| `fetch_android_docs` / `search_android_docs` | Context7 MCP or web search | — |
| `render_compose_preview` | No CLI equivalent — use emulator + `screencap` | [adb-device.md](references/adb-device.md) |
| `gradle_sync` | No full equivalent — `./gradlew :module:sourceSets` + `:module:dependencies` for partial data | [gradle-project.md](references/gradle-project.md) |
| — | `perfetto` / `am dumpheap` / `hprof-conv` | [profiling.md](references/profiling.md) |
| — | `aapt2 dump` / `bundletool get-size-total` | [app-size.md](references/app-size.md) |
| — | `adb pair` / `adb connect` (wireless ADB) | [adb-device.md](references/adb-device.md) |
| — | `cmd uimode night` / locale / font scale | [adb-device.md](references/adb-device.md) |
| — | TalkBack / color correction toggle | [adb-device.md](references/adb-device.md) |
| — | Test sharding (`numShards` / `shardIndex`) | [testing.md](references/testing.md) |

## Workflow

When asked to perform an Android development task without Android Studio:

1. **Identify the Studio tool being replaced** — use the mapping table above.
2. **Check the environment first** — run the prerequisite checks in the section below. If any check fails, **stop and report the specific missing tool to the user** with the fix. Do not attempt the requested command until prerequisites are met.
3. **Use the minimal command** — prefer direct `adb` or `./gradlew` invocations; only wrap in scripts when reuse is needed.
4. **Read reference for complex operations** — load the relevant file from `references/` when deeper guidance is needed.
5. **Surface errors correctly** — Gradle errors go to stdout; adb connection errors go to stderr. Parse accordingly.
6. **Never hardcode SDK path** — rely on `local.properties` (`sdk.dir`) or `$ANDROID_HOME`.

## Environment Prerequisites

Run these checks before any command. On failure, stop and tell the user exactly what is missing and how to fix it.

| Check | Command | Failure → tell the user |
|---|---|---|
| Android SDK Platform Tools | `adb version` | Install Platform Tools; set `ANDROID_HOME` and add `$ANDROID_HOME/platform-tools` to `PATH` |
| JDK 17+ | `java --version` | Install JDK 17+; AGP 8+ requires it — older JDKs produce `Unsupported class file major version` |
| Gradle wrapper | `./gradlew --version` | Not in an Android project root, or wrapper not committed — run from the directory containing `gradlew` |

Android SDK path resolution order:
1. `local.properties` → `sdk.dir` (project-local, not committed)
2. `$ANDROID_HOME` environment variable
3. `$ANDROID_SDK_ROOT` (legacy)

```bash
# Set for current shell if not in local.properties
export ANDROID_HOME=$HOME/Library/Android/sdk           # macOS
export ANDROID_HOME=$HOME/Android/Sdk                  # Linux
export PATH=$ANDROID_HOME/platform-tools:$PATH
```

## Core Rules

- Always use `./gradlew` (wrapper), never system `gradle` — the wrapper uses the project's pinned version.
- Always target a specific device when multiple are connected: `adb -s <serial> <command>`.
- ADB commands require the device to be unlocked and USB debugging enabled.
- For CI/CD environments: set `ANDROID_HOME`, use `./gradlew`, and pass `--no-daemon` for clean runs.
- Lint reports go to `app/build/reports/lint-results-*.html` and `-*.xml`.
- ktlint/kotlinter reports go to `app/build/reports/ktlint/`.

## Do / Don't

### Do
- Use `./gradlew tasks` to discover available tasks before guessing task names
- Filter logcat by tag or package (`adb logcat -s MyTag` or `--pid`)
- Use `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` for UI state
- Prefer `adb exec-out` over `adb shell` for binary output (screenshots)
- Use `grep -w` for exact symbol search, `grep` without `-w` for substring
- Run `./gradlew lintKotlin` for formatting, `./gradlew lint` for Android lint

### Don't
- Hardcode `~/Library/Android/sdk` — use `local.properties` or `$ANDROID_HOME`
- Use `adb shell screencap` and redirect via shell — binary is corrupted; use `exec-out`
- Run `./gradlew` without the wrapper (`gradlew`) — version mismatch causes subtle failures
- Parse `uiautomator dump` output as XML directly from stdout — always pull the file first
- Use `system gradle` — always `./gradlew`
- Forget `-s <serial>` when multiple devices/emulators are connected

## Quick Routing

- **Tap/swipe/key input on device** → [adb-device.md](references/adb-device.md) § Input Commands
- **Screenshot or screen recording** → [adb-device.md](references/adb-device.md) § Screen Capture
- **UI hierarchy / accessibility tree** → [adb-device.md](references/adb-device.md) § UI Hierarchy
- **Logcat filtering, crash logs, ANRs** → [adb-logging.md](references/adb-logging.md)
- **Build APK, AAB, or specific variant** → [gradle-build.md](references/gradle-build.md)
- **List tasks, build types, flavors** → [gradle-build.md](references/gradle-build.md) § Task Discovery
- **List subprojects or find build.gradle** → [gradle-project.md](references/gradle-project.md)
- **Source sets, dependencies, artifact graph** → [gradle-project.md](references/gradle-project.md)
- **Android lint warnings/errors** → [static-analysis.md](references/static-analysis.md) § Android Lint
- **Kotlin formatting (ktlint/kotlinter)** → [static-analysis.md](references/static-analysis.md) § Kotlinter
- **Run unit tests** → [testing.md](references/testing.md) § Unit Tests
- **Run instrumented/espresso tests** → [testing.md](references/testing.md) § Instrumented Tests
- **Install APK on device** → [deploy.md](references/deploy.md)
- **Check latest dependency versions** → [version-lookup.md](references/version-lookup.md)
- **Dependency tree / who uses artifact X** → [version-lookup.md](references/version-lookup.md) § Dependency Tree
- **Search code by symbol or pattern** → [code-search.md](references/code-search.md)
- **Find file by name or partial path** → [code-search.md](references/code-search.md) § Finding Files
- **Wireless ADB / Wi-Fi debugging** → [adb-device.md](references/adb-device.md) § Wireless ADB
- **Dark mode / locale / font scale / display** → [adb-device.md](references/adb-device.md) § Device Settings
- **TalkBack / color correction testing** → [adb-device.md](references/adb-device.md) § Accessibility Testing
- **Accessibility audit (Compose / ATF)** → [testing.md](references/testing.md) § Accessibility Tests
- **Smoke-test accessibility on device (View-based)** → [adb-device.md](references/adb-device.md) § Accessibility Testing
- **Perfetto traces, heap dumps, startup time** → [profiling.md](references/profiling.md)
- **APK size, aapt2, bundletool size analysis** → [app-size.md](references/app-size.md)
- **Test sharding for CI** → [testing.md](references/testing.md) § Test Sharding
