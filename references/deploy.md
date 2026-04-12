# Deploy & Install

CLI equivalent for Android Studio's `deploy` tool. Covers building, installing, and launching apps on a device or emulator.

## 1. Build and Install (Gradle)

The cleanest approach — builds the APK and installs it in one step.

```bash
# Install debug build on connected device
./gradlew installDebug

# Install release build (requires signing config)
./gradlew installRelease

# Install specific flavor+variant (e.g., flavor "paid", type "debug")
./gradlew installPaidDebug

# Install on a specific device
ANDROID_SERIAL=<serial> ./gradlew installDebug

# Uninstall
./gradlew uninstallDebug
./gradlew uninstallAll
```

### Discover available install tasks
```bash
./gradlew tasks --group=install
```

## 2. Manual ADB Install

Use when you already have an APK file (e.g., downloaded from CI).

```bash
# Install APK
adb install app-debug.apk

# Install on specific device
adb -s <serial> install app-debug.apk

# Force reinstall (same app already installed)
adb install -r app-debug.apk

# Allow downgrade
adb install -d app-debug.apk

# Grant all runtime permissions on install
adb install -g app-debug.apk

# Install to external storage (if supported)
adb install -s app-debug.apk

# All flags combined (common for testing)
adb install -r -g app-debug.apk
```

### Install split APKs (AAB-derived)
```bash
# Install multiple APK splits (base + feature splits)
adb install-multiple base.apk split_config.en.apk split_config.arm64_v8a.apk

# Or use bundletool for AAB → APK sets
bundletool build-apks --bundle=app.aab --output=app.apks --local-testing
bundletool install-apks --apks=app.apks
```

## 3. Launch the App

After installation, launch the app programmatically.

```bash
# Launch main activity (get package/activity from manifest or pm)
adb shell am start -n com.example.app/.MainActivity

# Launch with intent extras
adb shell am start \
  -n com.example.app/.MainActivity \
  -e key "value" \
  --ez booleanKey true \
  --ei intKey 42

# Launch with deep link
adb shell am start \
  -a android.intent.action.VIEW \
  -d "myapp://screen/home"

# Launch with action
adb shell am start -a android.intent.action.SEND \
  --es android.intent.extra.TEXT "Hello" \
  -t text/plain

# Get the main activity name from the APK
aapt dump badging app-debug.apk | grep "launchable-activity"
```

## 4. One-Shot: Build → Install → Launch

```bash
# Full cycle script
PACKAGE="com.example.app"
ACTIVITY="$PACKAGE.MainActivity"

./gradlew installDebug && \
  adb shell am force-stop "$PACKAGE" && \
  adb shell am start -n "$PACKAGE/$ACTIVITY"

# With logcat (opens in background)
adb logcat --pid=$(adb shell pidof "$PACKAGE") &
LOG_PID=$!
./gradlew installDebug && adb shell am start -n "$PACKAGE/$ACTIVITY"
# To stop logcat: kill $LOG_PID
```

## 5. Grant Runtime Permissions

```bash
# Grant a single permission after install
adb shell pm grant com.example.app android.permission.CAMERA
adb shell pm grant com.example.app android.permission.READ_EXTERNAL_STORAGE

# Revoke a permission
adb shell pm revoke com.example.app android.permission.CAMERA

# List all granted permissions
adb shell dumpsys package com.example.app | grep "granted=true"

# Grant all declared permissions (install with -g is simpler)
adb shell pm list permissions -g -d | grep "android.permission" | \
  awk -F: '{print $2}' | \
  xargs -I {} adb shell pm grant com.example.app {}
```

## 6. Uninstall

```bash
# Uninstall app
adb uninstall com.example.app

# Keep app data on uninstall (for debugging data persistence)
adb uninstall -k com.example.app

# Via Gradle
./gradlew uninstallDebug
./gradlew uninstallAll
```

## 7. Multiple Devices / Emulators

```bash
# List all connected devices
adb devices

# Install on ALL connected devices
adb devices | tail -n +2 | awk '{print $1}' | \
  xargs -I{} adb -s {} install -r app-debug.apk

# Install on emulators only
adb devices | grep "emulator" | awk '{print $1}' | \
  xargs -I{} adb -s {} install -r app-debug.apk
```

## 8. Verify Installation

```bash
# Check app is installed
adb shell pm list packages | grep com.example.app

# Get installed version
adb shell dumpsys package com.example.app | grep versionName

# Get APK path on device
adb shell pm path com.example.app

# Get all info
adb shell dumpsys package com.example.app
```

## 9. bundletool (AAB deployment)

Android App Bundles (`.aab`) cannot be installed directly with `adb install`. Use `bundletool`.

```bash
# Download bundletool jar (Google-published, requires only JDK)
# https://github.com/google/bundletool/releases
BUNDLETOOL=bundletool-all.jar

# Build APK set from AAB
java -jar $BUNDLETOOL build-apks \
  --bundle=app/build/outputs/bundle/debug/app-debug.aab \
  --output=/tmp/app.apks \
  --local-testing

# Install on connected device
java -jar $BUNDLETOOL install-apks --apks=/tmp/app.apks

# Generate APK set for a specific device
java -jar $BUNDLETOOL get-device-spec --output=/tmp/device.json
java -jar $BUNDLETOOL build-apks \
  --bundle=app.aab \
  --output=/tmp/app.apks \
  --device-spec=/tmp/device.json
```

## Do / Don't

| Do | Don't |
|---|---|
| Use `./gradlew installDebug` — single command, builds and installs | Manually build then `adb install` unless you already have the APK |
| Use `adb install -r` to reinstall over existing app | Forget `-r` when reinstalling (will fail with INSTALL_FAILED_ALREADY_EXISTS) |
| Use `adb install -g` to pre-grant permissions in tests | Manually dismiss permission dialogs in automated tests |
| Use `bundletool install-apks` for AAB | Try to `adb install` an `.aab` — it will fail |
| Launch via `am start` after install for immediate testing | Manually tap the icon (not scriptable) |
