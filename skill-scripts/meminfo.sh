#!/usr/bin/env bash
# meminfo.sh — show memory usage via dumpsys meminfo.
#
# Usage:
#   ./skill-scripts/meminfo.sh [package]
#
# If package is omitted, shows system-wide memory summary (all apps by PSS).
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:-}"

if [[ -n "$PACKAGE" ]]; then
    adb shell dumpsys meminfo "$PACKAGE"
else
    echo "System-wide memory summary (top 20 by PSS):"
    adb shell dumpsys meminfo --sort-by-pss 2>/dev/null | head -40 \
      || adb shell dumpsys meminfo | head -40
fi
