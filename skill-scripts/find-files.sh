#!/usr/bin/env bash
# find-files.sh — find files by name pattern, excluding build directories (find_files equivalent).
#
# Usage:
#   ./skill-scripts/find-files.sh <name_pattern> [path]
#
# path defaults to . (project root).
#
# Examples:
#   ./skill-scripts/find-files.sh "*.kt"
#   ./skill-scripts/find-files.sh "MainActivity.kt"

set -euo pipefail

PATTERN="${1:?Usage: $0 <name_pattern> [path]}"
SEARCH_PATH="${2:-.}"

find "$SEARCH_PATH" -name "$PATTERN" -not -path "*/build/*" -not -path "*/.gradle/*"
