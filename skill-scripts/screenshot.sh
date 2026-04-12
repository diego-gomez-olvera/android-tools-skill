#!/usr/bin/env bash
# screenshot.sh — capture the device screen to a PNG file.
#
# Usage:
#   ./skill-scripts/screenshot.sh [output.png]
#
# Defaults to shot.png in the current directory.
# Uses adb exec-out (not adb shell) to avoid binary corruption.
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

OUT="${1:-shot.png}"
adb exec-out screencap -p > "$OUT"
echo "Screenshot saved to $OUT"
