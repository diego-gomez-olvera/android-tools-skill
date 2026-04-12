<!--suppress HtmlDeprecatedAttribute -->
<div align="center">
  <h1>android-tools-skill</h1>

  <strong>Android Studio tools — available everywhere.</strong><br>
  A comprehensive agent skill mapping Android Studio's built-in AI tools to CLI equivalents.

  <br><br>

  <a href="#installation"><img src="https://img.shields.io/badge/setup-2_min-brightgreen?style=flat-square" alt="setup 2 min" /></a>
  <a href="https://developer.android.com/tools/adb"><img src="https://img.shields.io/badge/ADB-Platform_Tools-3DDC84?style=flat-square&logo=android&logoColor=white" alt="ADB" /></a>
  <a href="https://docs.gradle.org/"><img src="https://img.shields.io/badge/Gradle-8+-02303A?style=flat-square&logo=gradle&logoColor=white" alt="Gradle 8+" /></a>
  <a href="https://agentskills.io/"><img src="https://img.shields.io/badge/Agent_Skills-standard-8B5CF6?style=flat-square" alt="Agent Skills standard" /></a>
</div>

---

## What This Skill Does

This is an **AI agent skill** — not a library. Install it once, and your AI coding agent (Claude Code, Gemini CLI, Gemini for Android Studio, Codex, GitHub Copilot) gains full knowledge of the Android development toolchain outside Android Studio: ADB, Gradle CLI, static analysis, testing, deployment, project introspection, dependency management, and code search.

Every capability maps 1-to-1 to an Android Studio built-in AI tool and has a verified CLI equivalent.

## Tool Mapping

| Android Studio Tool | CLI Equivalent |
|---|---|
| `adb_shell_input` | `adb shell input <type> <args>` |
| `take_screenshot` | `adb exec-out screencap -p > shot.png` |
| `ui_state` | `adb shell uiautomator dump` |
| `deploy` | `./gradlew installDebug` |
| `read_logcat` | `adb logcat [--pid=<pid>]` |
| `gradle_build` | `./gradlew <task>` |
| `get_assemble_task_for_artifact` | `./gradlew tasks --group=build` |
| `get_top_level_sub_projects` | `./gradlew projects` |
| `get_build_file_location` | `./gradlew <module>:buildEnvironment` |
| `get_source_folders_for_artifact` | `./gradlew :module:sourceSets` |
| `get_test_task_for_artifact` | `./gradlew tasks --group=verification` |
| `get_artifact_consumers` | `./gradlew :module:dependencyInsight` |
| `analyze_current_file` | `./gradlew lint` / `./gradlew lintKotlin` |
| `version_lookup` | `./gradlew dependencyUpdates` |
| `code_search` | `git grep -n <pattern> -- '*.kt' '*.java'` |
| `find_files` | `find . -name <name> -not -path "*/build/*"` |
| `get_test_artifacts_for_sub_project` | `./gradlew :module:tasks` |
| `find_usages` | `git grep -n -w <symbol> -- '*.kt' '*.java'` |

## What's Covered

| Reference | Topic |
|---|---|
| [adb-device.md](references/adb-device.md) | Tap/swipe, screenshots, UI hierarchy, app management |
| [adb-logging.md](references/adb-logging.md) | Logcat filtering, crash analysis, performance logs |
| [gradle-build.md](references/gradle-build.md) | APK/AAB assembly, build variants, task discovery |
| [gradle-project.md](references/gradle-project.md) | Project structure, source sets, dependencies |
| [static-analysis.md](references/static-analysis.md) | Android lint, ktlint/kotlinter, detekt |
| [testing.md](references/testing.md) | Unit tests, instrumented tests, emulator setup |
| [deploy.md](references/deploy.md) | Install, launch, grant permissions, bundletool |
| [version-lookup.md](references/version-lookup.md) | Latest versions, dependency tree, conflict resolution |
| [code-search.md](references/code-search.md) | ripgrep, fd, symbol search, find usages |
| [profiling.md](references/profiling.md) | Perfetto traces, heap dumps, startup time, GPU rendering |
| [app-size.md](references/app-size.md) | aapt2, bundletool size analysis, DEX method count |

## Android Studio–Only Tools (No CLI Equivalent)

These tools from Android Studio's AI plugin have **no meaningful CLI replacement**. They depend on the IDE's internal model, rendering pipeline, or inspection engine and cannot be replicated outside Android Studio.

| Tool | Why it requires Android Studio | Best available workaround |
|---|---|---|
| `render_compose_preview` | Runs Layoutlib — the same rendering engine as Android itself — inside the IDE process to produce pixel-accurate previews of `@Preview` composables. | Launch the app on an emulator and `adb exec-out screencap -p`. For regression testing, use [Paparazzi](https://github.com/cashapp/paparazzi) (JVM screenshot tests, no emulator). |
| `analyze_current_file` *(full)* | Runs all registered IDE inspections: type inference, control flow analysis, data flow, unused symbol detection, Kotlin-specific checks, and hundreds of language-level rules — far beyond what lint covers. | `./gradlew lint` + `./gradlew lintKotlin` cover a subset. Full IDE-level analysis requires Android Studio or IntelliJ with the Kotlin plugin. |
| `resolve_symbol` *(semantic)* | Resolves a reference to its declaration using the IDE's full type system — handles Kotlin's type inference, smart casts, extension functions, operator overloading, and `expect/actual`. | `grep -rn -w <symbol>` finds textual matches. `kotlin-language-server` (LSP) approaches IDE-level accuracy but requires separate installation and setup. |
| `gradle_sync` *(full model)* | Builds Android Studio's in-memory Gradle model: all variants, build types, flavors, generated sources, merged manifests, and resource sets. Used to power all "get_*" project tools. | `./gradlew tasks --all` exposes task names. `./gradlew :module:sourceSets` and `./gradlew :module:dependencies` expose partial model data. No single command replicates the full model. |
| `fetch_android_docs` / `search_android_docs` | Queries Android Studio's curated, offline-indexed documentation database with IDE-aware context (e.g., knowing which API you're hovering over). | Web search on [developer.android.com](https://developer.android.com), or [Context7 MCP](https://context7.com) for AI-integrated doc access. |

### `analyze_current_file` coverage gap

The table below shows what `./gradlew lint` + `./gradlew lintKotlin` cover versus what only the IDE provides:

| Check type | `./gradlew lint` | `./gradlew lintKotlin` | IDE only |
|---|---|---|---|
| Android resource issues | ✅ | — | — |
| Kotlin formatting | — | ✅ | — |
| Compose rule violations | — | ✅ (with plugin) | — |
| Unused imports | — | ✅ | — |
| Type errors / unresolved refs | — | — | ✅ |
| Smart cast / null safety warnings | — | — | ✅ |
| Control / data flow analysis | — | — | ✅ |
| Unused symbols (IDE-level) | partial | — | ✅ |
| Kotlin compiler warnings | partial | partial | ✅ (full) |

<a id="installation"></a>
## Installation

**One-liner** — run from your Android project root. Auto-detects which agents you have configured and installs for all of them:

```bash
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash
```

**Options:**

```bash
# Gemini for Android Studio
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=android-studio

# Gemini CLI
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=gemini

# Claude Code
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=claude

# Codex
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=codex

# GitHub Copilot
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=copilot

# Multiple agents at once
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --agent=android-studio,gemini

# Install user-wide instead of per-repo
curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash -s -- --global
```

## Usage

Invoke by mentioning `@android-tools-skill` anywhere in your message. Using `@` (not `/`) avoids colliding with Android Studio's built-in `/tools` slash command.

**GitHub Copilot** — no `@mention` needed. The instructions in `.github/copilot-instructions.md` are injected automatically into every Copilot Chat session for the repo.

```text
@android-tools-skill How do I take a screenshot of the current device screen?
@android-tools-skill Filter logcat to only show my app's logs.
@android-tools-skill Build a release APK from the command line.
@android-tools-skill Find all usages of ReceiptParser in the project.
@android-tools-skill Run only the unit tests for the :app module.
@android-tools-skill Sign this APK for release and verify the signature.
@android-tools-skill Capture a Perfetto trace during app startup.
@android-tools-skill What's making this APK so large?
@android-tools-skill Connect to my device over Wi-Fi without USB.
@android-tools-skill Test this screen with TalkBack and dark mode enabled.
@android-tools-skill Shard my instrumented tests across 4 CI runners.
```

## Prerequisites

```bash
adb version               # Android SDK Platform Tools
java --version            # JDK 17+
./gradlew --version       # Gradle wrapper
```

No third-party tools required. All commands use Android SDK, JDK, Gradle wrapper, and standard POSIX utilities (`grep`, `find`, `sed`, `awk`).

## Skill Structure

```text
android-tools-skill/
├── SKILL.md                    # Skill definition — agent reads this (required)
├── AGENTS.md                   # Tool-agnostic project instructions (source of truth)
├── CLAUDE.md                   # Claude Code — points to AGENTS.md
├── GEMINI.md                   # Gemini CLI — points to AGENTS.md
├── install.sh                  # Installer: auto-detects agents, clones into right path
├── .github/
│   └── copilot-instructions.md # GitHub Copilot — injected automatically by Copilot Chat
├── agents/
│   └── openai.yaml             # Codex UI metadata (required)
├── references/                 # Deep-dive reference files (required)
│   ├── adb-device.md
│   ├── adb-logging.md
│   ├── gradle-build.md
│   ├── gradle-project.md
│   ├── static-analysis.md
│   ├── testing.md
│   ├── deploy.md
│   ├── version-lookup.md
│   ├── code-search.md
│   ├── profiling.md
│   └── app-size.md
├── README.md                   # This file (not read by agents)
├── scripts/
│   ├── validate.sh             # Skill structure validator (meta-script)
│   └── sync-agents.sh          # Verifies agent files stay in sync with skill-scripts/
└── skill-scripts/              # CLI scripts for each SKILL command
    ├── build.sh, deploy.sh, lint.sh, unit-test.sh
    ├── screenshot.sh, read-logcat.sh, dump-ui.sh, adb-input.sh
    ├── list-projects.sh, list-tasks.sh, build-file.sh, source-folders.sh
    ├── code-search.sh, find-files.sh, find-usages.sh
    ├── dependency-insight.sh, version-lookup.sh
    ├── apk-size.sh, install-bundletool.sh
    ├── startup-time.sh, startup-trace.sh, gpu-rendering.sh
    ├── perfetto.sh, heap-dump.sh, meminfo.sh
    ├── systrace.sh, simpleperf.sh
    ├── check-accessibility.sh, start-emulator.sh
    └── internal/               # helper scripts (not user-facing)
        ├── ensure-python3.sh, open-trace.sh, serve-trace.py
        └── parse-ui-dump.py, check-accessibility.py
```

## License

MIT
