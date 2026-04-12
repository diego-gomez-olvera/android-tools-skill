#!/usr/bin/env bash
# perfetto.sh — capture a Perfetto trace from a connected device (API 28+).
#
# Usage:
#   ./skill-scripts/perfetto.sh [duration_s]
#
# Defaults: duration=10s. Trace is saved to a temp directory and opened
# automatically in ui.perfetto.dev.
#
# Requires: adb in PATH, python3, a connected device or running emulator (API 28+).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DURATION="${1:-10}"
REMOTE=/data/misc/perfetto-traces/trace.perfetto-trace
TMPDIR_TRACE=$(mktemp -d)
OUTPUT="$TMPDIR_TRACE/trace.perfetto-trace"

echo "Recording ${DURATION}s Perfetto trace..."
adb shell perfetto \
  -o "$REMOTE" \
  -t "${DURATION}s" \
  sched freq idle am wm gfx view binder_driver hal dalvik camera input res memory

echo "Pulling trace..."
adb pull "$REMOTE" "$OUTPUT"
adb shell rm -f "$REMOTE"

echo "Trace saved: $OUTPUT"
"$SCRIPT_DIR/internal/open-trace.sh" "$OUTPUT"
