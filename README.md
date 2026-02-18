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
claude-sandbox           # Run Claude Code in sandbox
claude-sandbox --build   # Rebuild container
```

## How It Works

**Read-write access:**
- Current working directory
- `~/.julia/` (Julia packages)
- `~/.claude-sandbox-home/` (persistent container home)

**Ephemeral copy:**
- `~/.config/gh/` → `/tmp/.config/gh` (GitHub CLI credentials, copied fresh each run)

**Read-only access:**
- Julia binaries (auto-detected from host)
- `~/.local/share/uv/python/` (for PyCall and Python-dependent Julia packages)

**Blocked:**
- `~/.ssh/`, `~/.aws/`, `~/.config/` (except gh), host environment variables

### Python

Python 3.11 and [uv](https://docs.astral.sh/uv/) are installed inside the container. To avoid conflicts with host virtual environments, the container uses `.venv-sandbox/` instead of `.venv/`.

Add to your gitignore:
```bash
echo ".venv-sandbox/" >> .gitignore
```

### Julia

Julia binaries are detected from your host system and bind-mounted read-only. The `~/.julia/` directory is mounted read-write for package management.

To support precompilation caches that contain hardcoded paths (e.g., in `deps.jl` files), `~/.julia/` is also exposed read-write at its original host path.

## Disclaimer

This is a personal project. I'm not a security or container expert—use at your own risk and don't rely on this for security-critical environments.

## Contributing

Issues, feedback, and pull requests welcome.
