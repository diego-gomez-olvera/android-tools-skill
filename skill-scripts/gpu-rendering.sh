#!/usr/bin/env bash
# gpu-rendering.sh — dump GPU rendering stats for a package (Jank / frame pacing).
#
# Usage:
#   ./skill-scripts/gpu-rendering.sh <package>
#
# Example:
#   ./skill-scripts/gpu-rendering.sh com.example.helloworld
#
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:?Usage: $0 <package>}"

adb shell dumpsys gfxinfo "$PACKAGE" | grep -E "Total frames|Janky frames|deadline missed|90th|95th|99th"
