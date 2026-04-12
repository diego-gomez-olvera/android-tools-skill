#!/usr/bin/env bash
# read-logcat.sh — dump the current logcat buffer, optionally filtered to a
# specific package or PID.
#
# Usage:
#   ./skill-scripts/read-logcat.sh [package]
#
# If package is provided, the buffer is filtered to the process currently
# running under that package name. Exits with an error if the package is not
# running.
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:-}"

if [[ -n "$PACKAGE" ]]; then
    PID=$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$PID" ]]; then
        echo "Error: package '$PACKAGE' is not running on the device." >&2
        exit 1
    fi
    echo "Filtering logcat to package '$PACKAGE' (PID $PID)..."
    adb logcat -d --pid="$PID"
else
    echo "Dumping full logcat buffer..."
    adb logcat -d
fi
