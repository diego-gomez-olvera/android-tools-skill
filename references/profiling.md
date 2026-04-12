# Performance Profiling

Covers Perfetto trace capture, systrace, heap dumps, memory analysis, and startup profiling — all using SDK tools.

## 1. Perfetto Trace Capture

Perfetto is the modern tracing system for Android (API 28+). Traces are analyzed at [ui.perfetto.dev](https://ui.perfetto.dev).

### Quick capture (recommended)
```bash
./skill-scripts/perfetto.sh            # 10s trace → trace.perfetto-trace
./skill-scripts/perfetto.sh 30         # 30s trace
./skill-scripts/perfetto.sh 10 my.perfetto-trace
# Open result at https://ui.perfetto.dev
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
./skill-scripts/systrace.sh            # 5s trace → trace.html
./skill-scripts/systrace.sh 10         # 10s trace
./skill-scripts/systrace.sh 5 my.html
# Open in Chrome: chrome://tracing → Load → trace.html
```

Requires python3 (`brew install python3` on macOS) and `$ANDROID_HOME/platform-tools/systrace/systrace.py`.

## 3. Heap Dumps

Capture and analyze Java heap snapshots.

```bash
./skill-scripts/heap-dump.sh com.example.app
# → heap.hprof (converted, ready for Android Studio / Eclipse MAT / VisualVM)
```

Requires `hprof-conv` from `$ANDROID_HOME/platform-tools` (resolved automatically).

## 4. Memory Analysis (dumpsys)

No file capture needed — real-time memory stats.

```bash
./skill-scripts/meminfo.sh com.example.app   # full report for one app
./skill-scripts/meminfo.sh                   # system-wide summary (top 20 by PSS)
```

Key sections in the output: `Java Heap`, `Native Heap`, `Code`, `Stack`, `Graphics`, `TOTAL`.

```bash
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
./skill-scripts/startup-time.sh com.example.app/.MainActivity
# Key output: TotalTime (intent → fully drawn), WaitTime (am start → resumed)
```

### Measure warm start
```bash
adb shell input keyevent 3   # HOME (don't force-stop)
adb shell am start-activity -W com.example.app/.MainActivity 2>&1 | grep "TotalTime"
```

### Startup timing + Perfetto trace (combined)
```bash
./skill-scripts/startup-trace.sh com.example.app/.MainActivity
# Prints TotalTime/WaitTime and saves startup.perfetto-trace
# Open at: https://ui.perfetto.dev
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
./skill-scripts/simpleperf.sh com.example.app        # 10s profile → flamegraph.html
./skill-scripts/simpleperf.sh com.example.app 30     # 30s profile
```

Requires python3 and Android NDK installed under `$ANDROID_HOME/ndk` (SDK Manager → NDK).

## Do / Don't

| Do | Don't |
|---|---|
| Use Perfetto for API 28+ (modern, detailed) | Use systrace on new devices — Perfetto supersedes it |
| Convert hprof with `hprof-conv` before opening in non-Android tools | Open raw Android hprof in Eclipse MAT directly — format differs |
| Use `am start-activity -W -S` for cold start timing | Time startup manually with a stopwatch |
| Capture traces during the specific interaction you're profiling | Capture 60-second traces and search for issues — keep traces short and focused |
| Pull Perfetto traces and open at ui.perfetto.dev | Try to parse Perfetto trace files as text |
| Check `dumpsys gfxinfo` "Janky frames" for rendering perf | Rely on visual smoothness alone — measure it |
