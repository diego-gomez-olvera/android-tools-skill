#!/usr/bin/env bash
# simpleperf.sh — record a CPU profile and generate a flamegraph (NDK Simpleperf).
#
# Usage:
#   ./skill-scripts/simpleperf.sh <package> [duration_s]
#
# Defaults: duration=10s.
# Output: flamegraph.html (open in any browser).
#
# Requires: python3, Android NDK installed under $ANDROID_HOME/ndk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/ensure-python3.sh
source "$SCRIPT_DIR/internal/ensure-python3.sh"

PACKAGE="${1:?Usage: $0 <package> [duration_s]}"
DURATION="${2:-10}"

SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
NDK_DIR=$(ls -d "$SDK/ndk/"*/ 2>/dev/null | sort -rV | head -1)
if [[ -z "$NDK_DIR" ]]; then
    echo "Error: Android NDK not found under $SDK/ndk" >&2
    echo "       Install it via Android Studio → SDK Manager → NDK." >&2
    exit 1
fi

APP_PROFILER="$NDK_DIR/simpleperf/app_profiler.py"
REPORT_HTML="$NDK_DIR/simpleperf/report_html.py"

echo "Recording ${DURATION}s CPU profile for $PACKAGE..."
python3 "$APP_PROFILER" -p "$PACKAGE" -r "--duration $DURATION" -o perf.data

echo "Generating flamegraph..."
python3 "$REPORT_HTML" -i perf.data -o flamegraph.html

echo "Flamegraph ready: flamegraph.html"
