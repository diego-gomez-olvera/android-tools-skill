#!/usr/bin/env bash
# startup-time.sh — measure cold-start time for an activity.
#
# Usage:
#   ./skill-scripts/startup-time.sh <package/activity>
#
# Example:
#   ./skill-scripts/startup-time.sh com.example.helloworld/.MainActivity
#
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

COMPONENT="${1:?Usage: $0 <package/activity>}"

adb shell am force-stop "${COMPONENT%%/*}"
sleep 1
adb shell am start -W -n "$COMPONENT" | grep -E "TotalTime|WaitTime|Status"
