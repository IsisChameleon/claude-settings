# Worktree Manager

A Claude Code skill for managing parallel development using git worktrees. Each worktree is an isolated copy of a repo on a different branch, with its own ports, Docker containers, and Claude Code agent.

## Quick Start

1. Install the skill in `~/.claude/skills/worktree-manager/`
2. Run `/worktree-manager` in Claude Code - it will guide you through first-time setup
3. Or create your config manually (see below)

## Setup

Create `~/.claude/worktree-local.json` with your preferences:

```json
{
  "terminal": "ghostty",
  "shell": "zsh",
  "nodeVersion": null,
  "worktreeBase": "~/tmp/worktrees"
}
```

Only include keys you want to override. All other settings fall back to `config.defaults.json`.

### Available Settings

| Key | Default | Description |
|-----|---------|-------------|
| `terminal` | `ghostty` | Terminal to launch agents (`ghostty`, `iterm2`, `tmux`, `tabby`, `wezterm`, `kitty`, `alacritty`) |
| `shell` | `zsh` | Shell to use in launched terminals |
| `nodeVersion` | `null` | Node.js version to activate via nvm (null = skip) |
| `claudeCommand` | `claude` | Command to launch Claude Code |
| `worktreeBase` | `~/tmp/worktrees` | Base directory for all worktrees |
| `registryPath` | `~/.claude/worktree-registry.json` | Path to the global worktree registry |
| `portPool.start` | `8100` | First port in allocation pool |
| `portPool.end` | `8199` | Last port in allocation pool |
| `portsPerWorktree` | `2` | Number of ports per worktree |
| `defaultCopyDirs` | `[".agents", ".env.example", ".env"]` | Files/dirs to copy into new worktrees |
| `healthCheckTimeout` | `30` | Seconds to wait for health checks |
| `healthCheckRetries` | `6` | Number of health check retries |

## Usage

```
/worktree-manager create feature/my-branch
/worktree-manager status
/worktree-manager cleanup project-name feature/my-branch
```

## Per-Project Config (Optional)

Projects can provide `.claude/worktree.json` for custom Docker Compose commands, health checks, port mappings, and cleanup steps. See `templates/worktree.json` for the schema.

## File Layout

```
~/.claude/
├── worktree-local.json              # Your local config (create this)
├── worktree-registry.json           # Runtime state (auto-managed)
└── skills/worktree-manager/
    ├── SKILL.md                     # Skill instructions (for Claude)
    ├── CLAUDE.md                    # Skill context notes (for Claude)
    ├── config.defaults.json         # Shared defaults (don't edit)
    ├── README.md                    # This file (for humans)
    ├── scripts/                     # Helper scripts
    └── templates/                   # Config templates
```

## Permissions

This skill uses `allowed-tools` in SKILL.md to auto-approve tool usage during skill execution. No manual permission setup is needed for basic worktree operations.

For general git/docker commands outside the skill, you may want to add these to your `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(git worktree:*)",
      "Bash(docker compose:*)",
      "Bash(docker ps:*)"
    ]
  }
}
```
