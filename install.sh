#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="${HOME}/.local/share/claude-sandbox"

mkdir -p "${SANDBOX_DIR}" "${HOME}/.local/bin"

ln -sf "${SCRIPT_DIR}/claude-sandbox" "${SANDBOX_DIR}/claude-sandbox"
ln -sf "${SCRIPT_DIR}/claude-sandbox.def" "${SANDBOX_DIR}/claude-sandbox.def"
ln -sf "${SANDBOX_DIR}/claude-sandbox" "${HOME}/.local/bin/claude-sandbox"

echo "Installed claude-sandbox"
echo "Make sure ~/.local/bin is in your PATH, then run: claude-sandbox --build"
