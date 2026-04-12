#!/usr/bin/env bash
# version-lookup.sh — show resolved dependency versions for a module (version_lookup equivalent).
#
# Usage:
#   ./skill-scripts/version-lookup.sh [module]
#
# Defaults: module=:sample.
# Shows the resolved runtime dependency tree so you can compare versions.
#
# Note: For available-update checking, add the Ben Manes plugin
#   (id("com.github.ben-manes.versions") version "0.51.0") and run
#   ./gradlew dependencyUpdates.
#
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-:sample}"

./gradlew "${MODULE}:dependencies" --configuration debugRuntimeClasspath 2>&1 | head -80
