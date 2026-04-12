# Performance Profiling

Covers Perfetto trace capture, systrace, heap dumps, memory analysis, and startup profiling — all using SDK tools.

## 1. Perfetto Trace Capture

Perfetto is the modern tracing system for Android (API 28+). Traces are analyzed at [ui.perfetto.dev](https://ui.perfetto.dev).

### Quick capture (recommended)
```bash
# Record a 10-second trace with default categories
adb shell perfetto -o /data/misc/perfetto-traces/trace.perfetto-trace -t 10s \
  sched freq idle am wm gfx view binder_driver hal dalvik camera input res memory

# Pull and open
adb pull /data/misc/perfetto-traces/trace.perfetto-trace ./trace.perfetto-trace
# Open at https://ui.perfetto.dev
```

### With config file (fine-grained control)
```bash
cat > /tmp/perfetto.cfg <<'EOF'
buffers: {
  size_kb: 63488
  fill_policy: RING_BUFFER
}
data_sources: {
  config {
    name: "linux.ftrace"
    ftrace_config {
      ftrace_events: "sched/sched_switch"
      ftrace_events: "power/suspend_resume"
      ftrace_events: "sched/sched_wakeup"
      ftrace_events: "sched/sched_wakeup_new"
      atrace_categories: "am"
      atrace_categories: "wm"
      atrace_categories: "gfx"
      atrace_categories: "view"
      atrace_categories: "dalvik"
    }
  }
}
data_sources: {
  config {
    name: "linux.process_stats"
    process_stats_config {
      scan_all_processes_on_start: true
      proc_stats_poll_ms: 1000
    }
  }
}
duration_ms: 10000
EOF

# Push config and record
adb push /tmp/perfetto.cfg /data/misc/perfetto-configs/trace.cfg
adb shell perfetto --config /data/misc/perfetto-configs/trace.cfg \
  -o /data/misc/perfetto-traces/trace.perfetto-trace

# Pull result
adb pull /data/misc/perfetto-traces/trace.perfetto-trace ./trace.perfetto-trace
```

### Record via `record_android_trace` helper
```bash
# If the helper script is available in the SDK
$ANDROID_HOME/platform-tools/record_android_trace -o trace.perfetto-trace -t 10s -b 64mb
```

## 2. Systrace (Legacy, API < 28)

```bash
# systrace is a Python wrapper — available in SDK
python3 $ANDROID_HOME/platform-tools/systrace/systrace.py \
  --time=5 \
  -o trace.html \
  gfx view wm am dalvik sched freq idle

# Open in Chrome
open trace.html   # macOS
# Or navigate to chrome://tracing and load trace.html
```

## 3. Heap Dumps

Capture and analyze Java heap snapshots.

### Capture heap dump
```bash
# Get PID of the target app
PID=$(adb shell pidof com.example.app)

# Dump heap to device storage
adb shell am dumpheap $PID /data/local/tmp/heap.hprof

# Pull to local machine
adb pull /data/local/tmp/heap.hprof ./heap.hprof
adb shell rm /data/local/tmp/heap.hprof
```

### Convert for analysis
```bash
# Android hprof format differs from standard Java format
# Convert with hprof-conv (bundled in platform-tools)
hprof-conv heap.hprof heap-converted.hprof

# Now open heap-converted.hprof in:
# - Android Studio Memory Profiler (File → Open)
# - Eclipse MAT (https://eclipse.dev/mat/)
# - VisualVM
```

### One-liner: capture + convert
```bash
PACKAGE=com.example.app
PID=$(adb shell pidof $PACKAGE)
adb shell am dumpheap $PID /data/local/tmp/heap.hprof && \
  adb pull /data/local/tmp/heap.hprof ./heap-raw.hprof && \
  adb shell rm /data/local/tmp/heap.hprof && \
  hprof-conv heap-raw.hprof heap.hprof && \
  rm heap-raw.hprof && \
  echo "Heap dump ready: heap.hprof"
```

## 4. Memory Analysis (dumpsys)

No file capture needed — real-time memory stats.

```bash
# Full memory report for an app
adb shell dumpsys meminfo com.example.app

# Key sections in output:
#   Java Heap    — managed heap (GC-collected)
#   Native Heap  — malloc'd memory (NDK, bitmaps)
#   Code         — .dex/.oat/.so mapped memory
#   Stack        — thread stacks
#   Graphics     — GPU/surface buffers
#   TOTAL        — sum of all categories

# Compact summary (just totals)
adb shell dumpsys meminfo com.example.app | grep "TOTAL"

# System-wide memory overview
adb shell dumpsys meminfo

# All apps ranked by memory
adb shell dumpsys meminfo --sort-by-pss | head -40

# Low-memory killer thresholds
adb shell getprop dalvik.vm.heapsize        # max heap per app
adb shell getprop dalvik.vm.heapgrowthlimit  # growth limit before GC
```

### Track memory over time
```bash
# Sample every 2 seconds for 30 seconds
for i in $(seq 1 15); do
  TOTAL=$(adb shell dumpsys meminfo com.example.app | grep "TOTAL:" | awk '{print $2}')
  echo "$(date +%H:%M:%S) ${TOTAL}K"
  sleep 2
done
```

## 5. Startup Profiling

### Measure cold start time
```bash
# Force-stop + cold start with timing
adb shell am force-stop com.example.app
adb shell am start-activity -W -S com.example.app/.MainActivity

# Key output values:
#   TotalTime   — time from intent to activity fully drawn
#   WaitTime    — time from am start to activity resumed
#   ThisTime    — time for this specific activity

# Cold start (clear process + start)
adb shell am force-stop com.example.app && \
  adb shell am start-activity -W -S com.example.app/.MainActivity 2>&1 | grep -E "TotalTime|WaitTime"
```

### Measure warm start
```bash
# Press home first, don't force-stop
adb shell input keyevent 3   # HOME
adb shell am start-activity -W com.example.app/.MainActivity 2>&1 | grep "TotalTime"
```

### Startup trace with Perfetto
```bash
# Capture a trace that includes app startup
adb shell am force-stop com.example.app
adb shell perfetto -o /data/misc/perfetto-traces/startup.perfetto-trace -t 15s \
  sched freq idle am wm gfx view dalvik &

sleep 1
adb shell am start-activity -W -S com.example.app/.MainActivity
wait

adb pull /data/misc/perfetto-traces/startup.perfetto-trace ./startup-trace.perfetto-trace
```

### reportFullyDrawn timing
```bash
# If the app calls reportFullyDrawn(), it appears in logcat
adb logcat -d | grep "Fully drawn"
# Output: I/ActivityTaskManager: Fully drawn com.example.app/.MainActivity: +1s500ms
```

## 6. GPU Rendering

```bash
# Enable GPU profiling bars (shows on device)
adb shell setprop debug.hwui.profile true
adb shell setprop debug.hwui.profile visual_bars

# Dump GPU frame timing data
adb shell dumpsys gfxinfo com.example.app

# Reset GPU stats
adb shell dumpsys gfxinfo com.example.app reset

# Key metric: "Janky frames" percentage
adb shell dumpsys gfxinfo com.example.app | grep "Janky frames"

# Disable profiling
adb shell setprop debug.hwui.profile false
```

## 7. Simpleperf (CPU Profiling)

Bundled in NDK. Works on Java, Kotlin, and native code.

```bash
SIMPLEPERF=$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk 2>/dev/null | tail -1)/simpleperf/simpleperf

# Record CPU profile of a running app (10 seconds)
adb shell run-as com.example.app simpleperf record -p $(adb shell pidof com.example.app) --duration 10

# Or use the app_profiler.py helper
python3 $ANDROID_HOME/ndk/*/simpleperf/app_profiler.py \
  -p com.example.app -r "--duration 10" -o perf.data

# Generate flamegraph
python3 $ANDROID_HOME/ndk/*/simpleperf/report_html.py -i perf.data -o flamegraph.html
```

## Do / Don't

| Do | Don't |
|---|---|
| Use Perfetto for API 28+ (modern, detailed) | Use systrace on new devices — Perfetto supersedes it |
| Convert hprof with `hprof-conv` before opening in non-Android tools | Open raw Android hprof in Eclipse MAT directly — format differs |
| Use `am start-activity -W -S` for cold start timing | Time startup manually with a stopwatch |
| Capture traces during the specific interaction you're profiling | Capture 60-second traces and search for issues — keep traces short and focused |
| Pull Perfetto traces and open at ui.perfetto.dev | Try to parse Perfetto trace files as text |
| Check `dumpsys gfxinfo` "Janky frames" for rendering perf | Rely on visual smoothness alone — measure it |
