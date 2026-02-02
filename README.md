# Claude Code Apptainer Sandbox

Run Claude Code in an isolated Apptainer container with strict security boundaries.

## What's Isolated

| Resource | Access |
|----------|--------|
| Current directory | Read-write |
| Network | Allowed |
| GPU (NVIDIA) | Allowed |
| `~/.config/gh/` | Read-only |
| `~/.julia/` | Read-write |
| Julia binaries | Read-only |
| **Everything else** | **Blocked** |

Blocked: `~/.ssh`, `~/.aws`, `~/.config` (except gh), other directories, host environment variables.

## Installation

1. Clone this repo anywhere you like:
   ```bash
   git clone git@github.com:nathanaelbosch/claude-sandbox.git
   cd claude-sandbox
   ```

2. Run the install script:
   ```bash
   ./install.sh
   ```

   Or install manually:
   ```bash
   mkdir -p ~/.local/share/claude-sandbox ~/.local/bin
   ln -sf "$(pwd)/claude-sandbox" ~/.local/share/claude-sandbox/claude-sandbox
   ln -sf "$(pwd)/claude-sandbox.def" ~/.local/share/claude-sandbox/claude-sandbox.def
   ln -sf ~/.local/share/claude-sandbox/claude-sandbox ~/.local/bin/claude-sandbox
   ```

3. Build the container:
   ```bash
   claude-sandbox --build
   ```

## Usage

```bash
claude-sandbox              # Start Claude Code in sandbox
claude-sandbox --help       # Show help
claude-sandbox --build      # Build/rebuild container
```

## Features

- **Node.js 22** for Claude Code
- **Python 3.11** with `uv` package manager
- **Julia** auto-detected and bind-mounted from host
- **GitHub CLI** with read-only credential passthrough
- **Git** with author/email passed via environment variables

## Python Virtual Environments

The sandbox uses separate venvs from the host to avoid conflicts:
- Host: `.venv/` (default)
- Container: `.venv-sandbox/` (via `UV_PROJECT_ENVIRONMENT`)

Add to your global gitignore:
```bash
echo ".venv-sandbox/" >> ~/.config/git/ignore
```

## Persistence

Container home is persisted at `~/.claude-sandbox-home/`, preserving:
- Claude credentials
- Shell history
- uv tools
- npm globals
