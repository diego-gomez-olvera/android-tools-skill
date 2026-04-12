#!/usr/bin/env bash
# systrace.sh — capture a Systrace HTML trace (legacy, API < 28).
#
# Usage:
#   ./skill-scripts/systrace.sh [duration_s] [output.html]
#
# Defaults: duration=5s, output=trace.html.
# Open the result in Chrome (chrome://tracing) or via 'open trace.html' on macOS.
#
# Requires: python3, $ANDROID_HOME set, a connected device or running emulator.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ensure-python3.sh
source "$SCRIPT_DIR/ensure-python3.sh"

SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
SYSTRACE="$SDK/platform-tools/systrace/systrace.py"

if [[ ! -f "$SYSTRACE" ]]; then
    echo "Error: systrace.py not found at $SYSTRACE" >&2
    echo "       Ensure Android SDK Platform Tools are installed." >&2
    exit 1
fi

DURATION="${1:-5}"
OUTPUT="${2:-trace.html}"

python3 "$SYSTRACE" --time="$DURATION" -o "$OUTPUT" \
  gfx view wm am dalvik sched freq idle

echo "Trace saved to $OUTPUT"
echo "Open in Chrome: chrome://tracing → Load → $OUTPUT"
