#!/usr/bin/env bash
# source-folders.sh — list source folders for a module (get_source_folders_for_artifact equivalent).
#
# Usage:
#   ./skill-scripts/source-folders.sh [module]
#
# Defaults: module=sample.
# Requires: ./gradlew (run from project root).

set -euo pipefail

MODULE="${1:-sample}"

find . -path "*/${MODULE}/src/*" -type d -not -path "*/build/*" | sort
