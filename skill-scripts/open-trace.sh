#!/usr/bin/env bash
# open-trace.sh — serve a Perfetto trace file via local HTTP and open it in
# the Perfetto UI (ui.perfetto.dev). The UI loads the trace via ?url= parameter.
#
# Usage:
#   ./skill-scripts/open-trace.sh <trace.perfetto-trace> [port]
#
# Defaults: port=9001.
# Requires: python3.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ensure-python3.sh
source "$SCRIPT_DIR/ensure-python3.sh"

TRACE="${1:?Usage: $0 <trace.perfetto-trace> [port]}"
PORT="${2:-9001}"

TRACE_ABS="$(cd "$(dirname "$TRACE")" && pwd)/$(basename "$TRACE")"
TRACE_DIR="$(dirname "$TRACE_ABS")"
TRACE_FILE="$(basename "$TRACE_ABS")"

echo "Serving $TRACE_FILE on port $PORT..."
python3 "$SCRIPT_DIR/serve-trace.py" "$PORT" "$TRACE_DIR" &>/dev/null &
HTTP_PID=$!

sleep 1

URL="https://ui.perfetto.dev/#!/?url=http://127.0.0.1:${PORT}/${TRACE_FILE}"
echo "Opening: $URL"

if command -v open &>/dev/null; then
    open "$URL"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$URL"
else
    echo "Open this URL in your browser: $URL"
fi

echo "Trace server running (PID $HTTP_PID) — stop with: kill $HTTP_PID"
