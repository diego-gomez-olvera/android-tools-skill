#!/usr/bin/env bash
# unit-test.sh — run JVM unit tests for a module (no device required).
#
# Usage:
#   ./skill-scripts/unit-test.sh [module]
#
# Defaults: module=:sample.
# Reports: <module>/build/reports/tests/testDebugUnitTest/index.html
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"

./gradlew "${MODULE}:testDebugUnitTest"
MODULE_DIR="${MODULE/:/}"
echo "Report: ${MODULE_DIR}/build/reports/tests/testDebugUnitTest/index.html"
