#!/usr/bin/env bash
# apk-size.sh — report APK size and manifest summary via aapt2.
#
# Usage:
#   ./skill-scripts/apk-size.sh [apk_path]
#
# Defaults to the first debug APK found under sample/build/outputs/apk/debug/.
# Requires: Android SDK (ANDROID_HOME or ~/Library/Android/sdk on macOS).

set -euo pipefail

SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
AAPT2=$(find "$SDK/build-tools" -name "aapt2" | sort -rV | head -1)
if [[ -z "$AAPT2" ]]; then
    echo "Error: aapt2 not found under $SDK/build-tools" >&2
    exit 1
fi

APK="${1:-$(find . -path "*/build/outputs/apk/debug/*.apk" -not -path "*/androidTest/*" | head -1)}"
if [[ -z "$APK" ]]; then
    echo "Error: no debug APK found. Run ./gradlew assembleDebug first." >&2
    exit 1
fi

echo "APK: $APK"
du -sh "$APK"
echo
"$AAPT2" dump badging "$APK" | grep -E "^(package|application-label:|sdkVersion|targetSdkVersion)"
