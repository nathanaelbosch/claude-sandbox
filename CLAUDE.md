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

# Installation (run from repo root)
./install.sh
```

## Architecture

The project consists of three main components:

1. **`claude-sandbox`** (bash script) - Runner that detects Julia, initializes persistent storage at `~/.claude-sandbox-home/`, constructs Apptainer bind mounts, and executes Claude Code inside the container

2. **`claude-sandbox.def`** (Apptainer definition) - Container recipe based on `node:22-slim` that installs Node.js 22, Python 3.11, uv, gh, git, git-lfs, tmux, and Claude Code CLI

3. **`install.sh`** - Creates symlinks in `~/.local/share/claude-sandbox/` and `~/.local/bin/`

## Security Model

**Read-Write Access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/.claude-sandbox-home/` (persistent sandbox home)

**Ephemeral Copy (fresh each run):**
- `~/.config/gh/` → copied to `/tmp/.config/gh` so gh can perform config migrations

**Read-Only Access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)

**Blocked:** SSH keys, AWS credentials, home directory, host environment variables

**Instance Isolation:** Each container instance gets its own temp directory (`/tmp/claude-sandbox-$UID/instance.XXXXXX`), ensuring multiple users and multiple instances don't interfere with each other. Temp directories are cleaned up on exit.

## Container Environment

- Uses `.venv-sandbox/` for Python venvs (via `UV_PROJECT_ENVIRONMENT`) to avoid conflicts with host `.venv/`
- Git author/email passed from host via environment variables
- NVIDIA GPU support via `--nv` flag

## Documentation

When making changes to the codebase, keep documentation in sync:
- **README.md** - Update the "How It Works" section when changing bind mounts or security model
- **CLAUDE.md** - Update the "Security Model" or "Architecture" sections for structural changes

Include documentation updates in the same commit as the corresponding code changes.
