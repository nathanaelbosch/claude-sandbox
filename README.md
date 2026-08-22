# agent-sandbox

Run AI coding agents in an isolated [Apptainer](https://apptainer.org) container.

Blocks access to SSH keys, AWS credentials, and most of your home directory while allowing the agent to work normally in your current project. One shared container, multiple agents.

Supported agents: **Claude Code**, **Pi**, **Codex**, **Gemini CLI**, **Aider**

## Install

Requires [Apptainer](https://apptainer.org/docs/admin/main/installation.html).

```bash
git clone git@github.com:nathanaelbosch/claude-sandbox.git
cd claude-sandbox && ./install.sh
agent-sandbox --build
```

## Usage

```bash
agent-sandbox claude                    # Run Claude Code
agent-sandbox pi                       # Run Pi
agent-sandbox claude --profile work    # Use a separate login/config
agent-sandbox claude --exec CMD [ARGS...]  # Run arbitrary command in the sandbox
agent-sandbox --build                  # Rebuild container (shared by all agents)
```

The agent CLI is installed automatically on first run into the persistent home directory.

### Running commands inside the sandbox

Use `--exec` to run arbitrary commands inside the container with the same isolation:

```bash
agent-sandbox claude --exec claude-agent-acp   # ACP bridge for Emacs agent-shell
agent-sandbox pi --exec npm install -g pi-synthetic  # Install a Pi plugin
```

### Profiles (multiple logins)

Pass `--profile NAME` to use a dedicated home directory, giving that profile a completely independent login, config, and history:

```bash
agent-sandbox claude --profile work       # first run: log in with work subscription
agent-sandbox claude --profile personal   # first run: log in with personal subscription
agent-sandbox claude --profile work       # thereafter: reuses work login
```

Each profile is stored at `~/.agent-sandbox/homes/<agent>-<profile>/`.

#### Sharing history across profiles (Claude only)

Add `--shared-history` to pool conversation transcripts across profiles:

```bash
agent-sandbox claude --profile work --shared-history
agent-sandbox claude --profile personal --shared-history
```

Logins, config, and settings stay per-profile — only transcripts are shared.

## How It Works

All agents share a single container image with common tooling (Node.js, Python, uv, git, gh, etc.). The agent-specific CLI is installed at first run into the persistent home.

### Directory layout

```
~/.agent-sandbox/
├── agent-sandbox.sif        # container image (shared by all agents)
└── homes/
    ├── claude/              # default Claude home
    ├── claude-work/         # Claude --profile work
    └── pi/                  # default Pi home
```

### Security model

**Read-write access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/R/` (R user library)
- Agent persistent home (`~/.agent-sandbox/homes/<agent>/`)

**Ephemeral copy:**
- `~/.config/gh/` → `/tmp/.config/gh` (GitHub CLI credentials, copied fresh each run)

**Read-only access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)
- `~/.claude/skills/` and `~/.claude/plugins/` (Claude only — host skills and plugins)

**Blocked:**
- `~/.ssh/`, `~/.aws/`, `~/.config/` (except gh), host environment variables

### Python

Python 3.11 and [uv](https://docs.astral.sh/uv/) are installed inside the container. To avoid conflicts with host virtual environments, the container uses `.venv-sandbox/` instead of `.venv/`:

```bash
echo ".venv-sandbox/" >> .gitignore
```

### Julia

Julia binaries are detected from your host system and bind-mounted read-only. `~/.julia/` is mounted read-write for package management and also exposed at its original host path to support hardcoded paths in precompilation caches.

### agent-shell (Emacs ACP)

The container includes [`claude-agent-acp`](https://github.com/zed-industries/claude-agent-acp) for use with [agent-shell](https://github.com/xenodium/agent-shell) in Emacs:

```bash
agent-sandbox claude --exec claude-agent-acp
```

In your Emacs config:
```elisp
(setq agent-shell-container-command-runner '("agent-sandbox" "claude" "--exec"))
```

### Adding a new agent

Add 4 lines to the `resolve_agent` case statement in `agent-sandbox`:

```bash
    name)   AGENT_INSTALL='<install command>'
            AGENT_BIN='$HOME/.local/bin/<binary>'
            AGENT_CONFIG_DIR=".<config-dir>" ;;
```

### Migrating from claude-sandbox

If upgrading from the old `claude-sandbox` layout, the script will warn about legacy directories and print the exact commands to migrate them. The `claude-sandbox` command still works as a backwards-compatible alias for `agent-sandbox claude`.

## Disclaimer

This is a personal project. I'm not a security or container expert—use at your own risk and don't rely on this for security-critical environments.

## Contributing

Issues, feedback, and pull requests welcome.
