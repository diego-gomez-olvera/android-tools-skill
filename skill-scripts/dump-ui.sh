#!/usr/bin/env bash
# dump-ui.sh — dump the UI hierarchy from a connected device and print a
# readable node summary.
#
# Usage:
#   ./skill-scripts/dump-ui.sh [package_filter]
#
# package_filter: optional substring to restrict output to nodes whose package
#                 attribute contains it (e.g. "com.example.helloworld").
# Requires: adb in PATH, a connected device or running emulator.

set -euo pipefail

PACKAGE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_XML="$(mktemp /tmp/ui_XXXXXX.xml)"

cleanup() { rm -f "$TMP_XML"; }
trap cleanup EXIT

echo "Dumping UI hierarchy..."
adb shell uiautomator dump /sdcard/ui.xml >/dev/null
adb pull /sdcard/ui.xml "$TMP_XML" >/dev/null
adb shell rm /sdcard/ui.xml

python3 "$SCRIPT_DIR/parse-ui-dump.py" "$TMP_XML" "$PACKAGE"
