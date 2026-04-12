#!/usr/bin/env bash
# check-accessibility.sh — dump the UI hierarchy of the foreground app and report
# accessibility issues (missing labels on clickable/focusable nodes).
#
# Usage:
#   ./skill-scripts/check-accessibility.sh [package]
#
# If [package] is omitted, reports all packages found in the dump.
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:-}"
TMP_XML="$(mktemp /tmp/ui_XXXXXX.xml)"

cleanup() { rm -f "$TMP_XML"; }
trap cleanup EXIT

# ── Dump ────────────────────────────────────────────────────────────────────
echo "Dumping UI hierarchy..."
adb shell uiautomator dump /sdcard/ui.xml >/dev/null
adb pull /sdcard/ui.xml "$TMP_XML" >/dev/null
adb shell rm /sdcard/ui.xml

# ── Analyse ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/check-accessibility.py" "$TMP_XML" "$PACKAGE"
