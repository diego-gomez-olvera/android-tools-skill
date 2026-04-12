#!/usr/bin/env bash
# list-tasks.sh — list Gradle tasks for a module, optionally filtered by group.
#
# Covers: get_assemble_task_for_artifact, get_test_task_for_artifact,
#         get_test_artifacts_for_sub_project.
#
# Usage:
#   ./skill-scripts/list-tasks.sh [module] [group]
#
# Defaults: module=:sample, group=<all>.
# Common groups: build, verification, install.
#
# Examples:
#   ./skill-scripts/list-tasks.sh :sample build
#   ./skill-scripts/list-tasks.sh :sample verification
#
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"
GROUP="${2:-}"

if [[ -n "$GROUP" ]]; then
    ./gradlew "${MODULE}:tasks" --group="$GROUP"
else
    ./gradlew "${MODULE}:tasks"
fi
