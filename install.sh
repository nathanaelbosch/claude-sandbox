#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${HOME}/.local/bin"

ln -sf "${SCRIPT_DIR}/agent-sandbox" "${HOME}/.local/bin/agent-sandbox"

# Backwards compat
ln -sf "${SCRIPT_DIR}/agent-sandbox" "${HOME}/.local/bin/claude-sandbox"

echo "Installed agent-sandbox"
echo "Make sure ~/.local/bin is in your PATH, then run: agent-sandbox --build"
