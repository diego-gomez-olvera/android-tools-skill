#!/usr/bin/env bash
# find-usages.sh — find all usages of a symbol in Kotlin/Java source (find_usages equivalent).
#
# Usage:
#   ./skill-scripts/find-usages.sh <symbol> [path]
#
# Uses -w for whole-word matching. Build directories are excluded.
# path defaults to . (project root). Prefers git grep (respects .gitignore);
# falls back to grep outside a git repo.
#
# Examples:
#   ./skill-scripts/find-usages.sh "MainActivity"
#   ./skill-scripts/find-usages.sh "setContent"

set -euo pipefail

SYMBOL="${1:?Usage: $0 <symbol> [path]}"
SEARCH_PATH="${2:-.}"

if git rev-parse --is-inside-work-tree &>/dev/null; then
    git grep -n -w "$SYMBOL" -- '*.kt' '*.java'
else
    grep -rn -w --include="*.kt" --include="*.java" \
      --exclude-dir=build "$SYMBOL" "$SEARCH_PATH"
fi
