# Android Tools — CLI Equivalents for Android Studio Tools

When asked to perform Android development tasks, use the CLI equivalents below instead of Android Studio's built-in tools. Always use `./gradlew` (wrapper), never system `gradle`.

## Tool Mapping

| Android Studio Tool | CLI Equivalent |
|---|---|
| `adb_shell_input` | `adb shell input <type> <args>` |
| `take_screenshot` | `adb exec-out screencap -p > shot.png` |
| `ui_state` | `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` |
| `deploy` | `./gradlew :module:installDebug` |
| `read_logcat` | `adb logcat -d --pid=$(adb shell pidof <package>)` |
| `gradle_build` | `./gradlew :module:assembleDebug` |
| `get_assemble_task_for_artifact` | `./gradlew :module:tasks --group=build` |
| `get_test_task_for_artifact` | `./gradlew :module:tasks --group=verification` |
| `get_test_artifacts_for_sub_project` | `./gradlew :module:tasks` |
| `get_top_level_sub_projects` | `./gradlew projects` |
| `get_build_file_location` | `find . -path "*/<module>/build.gradle*" -not -path "*/build/*"` |
| `get_source_folders_for_artifact` | `find . -path "*/<module>/src/*" -type d -not -path "*/build/*"` |
| `get_artifact_consumers` | `./gradlew :module:dependencyInsight --dependency <artifact>` |
| `analyze_current_file` | `./gradlew :module:lintDebug` |
| `version_lookup` | `./gradlew :module:dependencies --configuration debugRuntimeClasspath` |
| `code_search` | `git grep -n <pattern> -- '*.kt' '*.java'` |
| `find_files` | `find . -name <name> -not -path "*/build/*"` |
| `find_usages` | `git grep -n -w <symbol> -- '*.kt' '*.java'` |

## Scripts

Ready-to-run scripts are in `skill-scripts/`. Prefer them over inline commands:

```
skill-scripts/build.sh            # gradle_build
skill-scripts/deploy.sh           # deploy
skill-scripts/lint.sh             # analyze_current_file
skill-scripts/unit-test.sh        # get_test_task_for_artifact
skill-scripts/screenshot.sh       # take_screenshot
skill-scripts/read-logcat.sh      # read_logcat
skill-scripts/dump-ui.sh          # ui_state
skill-scripts/adb-input.sh        # adb_shell_input
skill-scripts/code-search.sh      # code_search
skill-scripts/find-files.sh       # find_files
skill-scripts/find-usages.sh      # find_usages
skill-scripts/list-projects.sh    # get_top_level_sub_projects
skill-scripts/list-tasks.sh       # get_assemble_task_for_artifact / get_test_task_for_artifact
skill-scripts/build-file.sh       # get_build_file_location
skill-scripts/source-folders.sh   # get_source_folders_for_artifact
skill-scripts/dependency-insight.sh  # get_artifact_consumers
skill-scripts/version-lookup.sh   # version_lookup
skill-scripts/apk-size.sh         # app-size analysis
skill-scripts/startup-time.sh     # cold-start profiling
skill-scripts/check-accessibility.sh  # accessibility audit
```

## Core Rules

- Always use `./gradlew`, never system `gradle`
- Use `adb exec-out` for screenshots (not `adb shell` — binary is corrupted)
- Prefer `git grep` over `grep -r` — respects `.gitignore`, no `--exclude-dir=build` needed
- When multiple devices are connected, target with `adb -s <serial>`
- Lint reports: `<module>/build/reports/lint-results-debug.html`
- For AAB size analysis, install `bundletool` first: `./skill-scripts/install-bundletool.sh`
