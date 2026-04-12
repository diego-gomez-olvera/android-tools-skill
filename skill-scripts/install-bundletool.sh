#!/usr/bin/env bash
# install-bundletool.sh — install bundletool if not already in PATH.
#
# Usage:
#   ./skill-scripts/install-bundletool.sh
#
# macOS: installs via Homebrew.
# Linux: downloads the latest jar from GitHub and installs a wrapper script
#        at /usr/local/bin/bundletool.
# https://github.com/google/bundletool/releases

set -euo pipefail

if command -v bundletool &>/dev/null; then
    echo "bundletool already installed: $(command -v bundletool)"
    exit 0
fi

if [[ "$(uname)" == "Darwin" ]]; then
    brew install bundletool
else
    BUNDLE_TOOL_VERSION=$(curl -s https://api.github.com/repos/google/bundletool/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    curl -Lo /usr/local/bin/bundletool.jar \
      "https://github.com/google/bundletool/releases/download/${BUNDLE_TOOL_VERSION}/bundletool-all-${BUNDLE_TOOL_VERSION}.jar"
    printf '#!/bin/sh\nexec java -jar /usr/local/bin/bundletool.jar "$@"\n' \
      > /usr/local/bin/bundletool
    chmod +x /usr/local/bin/bundletool
    command -v bundletool || echo "Warning: /usr/local/bin not in PATH — add: export PATH=/usr/local/bin:\$PATH"
fi

echo "bundletool installed: $(bundletool version)"
