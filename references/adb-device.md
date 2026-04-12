# ADB Device Interaction

CLI equivalents for Android Studio's `adb_shell_input`, `take_screenshot`, `ui_state`, and `render_compose_preview` tools.

## 1. Device Management

```bash
# List connected devices
adb devices

# List with device details
adb devices -l

# Target a specific device (required when multiple connected)
adb -s <serial> <command>

# Get serial of the only connected device
DEVICE=$(adb get-serialno)

# Wait for device to come online
adb wait-for-device

# Reboot device
adb reboot

# Reboot to recovery / bootloader
adb reboot recovery
adb reboot bootloader
```

When multiple devices are connected, **always** pass `-s <serial>` or set:
```bash
export ANDROID_SERIAL=<serial>   # Applies to all subsequent adb calls in the shell
```

## 2. Input Commands

Equivalent to Android Studio's `adb_shell_input` tool.

### Tap
```bash
adb shell input tap <x> <y>
# Example: tap at (540, 960)
adb shell input tap 540 960
```

### Long press
```bash
adb shell input swipe <x> <y> <x> <y> <duration_ms>
# Example: long press at (540, 960) for 1 second
adb shell input swipe 540 960 540 960 1000
```

### Swipe
```bash
adb shell input swipe <x1> <y1> <x2> <y2> [duration_ms]
# Swipe up (scroll down)
adb shell input swipe 540 1200 540 300 300
# Swipe right (navigate back in some apps)
adb shell input swipe 50 960 900 960 200
```

### Key events
```bash
adb shell input keyevent <keycode>

# Common keycodes
adb shell input keyevent 4      # BACK
adb shell input keyevent 3      # HOME
adb shell input keyevent 187    # RECENTS
adb shell input keyevent 26     # POWER
adb shell input keyevent 24     # VOLUME_UP
adb shell input keyevent 25     # VOLUME_DOWN
adb shell input keyevent 66     # ENTER
adb shell input keyevent 67     # DEL (backspace)
adb shell input keyevent 111    # ESCAPE
adb shell input keyevent 82     # MENU
```

### Text input
```bash
# Type text (spaces must be escaped or use %s)
adb shell input text "Hello"
adb shell input text "Hello%sWorld"   # %s = space

# Clear a text field (select all + delete)
adb shell input keyevent 314           # KEYCODE_SELECT_ALL (API 11+)
adb shell input keyevent 67            # DEL — clears selected text
```

### Combined actions
```bash
# Unlock screen (swipe up on lock screen)
adb shell input keyevent 26          # wake screen
adb shell input swipe 540 1500 540 500 300  # swipe up

# Pull down notification shade
adb shell input swipe 540 0 540 800 300

# Open quick settings (double pull-down)
adb shell input swipe 540 0 540 800 300
adb shell input swipe 540 0 540 800 300
```

## 3. Screen Capture

Equivalent to Android Studio's `take_screenshot` tool.

### Screenshot (PNG)
```bash
# IMPORTANT: Use exec-out, NOT shell redirect (binary is corrupted otherwise)
adb exec-out screencap -p > screenshot.png

# With timestamp
adb exec-out screencap -p > "screenshot_$(date +%Y%m%d_%H%M%S).png"

# Save to device first, then pull (alternative method)
adb shell screencap /sdcard/screen.png
adb pull /sdcard/screen.png ./screen.png
adb shell rm /sdcard/screen.png
```

### Screen recording (video)
```bash
# Record up to 3 minutes (default), stop with Ctrl+C
adb shell screenrecord /sdcard/demo.mp4

# With options
adb shell screenrecord --size 1080x1920 --bit-rate 4000000 /sdcard/demo.mp4

# Pull recording
adb pull /sdcard/demo.mp4 ./demo.mp4
```

### View screenshot immediately (macOS)
```bash
adb exec-out screencap -p > /tmp/screen.png && open /tmp/screen.png
```

## 4. UI Hierarchy

Equivalent to Android Studio's `ui_state` tool. Returns the accessibility/view tree of what is currently on screen.

```bash
# Dump UI hierarchy to device, then pull
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ./ui.xml
adb shell rm /sdcard/ui.xml

# One-liner
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml ./ui.xml && adb shell rm /sdcard/ui.xml
```

The output is XML. Key attributes per node:
- `text` — visible text
- `content-desc` — content description (accessibility label)
- `resource-id` — `package:id/viewId`
- `class` — view class (e.g., `android.widget.TextView`)
- `bounds` — `[x1,y1][x2,y2]` — use centre for tap coordinates
- `clickable`, `focusable`, `scrollable`, `checked`, `enabled`

### Parse bounds to get tap coordinates
```bash
# Extract centre of a view by resource-id (grep + awk, no python needed)
grep "submit_button" ui.xml | grep -o 'bounds="[^"]*"' | head -1 | \
  sed 's/bounds="//;s/"//;s/\]\[/,/;s/\[//;s/\]//' | \
  awk -F, '{cx=int(($1+$3)/2); cy=int(($2+$4)/2); print "Centre:", cx, cy}'
```

## 5. App Management

```bash
# List installed packages
adb shell pm list packages

# Find package by name
adb shell pm list packages | grep myapp

# Get current foreground activity
adb shell dumpsys activity activities | grep mResumedActivity

# Force stop an app
adb shell am force-stop com.example.myapp

# Clear app data (equivalent to uninstall/reinstall)
adb shell pm clear com.example.myapp

# Launch an activity
adb shell am start -n com.example.myapp/.MainActivity

# Launch with deep link
adb shell am start -a android.intent.action.VIEW -d "myapp://screen/detail/123"

# Send broadcast
adb shell am broadcast -a com.example.MY_ACTION

# Get APK path
adb shell pm path com.example.myapp
```

## 6. System Info

```bash
# Device screen resolution
adb shell wm size

# Device DPI
adb shell wm density

# Android version
adb shell getprop ro.build.version.release

# SDK version
adb shell getprop ro.build.version.sdk

# Device model
adb shell getprop ro.product.model

# CPU ABI
adb shell getprop ro.product.cpu.abi

# Battery status
adb shell dumpsys battery

# Network info
adb shell dumpsys connectivity
```

## 7. File Transfer

```bash
# Push file to device
adb push ./local_file.txt /sdcard/remote_file.txt

# Pull file from device
adb pull /sdcard/remote_file.txt ./local_file.txt

# Pull directory
adb pull /sdcard/Download/ ./downloads/

# Push multiple files
adb push file1.txt file2.txt /sdcard/
```

## 8. Compose Preview Alternative

There is **no headless CLI equivalent** for Android Studio's `render_compose_preview`. The closest alternatives:

```bash
# 1. Launch the app on emulator and screenshot
adb shell am start -n com.example.app/.MainActivity
sleep 2
adb exec-out screencap -p > preview.png

# 2. Run a screenshot test (Paparazzi or Roborazzi)
./gradlew :module:recordPaparazziDebug        # record golden images
./gradlew :module:verifyPaparazziDebug        # verify against goldens

# 3. Compose screenshot testing (AndroidX)
./gradlew :module:screenshotTest              # if configured
```

## 9. Wireless ADB

Connect to devices over Wi-Fi — no USB cable needed.

### Android 11+ (Wireless Debugging)
```bash
# On device: Settings → Developer Options → Wireless debugging → ON
# Note the IP:port shown, then tap "Pair device with pairing code"

# Pair (one-time per device)
adb pair <ip>:<pairing_port>
# Enter the 6-digit pairing code when prompted

# Connect
adb connect <ip>:<debug_port>

# Verify
adb devices
```

### Android 10 and below (TCP/IP method)
```bash
# With USB connected first:
adb tcpip 5555

# Disconnect USB, then connect over Wi-Fi
adb connect <device_ip>:5555

# Find device IP
adb shell ip route | grep wlan0 | awk '{print $9}'

# Switch back to USB mode
adb usb
```

### Disconnect
```bash
adb disconnect <ip>:<port>    # specific device
adb disconnect                # all wireless connections
```

## 10. Clipboard Access

```bash
# Paste from device clipboard (into a focused field)
adb shell input keyevent 279   # PASTE

# Select all + copy (in a focused text field)
adb shell input keyevent 256   # CTRL (hold)
adb shell input keyevent 29    # A (select all)
adb shell input keyevent 31    # C (copy)

# Type text directly into a focused field
adb shell input text "paste_this_text"
```

Note: Direct clipboard read/write is restricted since Android 10. Use `input text` for setting content.

## 11. Device Settings (Locale, Dark Mode, Display)

### Dark mode
```bash
# Enable / disable / auto
adb shell cmd uimode night yes
adb shell cmd uimode night no
adb shell cmd uimode night auto

# Check current
adb shell cmd uimode night
```

### Locale / language
```bash
# Set device locale
adb shell setprop persist.sys.locale en-US
adb shell setprop persist.sys.locale es-ES
adb shell setprop persist.sys.locale ja-JP

# Per-app locale (API 34+)
adb shell cmd locale set-app-locales com.example.app --locales en-US

# Check current
adb shell getprop persist.sys.locale
```

### Font scale
```bash
adb shell settings put system font_scale 1.0    # normal
adb shell settings put system font_scale 1.30   # largest
adb shell settings put system font_scale 2.0    # extreme (for testing)
adb shell settings get system font_scale         # read current
```

### Display density
```bash
adb shell wm density 480        # override DPI
adb shell wm density reset      # restore default
adb shell wm size 1080x1920     # override resolution
adb shell wm size reset         # restore default
```

### Animations (disable for testing)
```bash
# Disable all (recommended for UI tests)
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

# Re-enable (1.0 = normal)
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
```

### Stay awake while charging
```bash
adb shell settings put global stay_on_while_plugged_in 3   # USB + AC + wireless
adb shell settings put global stay_on_while_plugged_in 0   # disable
```

## 12. Accessibility Testing

### Automated accessibility check

```bash
# Dump UI hierarchy and report missing labels on clickable/focusable nodes
./skill-scripts/check-accessibility.sh <package>

# Example
./skill-scripts/check-accessibility.sh com.example.myapp
```

Exits with code 1 and lists issues if any clickable or focusable node has no
`text` or `content-desc`. Pass no argument to report all packages in the dump.

> **Compose note:** `uiautomator dump` reads the View layer, not Compose's
> semantic tree. A `TextField` with `label = { Text("…") }` will appear
> unlabelled in the dump but IS correctly labelled for TalkBack. Treat
> Compose text field warnings as informational, not blocking.

### TalkBack
```bash
# Enable
adb shell settings put secure enabled_accessibility_services \
  com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService

# Disable
adb shell settings put secure enabled_accessibility_services ""

# Check
adb shell settings get secure enabled_accessibility_services
```

### Color correction (color blind simulation)
```bash
# Enable
adb shell settings put secure accessibility_display_daltonizer_enabled 1

# Modes: 11 = deuteranomaly, 12 = protanomaly, 13 = tritanomaly
adb shell settings put secure accessibility_display_daltonizer 11

# Disable
adb shell settings put secure accessibility_display_daltonizer_enabled 0
```

### Touch feedback
```bash
# Show touch locations on screen
adb shell settings put system show_touches 1
adb shell settings put system show_touches 0

# Show pointer coordinates
adb shell settings put system pointer_location 1
adb shell settings put system pointer_location 0
```

## Do / Don't

| Do | Don't |
|---|---|
| Use `adb exec-out screencap -p` for screenshots | Use `adb shell screencap \| ...` — binary gets corrupted |
| Pull `uiautomator dump` file before parsing | Try to parse XML from stdout directly |
| Always `-s <serial>` with multiple devices | Assume there is only one device |
| Use `am start -d` for deep link testing | Hardcode screen coordinates without verifying on current resolution |
| Use `adb pair` for Android 11+ wireless debugging | Use `adb tcpip` on Android 11+ — pairing is more secure |
| Disable animations for instrumented tests | Leave animations on during automated tests — causes flaky timing |
| Test with TalkBack + color correction before release | Skip accessibility testing — many users rely on these features |
