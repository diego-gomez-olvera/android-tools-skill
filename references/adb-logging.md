# ADB Logging & Debugging

CLI equivalent for Android Studio's `read_logcat` tool, plus crash analysis and memory debugging.

## 1. Basic Logcat

```bash
# Stream all logs
adb logcat

# Stream for specific device
adb -s <serial> logcat

# Dump current buffer and exit (don't stream)
adb logcat -d

# Clear log buffer
adb logcat -c

# Show timestamp and UID
adb logcat -v threadtime
```

## 2. Filtering

### By log level
```bash
# Levels: V (verbose) D (debug) I (info) W (warn) E (error) F (fatal) S (silent)
adb logcat *:E          # only errors and fatal
adb logcat *:W          # warnings and above
adb logcat *:I          # info and above (common for app logs)
adb logcat *:S MyTag:D  # silent everything, show MyTag at debug+
```

### By tag
```bash
# Filter to a specific tag
adb logcat -s MyTag
adb logcat -s MyTag:D OtherTag:I

# Multiple tags
adb logcat -s ActivityManager:I myapp:D
```

### By package (recommended for app debugging)
```bash
# Get the PID of your app first
PID=$(adb shell pidof com.example.myapp)
adb logcat --pid=$PID

# One-liner that survives app restart
adb logcat | grep "$(adb shell pidof com.example.myapp)"

# More robust: filter by package name in log lines
adb logcat | grep -E "com\.example\.myapp|MyTag"
```

### By pattern (grep)
```bash
adb logcat | grep -i "error\|exception\|crash"
adb logcat | grep "D/MyTag"     # Debug logs from MyTag
adb logcat | grep -v "Choreographer"  # Exclude noisy tags
```

## 3. Format Modes

```bash
# Format options: brief (default), tag, process, raw, time, threadtime, long
adb logcat -v time          # timestamps
adb logcat -v threadtime    # timestamp + thread ID (most useful for debugging)
adb logcat -v long          # full metadata block per entry
adb logcat -v tag           # tag + level only, no metadata
```

## 4. Crash Analysis

### Catch crash output
```bash
# Stream logs and capture crash (ANR, exception)
adb logcat *:E -v threadtime 2>&1 | tee logcat_crash.txt

# Filter specifically for crashes
adb logcat | grep -A 30 "AndroidRuntime"   # Java/Kotlin exceptions
adb logcat | grep -A 20 "FATAL EXCEPTION"
```

### ANR (Application Not Responding)
```bash
# ANR traces are written to the device
adb pull /data/anr/traces.txt ./anr_traces.txt   # may need root

# Check logcat for ANR trigger
adb logcat | grep "ANR in"
```

### Native crashes
```bash
# Native crash output comes via logcat
adb logcat | grep -A 50 "tombstone\|libc\|signal"

# Pull tombstone files (needs root or shell permissions)
adb shell ls /data/tombstones/
adb pull /data/tombstones/tombstone_00 ./tombstone_00
```

## 5. Performance Logs

### Frame timing (Choreographer)
```bash
# See jank / dropped frames
adb logcat | grep "Choreographer"
adb logcat | grep "Skipped .* frames"

# Systrace alternative via perfetto
adb shell perfetto --config - --txt --out /data/misc/perfetto-traces/trace.perfetto <<EOF
buffers: { size_kb: 63488 fill_policy: RING_BUFFER }
data_sources: { config { name: "linux.ftrace" ftrace_config { ... } } }
EOF
```

### Memory
```bash
# App memory usage summary
adb shell dumpsys meminfo com.example.myapp

# Java heap only
adb shell dumpsys meminfo com.example.myapp | grep -A 5 "Java Heap"

# System-wide memory
adb shell cat /proc/meminfo

# GC logs (add to logcat filter)
adb logcat | grep -i "gc\|heap\|OOM"
```

## 6. Structured Logcat Output

```bash
# Save to file with rotation (1MB per file, 4 files)
adb logcat -v threadtime -r 1000 -n 4 -f /tmp/logcat.txt

# Read saved log
adb logcat -d -f /tmp/logcat.txt
```

## 7. Real-time Log Monitoring Script

```bash
#!/bin/bash
# monitor.sh — filter logcat to your app, colourized
PACKAGE=${1:-com.example.myapp}
PID=$(adb shell pidof "$PACKAGE" 2>/dev/null)

if [ -z "$PID" ]; then
  echo "App not running. Streaming all logs filtered by package name."
  adb logcat -v time | grep --line-buffered "$PACKAGE"
else
  echo "Streaming logs for PID $PID ($PACKAGE)"
  adb logcat -v time --pid="$PID"
fi
```

## 8. Common Log Tags

| Tag | What it logs |
|---|---|
| `System.out` | `println()` calls (avoid in production) |
| `AndroidRuntime` | Java/Kotlin exceptions and stack traces |
| `ActivityManager` | Activity lifecycle, task management |
| `WindowManager` | Window focus changes |
| `Choreographer` | Frame timing and jank |
| `SQLiteLog` | Database errors |
| `OkHttp` | HTTP requests/responses (if logging interceptor enabled) |
| `Retrofit` | Retrofit call logging |

## Do / Don't

| Do | Don't |
|---|---|
| Filter by PID or package to reduce noise | Stream unfiltered logcat for debugging (too noisy) |
| Use `-v threadtime` for accurate timestamps | Use `-v brief` when debugging async/coroutine issues |
| Capture to file for crash reports | Rely on scrollback in terminal for long crash traces |
| Clear buffer before reproducing a bug (`adb logcat -c`) | Mix log levels confusingly |
