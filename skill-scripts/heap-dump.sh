#!/usr/bin/env bash
# heap-dump.sh — capture and convert a heap dump for a running app (am dumpheap equivalent).
#
# Usage:
#   ./skill-scripts/heap-dump.sh <package>
#
# Output: heap.hprof (converted, ready for Android Studio / Eclipse MAT / VisualVM).
# Requires: adb in PATH, hprof-conv in PATH ($ANDROID_HOME/platform-tools),
#           a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:?Usage: $0 <package>}"
REMOTE=/data/local/tmp/heap-raw.hprof
OUTPUT=heap.hprof

# Resolve hprof-conv
HPROF_CONV=$(command -v hprof-conv 2>/dev/null \
  || find "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools" -name hprof-conv 2>/dev/null | head -1)
if [[ -z "$HPROF_CONV" ]]; then
    echo "Error: hprof-conv not found. Ensure \$ANDROID_HOME/platform-tools is in PATH." >&2
    exit 1
fi

PID=$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '[:space:]')
if [[ -z "$PID" ]]; then
    echo "Error: package '$PACKAGE' is not running on the device." >&2
    exit 1
fi

echo "Capturing heap dump for $PACKAGE (PID $PID)..."
adb shell am dumpheap "$PID" "$REMOTE"
sleep 1   # allow flush to complete

echo "Pulling..."
adb pull "$REMOTE" heap-raw.hprof
adb shell rm -f "$REMOTE"

echo "Converting (Android hprof → standard hprof)..."
"$HPROF_CONV" heap-raw.hprof "$OUTPUT"
rm heap-raw.hprof

echo "Heap dump ready: $OUTPUT"
echo "Open in Android Studio → Profiler → Load from disk, Eclipse MAT, or VisualVM."
