# Worktree Manager Skill Notes

## Configuration

All local settings (worktree base path, terminal, shell, node version) are defined in the user's local config file. **Always read config before any operation. Never assume paths or settings.**

**Config resolution order (local overrides defaults):**
1. `~/.claude/worktree-local.json` (per-user overrides)
2. `config.defaults.json` in this skill directory (shared defaults)

Merge: local values take precedence. Missing local keys fall back to defaults.

## Visual Differentiation

Each worktree gets automatic visual styling:

- **Color assignment**: yellow, red, green, blue, purple (cycles)
- **Index number**: [1], [2], [3], etc.
- **Terminal background tint**: Dark tinted background based on color
- **Tab title**: Shows `[N] branch-name` (e.g., "[1] isabelle/fix-agent")
- **Shell prompt**: Colored prompt prefix with index number

Colors are assigned automatically when registering worktrees and stored in the registry.
