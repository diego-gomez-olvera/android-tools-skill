#!/usr/bin/env bash
# adb-input.sh — send input events to a connected device (adb_shell_input equivalent).
#
# Usage:
#   ./skill-scripts/adb-input.sh <type> [args...]
#
# Types:
#   tap <x> <y>              — tap at coordinates
#   swipe <x1> <y1> <x2> <y2> [duration_ms]
#   text <string>            — type text
#   keyevent <keycode>       — send key (e.g. 3=HOME 4=BACK 26=POWER 66=ENTER)
#
# Examples:
#   ./skill-scripts/adb-input.sh tap 540 960
#   ./skill-scripts/adb-input.sh text "Hello"
#   ./skill-scripts/adb-input.sh keyevent 3
#
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

TYPE="${1:?Usage: $0 <type> [args...]}"
shift

adb shell input "$TYPE" "$@"
