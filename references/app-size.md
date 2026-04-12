# App Size Analysis

Covers APK/AAB inspection, size breakdown, resource shrinking verification, and dex method counting — all using SDK tools.

## 1. aapt2 (APK Content Inspection)

Located at `$ANDROID_HOME/build-tools/<version>/aapt2`.

```bash
AAPT2=$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/aapt2

# Dump APK summary (package name, version, permissions, features)
$AAPT2 dump badging app-release.apk

# Dump resource table
$AAPT2 dump resources app-release.apk

# Dump specific resource values
$AAPT2 dump resources app-release.apk | grep "string/app_name"

# Dump manifest
$AAPT2 dump xmltree app-release.apk --file AndroidManifest.xml

# Dump a specific XML resource
$AAPT2 dump xmltree app-release.apk --file res/layout/activity_main.xml

# List all files in the APK with sizes
unzip -l app-release.apk | sort -k1 -rn | head -30
```

### aapt (v1, legacy but simpler for quick checks)
```bash
AAPT=$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/aapt

# Quick package info
$AAPT dump badging app-release.apk | grep -E "package:|sdkVersion:|targetSdkVersion:"

# List permissions
$AAPT dump permissions app-release.apk
```

## 2. APK Size Breakdown

### Manual breakdown by file type
```bash
# Total APK size
du -sh app-release.apk

# Size by directory inside APK
unzip -l app-release.apk | awk '{print $4}' | \
  sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -20

# Size of DEX files
unzip -l app-release.apk | grep "\.dex$"

# Size of native libraries
unzip -l app-release.apk | grep "\.so$"

# Size of resources
unzip -l app-release.apk | grep "^.*res/" | awk '{sum+=$1} END {print sum/1024/1024 " MB"}'

# Size of assets
unzip -l app-release.apk | grep "^.*assets/" | awk '{sum+=$1} END {print sum/1024/1024 " MB"}'

# Largest 20 files in APK
unzip -l app-release.apk | sort -k1 -rn | head -20
```

### Compare two APK versions
```bash
# Size difference
echo "Old: $(du -sh old.apk | awk '{print $1}')"
echo "New: $(du -sh new.apk | awk '{print $1}')"

# Detailed diff (which files grew/shrank)
diff <(unzip -l old.apk | sort -k4) <(unzip -l new.apk | sort -k4) | head -50
```

## 3. bundletool Size Analysis

For AAB (Android App Bundle) files — shows download and install sizes per device configuration.

```bash
# Download bundletool jar (Google-published, requires only JDK)
# https://github.com/google/bundletool/releases
BUNDLETOOL=bundletool-all.jar
curl -Lo $BUNDLETOOL "https://github.com/google/bundletool/releases/latest/download/bundletool-all-1.17.2.jar"

# Get total download size for all configurations
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab

# Get size for a specific device
java -jar $BUNDLETOOL get-device-spec --output=device.json
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab --device-spec=device.json

# Get size broken down by dimension (ABI, screen density, language)
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab --dimensions=ABI
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab --dimensions=SCREEN_DENSITY
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab --dimensions=LANGUAGE

# All dimensions at once
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab \
  --dimensions=ABI,SCREEN_DENSITY,LANGUAGE

# Output as CSV
java -jar $BUNDLETOOL get-size-total --bundle=app-release.aab --human-readable-sizes
```

## 4. DEX Method Count

Important for legacy multidex (pre-API 21) and for monitoring app complexity.

### Using dexdump (SDK tool)
```bash
DEXDUMP=$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/dexdump

# Count methods in a DEX file
$DEXDUMP -f classes.dex | grep "method_ids_size"

# Count across all DEX files in an APK
unzip -o app-release.apk "*.dex" -d /tmp/dex_count
for dex in /tmp/dex_count/*.dex; do
  count=$($DEXDUMP -f "$dex" | grep "method_ids_size" | awk '{print $NF}')
  echo "$(basename $dex): $count methods"
done
TOTAL=$(for dex in /tmp/dex_count/*.dex; do $DEXDUMP -f "$dex" | grep "method_ids_size" | awk '{print $NF}'; done | paste -sd+ | bc)
echo "Total: $TOTAL methods"
rm -rf /tmp/dex_count
```

### Using d8 (modern)
```bash
D8=$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/d8

# d8 doesn't directly count, but you can use the output of dexdump
# or use APK Analyzer functionality via command line (see section 5)
```

## 5. Resource Shrinking Verification

After building with `isShrinkResources = true`:

```bash
# Check what resources were removed
# R8 logs resource shrinking info to:
cat app/build/outputs/mapping/release/resources.txt 2>/dev/null

# Or check the APK directly — look for empty/replaced resources
unzip -l app-release.apk | grep "res/" | wc -l

# Compare resources between debug and release
echo "Debug resources:"
unzip -l app-debug.apk | grep "res/" | wc -l
echo "Release resources:"
unzip -l app-release.apk | grep "res/" | wc -l

# Find unused resources (build tool output)
# Enable strict mode in build.gradle.kts:
# android { buildTypes { release { isShrinkResources = true } } }
# Add to res/raw/keep.xml to force-keep specific resources
```

### Check for large resources
```bash
# Find images > 100KB in APK
unzip -l app-release.apk | grep -E "\.(png|jpg|webp)" | \
  awk '$1 > 102400 {print $1/1024 "KB", $4}' | sort -rn

# Check if WebP conversion would help (compare PNG vs WebP sizes)
# PNG files that could be converted:
unzip -l app-release.apk | grep "\.png$" | awk '{sum+=$1} END {print sum/1024 "KB in PNG"}'
```

## 6. Native Library Analysis

```bash
# List native libraries and their ABIs
unzip -l app-release.apk | grep "\.so$"

# Size per ABI
for abi in armeabi-v7a arm64-v8a x86 x86_64; do
  SIZE=$(unzip -l app-release.apk | grep "lib/$abi/" | awk '{sum+=$1} END {print sum/1024/1024}')
  echo "$abi: ${SIZE:-0} MB"
done

# Check which ABIs are included
unzip -l app-release.apk | grep "lib/" | sed 's|.*lib/||;s|/.*||' | sort -u
```

## 7. Size Budget Script

```bash
#!/bin/bash
# size-check.sh — fail CI if APK exceeds budget
APK="${1:-app/build/outputs/apk/release/app-release.apk}"
MAX_MB="${2:-20}"

if [ ! -f "$APK" ]; then
  echo "APK not found: $APK"
  exit 1
fi

SIZE_BYTES=$(wc -c < "$APK")
SIZE_MB=$(echo "scale=2; $SIZE_BYTES / 1048576" | bc)

echo "APK size: ${SIZE_MB} MB (budget: ${MAX_MB} MB)"

if (( $(echo "$SIZE_MB > $MAX_MB" | bc -l) )); then
  echo "FAIL: APK exceeds size budget by $(echo "$SIZE_MB - $MAX_MB" | bc) MB"
  echo ""
  echo "Largest files:"
  unzip -l "$APK" | sort -k1 -rn | head -15
  exit 1
else
  echo "PASS: within budget"
fi
```

## Do / Don't

| Do | Don't |
|---|---|
| Use `bundletool get-size-total` for AAB download size estimates | Use raw AAB file size — it's not what users download |
| Compare debug vs release APK sizes to verify shrinking works | Assume `isShrinkResources` removed everything — verify |
| Monitor APK size in CI with a budget script | Let APK size grow unchecked — set a threshold |
| Check per-ABI native lib sizes separately | Include all ABIs when only arm64-v8a matters for production |
| Use `unzip -l` for quick file-level size breakdown | Install third-party tools when SDK tools suffice |
| Convert large PNGs to WebP | Ship uncompressed PNGs > 100KB |
