#!/usr/bin/env bash
# build-file.sh — locate the build file for a module (get_build_file_location equivalent).
#
# Usage:
#   ./skill-scripts/build-file.sh [module]
#
# Defaults: module=:sample.
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"

./gradlew "${MODULE}:buildEnvironment" 2>&1 | head -20
echo ""
echo "Build file:"
MODULE_DIR="${MODULE#:}"
find . -path "*/${MODULE_DIR}/build.gradle*" -not -path "*/build/*" | head -5
