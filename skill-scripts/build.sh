#!/usr/bin/env bash
# build.sh — assemble an APK for a module (gradle_build equivalent).
#
# Usage:
#   ./skill-scripts/build.sh [module] [variant]
#
# Defaults: module=:sample, variant=Debug.
# Output APK: <module>/build/outputs/apk/debug/*.apk
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"
VARIANT="${2:-Debug}"

./gradlew "${MODULE}:assemble${VARIANT}"
VARIANT_LOWER=$(echo "$VARIANT" | tr '[:upper:]' '[:lower:]')
MODULE_DIR="${MODULE#:}"
find . -path "*/${MODULE_DIR}/build/outputs/apk/${VARIANT_LOWER}/*.apk" \
  -not -path "*/androidTest/*" 2>/dev/null | head -1 | xargs -I{} du -sh {}
