# claude-sandbox

Run [Claude Code](https://claude.ai/code) in an isolated [Apptainer](https://apptainer.org) container.

Blocks access to SSH keys, AWS credentials, and most of your home directory while allowing Claude to work normally in your current project.

## Install

Requires [Apptainer](https://apptainer.org/docs/admin/main/installation.html).

```bash
git clone git@github.com:nathanaelbosch/claude-sandbox.git
cd claude-sandbox && ./install.sh
claude-sandbox --build
```

## Usage

```bash
claude-sandbox                        # Run Claude Code in sandbox
claude-sandbox --build                # Rebuild container
claude-sandbox --exec CMD [ARGS...]   # Run arbitrary command inside the sandbox
claude-sandbox --profile NAME ...     # Use a separate login/config (e.g. work vs personal)
claude-sandbox --shared-history ...   # Pool conversation transcripts across profiles
```

### Profiles (multiple logins)

By default the sandbox stores its login and config in `~/.claude-sandbox-home/`.
Pass `--profile NAME` to use a dedicated home at `~/.claude-sandbox-home-NAME/`
instead, giving that profile a completely independent Claude Code login, config,
and history. Log in once per profile and switch freely without re-authenticating:

```bash
claude-sandbox --profile work       # first run: log in with the work subscription
claude-sandbox --profile personal   # first run: log in with the personal subscription
claude-sandbox --profile work       # thereafter: reuses the work login, no re-login
```

The profile can also be set via the `CLAUDE_SANDBOX_PROFILE` environment variable,
which makes per-profile shell aliases easy:

```bash
alias claude-work='CLAUDE_SANDBOX_PROFILE=work claude-sandbox'
alias claude-personal='CLAUDE_SANDBOX_PROFILE=personal claude-sandbox'
```

`--profile` works with `--exec` too, but must come before it (everything after
`--exec` is treated as the command to run).

#### Sharing history across profiles

Profiles are isolated by default, including conversation history. Add
`--shared-history` to pool the **conversation transcripts** (the resumable
sessions, stored in `.claude/projects/`) in a common directory
(`~/.claude-sandbox-shared/projects/`) that all profiles bind-mount:

```bash
claude-sandbox --profile work --shared-history       # work login, shared transcripts
claude-sandbox --profile personal --shared-history   # personal login, same transcripts
```

Logins, config, and settings stay per-profile — only the transcripts are shared.
Note that this lets either profile read conversations created under the other,
so it crosses the work/personal boundary by design. The up-arrow input history
(stored in `.claude.json` alongside account state) is *not* shared.

## How It Works

**Read-write access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/R/` (R user library)
- `~/.claude-sandbox-home/` (persistent container home; `~/.claude-sandbox-home-NAME/` with `--profile NAME`)

**Ephemeral copy:**
- `~/.config/gh/` → `/tmp/.config/gh` (GitHub CLI credentials, copied fresh each run)

**Read-only access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)
- `~/.claude/skills/` and `~/.claude/plugins/` (host Claude Code skills and plugins)

**Blocked:**
- `~/.ssh/`, `~/.aws/`, `~/.config/` (except gh), host environment variables

### Python

Python 3.11 and [uv](https://docs.astral.sh/uv/) are installed inside the container. To avoid conflicts with host virtual environments, the container uses `.venv-sandbox/` instead of `.venv/`.

Add to your gitignore:
```bash
echo ".venv-sandbox/" >> .gitignore
```

### R

R and `r-base-dev` are installed inside the container. User-installed packages in `~/R/` are bind-mounted for persistence across runs.

### Julia

Julia binaries are detected from your host system and bind-mounted read-only. The `~/.julia/` directory is mounted read-write for package management.

To support precompilation caches that contain hardcoded paths (e.g., in `deps.jl` files), `~/.julia/` is also exposed read-write at its original host path.

### agent-shell (Emacs ACP)

The container includes [`claude-agent-acp`](https://github.com/zed-industries/claude-agent-acp), an ACP bridge for use with [agent-shell](https://github.com/xenodium/agent-shell) in Emacs. Use `--exec` to run it inside the sandbox:

```bash
claude-sandbox --exec claude-agent-acp
```

In your Emacs config:
```elisp
(setq agent-shell-container-command-runner '("claude-sandbox" "--exec"))
```

All sandboxing constraints apply equally to `--exec` mode — the same bind mounts, env vars, and isolation flags are used.

## Disclaimer

This is a personal project. I'm not a security or container expert—use at your own risk and don't rely on this for security-critical environments.

## Contributing

Issues, feedback, and pull requests welcome.
