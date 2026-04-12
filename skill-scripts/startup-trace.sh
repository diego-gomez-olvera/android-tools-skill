#!/usr/bin/env bash
# startup-trace.sh — cold-start an app, measure startup time, and capture a
# Perfetto trace covering the full launch sequence.
#
# Usage:
#   ./skill-scripts/startup-trace.sh <package/activity>
#
# Example:
#   ./skill-scripts/startup-trace.sh com.example.helloworld/.MainActivity
#
# Output: saved to a temp directory, opened automatically in ui.perfetto.dev.
# Requires: adb in PATH, python3, a connected device or running emulator (API 28+).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMPONENT="${1:?Usage: $0 <package/activity>}"
PACKAGE="${COMPONENT%%/*}"
REMOTE=/data/misc/perfetto-traces/startup.perfetto-trace
TMPDIR_TRACE=$(mktemp -d)
OUTPUT="$TMPDIR_TRACE/startup.perfetto-trace"

echo "Force-stopping $PACKAGE..."
adb shell am force-stop "$PACKAGE"

echo "Starting 10s Perfetto trace..."
adb shell perfetto \
  -o "$REMOTE" \
  -t 10s \
  sched freq idle am wm gfx view binder_driver hal dalvik camera input res memory &
PERFETTO_PID=$!

sleep 1

echo "Cold-launching $COMPONENT..."
adb shell am start -W -n "$COMPONENT" | grep -E "Status|TotalTime|WaitTime"

wait $PERFETTO_PID

adb pull "$REMOTE" "$OUTPUT"
adb shell rm -f "$REMOTE"

echo "Startup trace saved: $OUTPUT"
"$SCRIPT_DIR/open-trace.sh" "$OUTPUT"
