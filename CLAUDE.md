# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code Apptainer Sandbox - a containerized environment that runs Claude Code in an isolated Apptainer container with strict security boundaries. It provides sandboxed execution while selectively allowing access to specific resources (working directory, GitHub credentials, Julia installations).

## Build and Run Commands

```bash
# Build the container (first run or to rebuild)
claude-sandbox --build

# Run Claude Code in sandbox
claude-sandbox

# Pass arguments to Claude Code
claude-sandbox [CLAUDE_ARGS...]

# Run arbitrary command inside the sandbox (e.g., claude-agent-acp for Emacs ACP)
claude-sandbox --exec CMD [ARGS...]

# Use a separate persistent home for an independent login/config (e.g. work vs personal)
claude-sandbox --profile NAME [CLAUDE_ARGS...]

# Pool conversation transcripts across profiles (keeps logins/config separate)
claude-sandbox --profile NAME --shared-history [CLAUDE_ARGS...]

# Installation (run from repo root)
./install.sh

# Move a conversation to a stricter backend profile (scrubs only the copy)
transcript-clone ~/.claude-sandbox-shared/projects/<proj>/<session>.jsonl

# Scrub a transcript in place so a stricter backend can resume it
transcript-scrub TRANSCRIPT.jsonl     # or: transcript-scrub --hook (SessionStart hook)
```

## Architecture

The project consists of four main components:

1. **`claude-sandbox`** (bash script) - Runner that detects Julia, initializes persistent storage at `~/.claude-sandbox-home/`, constructs Apptainer bind mounts, and executes Claude Code inside the container. Each run also copies `transcript-scrub` into the sandbox home's `~/.local/bin/` so it is available inside the container

2. **`claude-sandbox.def`** (Apptainer definition) - Container recipe based on `node:22-slim` that installs Node.js 22, Python 3.11, uv, gh, git, git-lfs, tmux, gfortran, claude-agent-acp, and Claude Code CLI

3. **`transcript-scrub`** (Python 3, stdlib only) - Rewrites a Claude Code transcript (JSONL) in place so backends with a stricter message schema than Anthropic's (e.g. synthetic.new) can resume it: strips `thinking`/`redacted_thinking` blocks, drops malformed/orphaned/duplicate `tool_result` blocks, synthesizes results for unanswered `tool_use` calls (appended as a chained user entry when the transcript ends mid-tool-call), and backfills empty message content. Works on folded logical turns (consecutive same-role entries = one turn), separately per sidechain stream. Idempotent; keeps a one-time `<file>.scrub-backup`. `--hook` mode reads hook JSON on stdin and scrubs `transcript_path`, intended for a per-profile `SessionStart` (matcher `resume`) hook

4. **`transcript-clone`** (bash) - Host-side one-way bridge between transcript pools: copies a transcript from the shared pool into a profile's pool and scrubs only the copy (or plain-copies back into the shared pool), leaving the source untouched. Refuses to overwrite an existing destination without `--force`. This is the recommended way to move conversations across backends; the stricter profile should NOT use `--shared-history`

5. **`install.sh`** - Creates symlinks in `~/.local/share/claude-sandbox/` and `~/.local/bin/` (including host-side `transcript-scrub` and `transcript-clone`)

## Security Model

**Read-Write Access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/R/` (R user library)
- `~/.claude-sandbox-home/` (persistent sandbox home; `--profile NAME` switches this to `~/.claude-sandbox-home-NAME/` for an isolated login/config/history)
- `~/.claude-sandbox-shared/projects/` (only with `--shared-history`; bind-mounted over `/home/sandbox/.claude/projects` so profiles pool conversation transcripts while keeping separate credentials/config)

**Ephemeral Copy (fresh each run):**
- `~/.config/gh/` → copied to `/tmp/.config/gh` so gh can perform config migrations

**Read-Only Access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)
- `~/.claude/skills/` and `~/.claude/plugins/` (host Claude Code skills/plugins, so sandboxed sessions see the same skills without exposing credentials/history/projects)

**Blocked:** SSH keys, AWS credentials, home directory, host environment variables

**Instance Isolation:** Each container instance gets its own temp directory (`/tmp/claude-sandbox-$UID/instance.XXXXXX`), ensuring multiple users and multiple instances don't interfere with each other. Temp directories are cleaned up on exit.

## Container Environment

- Uses `.venv-sandbox/` for Python venvs (via `UV_PROJECT_ENVIRONMENT`) to avoid conflicts with host `.venv/`
- Git author/email passed from host via environment variables
- NVIDIA GPU support via `--nv` flag
- `--exec` mode runs arbitrary commands (e.g., `claude-agent-acp`) with the same isolation as the default mode; uses `apptainer exec` instead of `apptainer run`
- `--profile NAME` (or `CLAUDE_SANDBOX_PROFILE=NAME`) selects a dedicated persistent home (`~/.claude-sandbox-home-NAME/`), enabling multiple independent Claude Code logins; must precede `--exec`. Leading options are parsed in a loop before dispatching, and remaining args are passed through to Claude Code
- `--shared-history` bind-mounts a common transcript pool (`~/.claude-sandbox-shared/projects/`) over `/home/sandbox/.claude/projects`, so profiles share resumable conversation history while keeping per-profile credentials/config. Only transcripts are shared; the `.claude.json` input history is not. If profiles use different model backends (e.g. Anthropic vs. a stricter compatible API), cross-resuming Anthropic-written transcripts needs a scrubbed copy — use `transcript-clone` (recommended) or `transcript-scrub` (see README's "Sharing history across backends")

## Documentation

When making changes to the codebase, keep documentation in sync:
- **README.md** - Update the "How It Works" section when changing bind mounts or security model
- **CLAUDE.md** - Update the "Security Model" or "Architecture" sections for structural changes

Include documentation updates in the same commit as the corresponding code changes.
