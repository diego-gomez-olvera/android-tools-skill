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

> ⚠️ **DEPRECATED:** Google has officially released the [Android CLI for Agents](https://developer.android.com/tools/agents). I highly recommend using the official tools, as they provide deeper integration (pixel-accurate previews, semantic symbol resolution, etc.) and first-party support. This repository remains available as an educational resource and as a reference for low-level ADB/Gradle automation.

---

## What This Skill Does

This is an **AI agent skill** — not a library. Install it once, and your AI coding agent (Claude Code, Gemini CLI, Gemini for Android Studio, Codex, GitHub Copilot) gains full knowledge of the Android development toolchain outside Android Studio: ADB, Gradle CLI, static analysis, testing, deployment, project introspection, dependency management, and code search.

Every capability maps 1-to-1 to an Android Studio built-in AI tool and has a verified CLI equivalent.

## Tool Mapping

| Tool | Barebones CLI Equivalent | Official Android CLI |
|---|---|---|
| `adb_shell_input` | `adb shell input <type> <args>` | Native (ADB wrapper) |
| `take_screenshot` | `adb exec-out screencap -p > shot.png` | Native (Returns image payload) |
| `ui_state` | `adb shell uiautomator dump` | Native (XML + visual bounds) |
| `deploy` | `./gradlew installDebug` | Native (Builds + installs app) |
| `read_logcat` | `adb logcat [--pid=<pid>]` | Native (Filtered by app PID) |
| `gradle_build` | `./gradlew <task>` | Native (Gradle Tooling API) |
| `get_assemble_task_for_artifact` | `./gradlew tasks --group=build` | Native (In-memory Project Model) |
| `get_top_level_sub_projects` | `./gradlew projects` | Native (In-memory Project Model) |
| `get_build_file_location` | `./gradlew <module>:buildEnvironment` | Native (In-memory Project Model) |
| `get_source_folders_for_artifact` | `./gradlew :module:sourceSets` | Native (In-memory Project Model) |
| `get_test_task_for_artifact` | `./gradlew tasks --group=verification` | Native (In-memory Project Model) |
| `get_artifact_consumers` | `./gradlew :module:dependencyInsight` | Native (In-memory Project Model) |
| `analyze_current_file` | `./gradlew lint` / `./gradlew lintKotlin` | Headless IDE Inspection Engine |
| `version_lookup` | `./gradlew dependencyUpdates` | Native Maven/Google index lookup |
| `code_search` | `git grep -n <pattern> -- '*.kt' '*.java'` | Lucene-based semantic index |
| `find_files` | `find . -name <name> -not -path "*/build/*"` | IDE-based fast file search |
| `get_test_artifacts_for_sub_project` | `./gradlew :module:tasks` | Native (In-memory Project Model) |
| `find_usages` | `git grep -n -w <symbol> -- '*.kt' '*.java'` | Full PSI/AST Reference Search |
| `render_compose_preview` | Launch app + screencap | Headless Layoutlib Engine |
| `resolve_symbol` | `grep` or LSP | Kotlin Compiler / PSI Resolution |
| `fetch_android_docs` | Web search | Direct Knowledge Base query |

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

## Advanced IDE Tools: Barebones CLI vs. Official Android CLI vs. Android Studio

Historically, several tools from Android Studio's AI plugin had **no meaningful barebones CLI replacement** because they depended on the IDE's internal PSI model, rendering pipeline, or inspection engine. 

With the launch of the **Official Android CLI for Agents**, these capabilities are now exposed headlessly to AI agents. However, the full Android Studio GUI still holds the edge for interactive, visual, and real-time developer workflows.

* **GUI Interactivity:** The IDE provides interactive previews, bounding-box selection, and visual click-to-navigate flows.
* **Real-time Feedback:** The IDE warns you  *while you type* and offers visual quick-fix menus.
* **Contextual Tooltips:** The IDE provides instant, context-aware hover documentation perfectly anchored to your screen layout.
* **Automation Efficiency (CLI Edge):** The Official Android CLI is infinitely more efficient for scripting, automating CI pipelines, and letting multi-step AI agents rapidly parse through large chunks of semantic data without having to drive a heavy UI process.

| Tool | Why it historically required Android Studio | Best Barebones CLI Workaround | Official Android CLI |
|---|---|---|---|
| `render_compose_preview` | Runs Layoutlib (Android's rendering engine) for pixel-accurate previews without an emulator. | Launch on emulator + `adb exec-out screencap`. | Native headless Layoutlib rendering |
| `analyze_current_file` | Runs hundreds of IDE inspections (type inference, control flow, nullability) beyond simple linting. | `./gradlew lint` + `lintKotlin` | Runs full headless IDE inspection engine |
| `resolve_symbol` | Requires the IDE's full type system to handle inference, smart casts, operator overloading. | `grep -rn -w <symbol>` or LSP setup. | Full semantic resolution via Kotlin compiler |
| `gradle_sync` | Builds the in-memory Gradle model (variants, generated sources, merged manifests). | `./gradlew tasks --all` & partial `sourceSets`. | Exposes the synchronized project model |
| `fetch_android_docs` | Queries Android Studio's curated, offline-indexed knowledge base. | Web search on developer.android.com. | Direct API access to Knowledge Base |

### `analyze_current_file` coverage gap

The table below illustrates how the new Official Android CLI bridges the gap between basic scripts and the full IDE:

| Check type | Barebones CLI (`./gradlew lint`) | Barebones CLI (`lintKotlin`) | Official Android CLI | Android Studio |
|---|---|---|---|---|
| Android resource issues | Supported | — | Supported | Supported |
| Kotlin formatting | — | Supported | Supported | Supported |
| Compose rule violations | — | Supported (with plugin) | Supported | Supported |
| Unused imports | — | Supported | Supported | Supported |
| Type errors / unresolved refs | — | — | Supported (Headless) | Supported (Real-time) |
| Smart cast / null safety warnings | — | — | Supported (Headless) | Supported (Real-time) |
| Control / data flow analysis | — | — | Supported (Headless) | Supported (Real-time) |
| Unused symbols (IDE-level) | Partial | — | Current-file scope* | Full project scope |
| Kotlin compiler warnings | Partial | Partial | Full | Full |

*\*Note on Unused Symbols: While the Official Android CLI runs the headless IDE inspection engine, detecting if a public symbol is entirely unused across a massive project requires building and querying a full global code index. Headless agents typically perform this validation at the local file scope, whereas Android Studio maintains this global index constantly in the background.*

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