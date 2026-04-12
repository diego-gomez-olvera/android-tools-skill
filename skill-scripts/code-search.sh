#!/usr/bin/env bash
# code-search.sh — search Kotlin/Java source for a pattern or symbol.
#
# Usage:
#   ./skill-scripts/code-search.sh <pattern> [path]
#
# path defaults to . (project root). Build directories are excluded.
# Prefers git grep (respects .gitignore, no --exclude-dir needed); falls back
# to grep outside a git repo.

set -euo pipefail

PATTERN="${1:?Usage: $0 <pattern> [path]}"
SEARCH_PATH="${2:-.}"

if git rev-parse --is-inside-work-tree &>/dev/null; then
    git grep -n "$PATTERN" -- '*.kt' '*.java'
else
    grep -rn --include="*.kt" --include="*.java" \
      --exclude-dir=build "$PATTERN" "$SEARCH_PATH"
fi
