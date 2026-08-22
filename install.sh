#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="${HOME}/.local/share/claude-sandbox"

mkdir -p "${SANDBOX_DIR}" "${HOME}/.local/bin"

ln -sf "${SCRIPT_DIR}/claude-sandbox" "${SANDBOX_DIR}/claude-sandbox"
ln -sf "${SCRIPT_DIR}/claude-sandbox.def" "${SANDBOX_DIR}/claude-sandbox.def"
ln -sf "${SANDBOX_DIR}/claude-sandbox" "${HOME}/.local/bin/claude-sandbox"
# transcript-scrub runs on plain JSONL files, so a host-side copy is useful
# for scrubbing transcripts without entering the sandbox; transcript-clone is
# host-side only (it bridges the shared pool and per-profile pools)
ln -sf "${SCRIPT_DIR}/transcript-scrub" "${HOME}/.local/bin/transcript-scrub"
ln -sf "${SCRIPT_DIR}/transcript-clone" "${HOME}/.local/bin/transcript-clone"

echo "Installed claude-sandbox, transcript-scrub and transcript-clone"
echo "Make sure ~/.local/bin is in your PATH, then run: claude-sandbox --build"
