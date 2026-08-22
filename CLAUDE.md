# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Agent Sandbox - a containerized environment that runs AI coding agents (Claude Code, Pi, Codex, Gemini CLI, Aider) in an isolated Apptainer container with strict security boundaries. All agents share a single container image with common tooling; the agent-specific CLI is installed at first run into a persistent home directory.

## Build and Run Commands

```bash
# Build the shared container (first run or to rebuild)
agent-sandbox --build

# Run an agent in sandbox
agent-sandbox claude
agent-sandbox pi

# Pass arguments to the agent
agent-sandbox claude [AGENT_ARGS...]

# Run arbitrary command inside the sandbox
agent-sandbox claude --exec CMD [ARGS...]

# Use a separate persistent home for an independent login/config
agent-sandbox claude --profile NAME [AGENT_ARGS...]

# Pool conversation transcripts across profiles (Claude only)
agent-sandbox claude --profile NAME --shared-history [AGENT_ARGS...]

# Installation (run from repo root)
./install.sh
```

## Architecture

The project consists of three main components:

1. **`agent-sandbox`** (bash script) - Runner that detects the agent from the first argument, resolves agent config (install command, binary path, config directory), detects Julia, initializes persistent storage, constructs Apptainer bind mounts, and executes the agent inside the container

2. **`agent-sandbox.def`** (Apptainer definition) - Container recipe based on `node:22-slim` that installs Node.js 22, Python 3.11, uv, gh, git, git-lfs, tmux, gfortran, and claude-agent-acp. The runscript uses `AGENT_INSTALL` and `AGENT_BIN` env vars passed by the runner to install and launch the selected agent

3. **`install.sh`** - Creates symlinks in `~/.local/bin/` (`agent-sandbox` and `claude-sandbox` for backwards compat)

## Directory Layout

```
~/.agent-sandbox/
├── agent-sandbox.sif        # container image (shared by all agents)
├── homes/
│   ├── claude/              # default Claude home
│   ├── claude-work/         # Claude --profile work
│   └── pi/                  # default Pi home
└── shared/
    └── claude/
        └── projects/        # shared transcript pool
```

## Security Model

**Read-Write Access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/R/` (R user library)
- Agent persistent home (`~/.agent-sandbox/homes/<agent>/`; `--profile NAME` uses `~/.agent-sandbox/homes/<agent>-NAME/`)
- `~/.agent-sandbox/shared/<agent>/projects/` (only with `--shared-history`)

**Ephemeral Copy (fresh each run):**
- `~/.config/gh/` → copied to `/tmp/.config/gh` so gh can perform config migrations

**Read-Only Access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)
- `~/.claude/skills/` and `~/.claude/plugins/` (Claude only — host skills/plugins)

**Blocked:** SSH keys, AWS credentials, home directory, host environment variables

**Instance Isolation:** Each container instance gets its own temp directory (`/tmp/agent-sandbox-$UID/instance.XXXXXX`), ensuring multiple users and multiple instances don't interfere. Temp directories are cleaned up on exit.

## Container Environment

- Uses `.venv-sandbox/` for Python venvs (via `UV_PROJECT_ENVIRONMENT`) to avoid conflicts with host `.venv/`
- Git author/email passed from host via environment variables
- NVIDIA GPU support via `--nv` flag
- `--exec` mode runs arbitrary commands with the same isolation; uses `apptainer exec` instead of `apptainer run`
- `--profile NAME` selects a dedicated persistent home, enabling multiple independent logins per agent
- `--shared-history` (Claude only) bind-mounts a common transcript pool so profiles share resumable conversation history while keeping per-profile credentials/config

## Adding a New Agent

Add 4 lines to the `resolve_agent` case statement in `agent-sandbox`:

```bash
    name)   AGENT_INSTALL='<install command>'
            AGENT_BIN='$HOME/.local/bin/<binary>'
            AGENT_CONFIG_DIR=".<config-dir>" ;;
```

## Documentation

When making changes to the codebase, keep documentation in sync:
- **README.md** - Update the "How It Works" section when changing bind mounts or security model
- **CLAUDE.md** - Update the "Security Model" or "Architecture" sections for structural changes

Include documentation updates in the same commit as the corresponding code changes.
