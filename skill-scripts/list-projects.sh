#!/usr/bin/env bash
# list-projects.sh — list top-level sub-projects (get_top_level_sub_projects equivalent).
#
# Usage:
#   ./skill-scripts/list-projects.sh
#
# Requires: ./gradlew (run from project root).

set -euo pipefail

./gradlew projects 2>&1 | grep -E "^(Root project|[+\\\\]--- Project)" | uniq
