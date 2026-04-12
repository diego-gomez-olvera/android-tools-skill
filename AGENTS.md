# android-tools-skill

An AI agent skill that maps Android Studio's built-in AI tools to CLI equivalents (ADB, Gradle, lint, tests, deploy, profiling, signing, app-size analysis). Not a library — installed once so AI coding agents gain Android toolchain knowledge.

## Project Structure

```
SKILL.md              # Agent-facing skill definition (required, ≤500 lines)
AGENTS.md             # Tool-agnostic project instructions (this file)
CLAUDE.md             # Claude Code — points to AGENTS.md
GEMINI.md             # Gemini CLI — points to AGENTS.md
install.sh            # Installer: auto-detects agents and clones into the right path
agents/openai.yaml    # Codex UI metadata (display_name + default_prompt required)
references/           # Deep-dive reference files (≤500 lines each)
scripts/validate.sh   # Validates structure and internal links (meta-script)
skill-scripts/        # CLI scripts for each SKILL command (adb, gradle, lint, …)
settings.gradle.kts   # Root Gradle settings — includes :sample module
build.gradle.kts      # Root build file (plugin declarations)
gradle.properties     # Gradle JVM + Android flags
gradle/               # Wrapper + version catalog (libs.versions.toml)
gradlew / gradlew.bat # Gradle wrapper scripts
sample/               # Hello World Android app (:sample module) for manual testing
```

## Agent Support

| Agent | Entry point | Install path |
|---|---|---|
| Claude Code | `CLAUDE.md` → `AGENTS.md` | `.claude/skills/android-tools-skill` |
| Gemini CLI | `GEMINI.md` | `.gemini/skills/android-tools-skill` |
| Gemini for Android Studio | `SKILL.md` (auto-loaded from `.skills/`) | `.skills/android-tools-skill` |
| Codex | `agents/openai.yaml` | `.codex/skills/android-tools-skill` |

## Reference Files

| File | Topic |
|---|---|
| `adb-device.md` | Tap/swipe, screenshots, UI hierarchy, wireless ADB, accessibility |
| `adb-logging.md` | Logcat filtering, crash analysis, ANRs |
| `gradle-build.md` | APK/AAB assembly, build variants, task discovery |
| `gradle-project.md` | Project structure, source sets, dependencies |
| `static-analysis.md` | Android lint, ktlint/kotlinter, detekt |
| `testing.md` | Unit tests, instrumented tests, sharding |
| `deploy.md` | Install, launch, grant permissions, bundletool |
| `version-lookup.md` | Latest versions, dependency tree, conflict resolution |
| `code-search.md` | ripgrep, fd, symbol search, find usages |
| `profiling.md` | Perfetto traces, heap dumps, startup time |
| `app-size.md` | aapt2, bundletool size analysis, DEX method count |

## Validation

```bash
./scripts/validate.sh
```

Checks: required files present, SKILL.md front-matter, line counts (≤500), internal link integrity, all references linked from SKILL.md, `agents/openai.yaml` fields.

## Key Conventions

- **SKILL.md** is the agent-facing entry point — keep it ≤500 lines; link all reference files from it.
- **Reference files** are loaded on demand — each should be self-contained and ≤500 lines.
- `SKILL.md` front-matter requires `name:`, `description:`, and explicit activation instructions (only trigger on direct user request, not keyword matching).
- `agents/openai.yaml` requires `display_name` and `default_prompt`.
- `README.md` is for humans — agents do not read it.
- The `sample/` app is the `:sample` Gradle module (root project at repo root). It is a minimal Hello World used for manual testing only; do not add features to it.
- Open the repo root in Android Studio to see the `:sample` module as a runnable Android app.
- From CLI: `./gradlew :sample:assembleDebug` or `./gradlew :sample:installDebug`.

## Adding a New Reference Topic

1. Create `references/<topic>.md` (≤500 lines).
2. Add a row to the Tool Mapping table in `SKILL.md`.
3. Add a Quick Routing entry in `SKILL.md`.
4. Run `./scripts/validate.sh` — must pass with 0 errors.
