# claude-settings

Personal Claude Code (Cursor) configuration and skills, synced across machines.

## Setup

Clone into your Claude config directory:

```bash
git clone https://github.com/IsisChameleon/claude-settings.git ~/.claude
cd ~/.claude
```

If `~/.claude` already exists with local data, merge or symlink the repo contents instead.

## Contents

| Path | Description |
|------|-------------|
| `CLAUDE.md` | Global guidance for Claude Code (code style, env, package managers) |
| `CLAUDE-toocan-app.md` | Project-specific guidance for toocan-app |
| `settings.json` | Cursor permissions, model preferences |
| `statusline-command.sh` | Status line script (git branch, token usage) |
| `worktree-toocan-app.json` | Worktree config for toocan-app (ports, docker compose) |
| `agents/` | Agent definitions (e.g. senior-svelte-frontend) |
| `skills/` | Installed skills (worktree-manager, memory-profiling, etc.) |
| `plugins/known_marketplaces.json` | Plugin marketplace metadata |

## Ignored (runtime data)

Session history, cache, debug output, worktree registry, and cloned plugin content are excluded via `.gitignore` and remain local.

## Environment

Target: macOS, zsh, nvm for Node, pnpm for JS/TS, uv for Python.
