# Worktree Manager Skill Notes

This file contains notes specific to the worktree manager skill execution.

## Agent Launching

When launching agents in Ghostty, use zsh (not fish):

```bash
open -na "Ghostty.app" --args -e zsh -c "cd '$WORKTREE_PATH' && exec claude"
```

## Dependency Installation

Before running `pnpm install`, ensure correct Node version:

```bash
nvm use 24.13.0
```

## Worktree Storage

- **Base path**: `~/tmp/worktrees/<project>/<branch-slug>/`
- **Registry**: `~/.claude/worktree-registry.json`

## Visual Differentiation

Each worktree gets automatic visual styling:

- **Color assignment**: yellow, red, green, blue, purple (cycles)
- **Index number**: [1], [2], [3], etc.
- **Ghostty background tint**: Dark tinted background based on color
- **Tab title**: Shows `[N] branch-name` (e.g., "[1] isabelle/fix-agent")
- **Shell prompt**: Colored prompt prefix with index number

Colors are assigned automatically when registering worktrees and stored in the registry.
