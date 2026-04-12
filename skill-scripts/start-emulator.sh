#!/usr/bin/env bash
# start-emulator.sh — boot the first available AVD and wait until ready.
#
# Usage:
#   ./skill-scripts/start-emulator.sh [avd_name]
#
# If avd_name is omitted, the first AVD returned by emulator -list-avds is used.
# Requires: ANDROID_HOME set or SDK at ~/Library/Android/sdk (macOS default).

set -euo pipefail

SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
EMULATOR="$SDK/emulator/emulator"

AVD="${1:-}"
if [[ -z "$AVD" ]]; then
    AVD=$("$EMULATOR" -list-avds 2>/dev/null | head -1)
    if [[ -z "$AVD" ]]; then
        echo "Error: no AVDs found. Create one in Android Studio → Device Manager." >&2
        exit 1
    fi
fi

echo "Starting AVD: $AVD"
"$EMULATOR" -avd "$AVD" -no-snapshot-save &

echo "Waiting for device to come online..."
adb wait-for-device

echo "Waiting for boot to complete..."
until adb shell getprop sys.boot_completed 2>/dev/null | grep -q "^1$"; do
    sleep 2
done

echo "Emulator ready."
