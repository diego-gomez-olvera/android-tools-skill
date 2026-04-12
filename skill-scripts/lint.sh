#!/usr/bin/env bash
# lint.sh — run Android lint on a module (analyze_current_file equivalent).
#
# Usage:
#   ./skill-scripts/lint.sh [module]
#
# Defaults: module=:sample.
# Report: <module>/build/reports/lint-results-debug.html
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"

./gradlew "${MODULE}:lintDebug"
MODULE_DIR="${MODULE/:/}"
echo "Report: ${MODULE_DIR}/build/reports/lint-results-debug.html"
