#!/usr/bin/env bash
# ensure-python3.sh — ensure python3 is available; install via Homebrew on macOS,
# fail with a clear error on other platforms.
#
# Source this file from other scripts rather than invoking it directly:
#   source "$(dirname "${BASH_SOURCE[0]}")/ensure-python3.sh"

if ! command -v python3 &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "python3 not found — installing via Homebrew..."
        brew install python3
    else
        echo "Error: python3 is required but not found in PATH." >&2
        echo "       Install it with your package manager, e.g. apt-get install python3" >&2
        exit 1
    fi
fi
