#!/usr/bin/env bash
# deploy.sh — build and install the debug APK on a connected device or emulator.
#
# Usage:
#   ./skill-scripts/deploy.sh [module]
#
# Defaults: module=:sample.
# Requires: adb in PATH, a connected device or running emulator, ./gradlew.

set -euo pipefail

MODULE="${1:-:sample}"

./gradlew "${MODULE}:installDebug"
echo "Installed ${MODULE} debug APK."
