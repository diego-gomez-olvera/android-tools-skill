#!/usr/bin/env bash
# dependency-insight.sh — show why a dependency is on the classpath (get_artifact_consumers).
#
# Usage:
#   ./skill-scripts/dependency-insight.sh <module> <dependency>
#
# Example:
#   ./skill-scripts/dependency-insight.sh :sample androidx.compose.material3:material3
#
# Requires: ./gradlew in PATH (run from project root).

set -euo pipefail

MODULE="${1:?Usage: $0 <module> <dependency>}"
DEPENDENCY="${2:?Usage: $0 <module> <dependency>}"
CONFIGURATION="${3:-debugCompileClasspath}"

./gradlew "${MODULE}:dependencyInsight" --dependency "$DEPENDENCY" --configuration "$CONFIGURATION" 2>&1 | head -40
