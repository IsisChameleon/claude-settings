# CLAUDE.md

This file provides general guidance to Claude Code (claude.ai/code).

## System Environment

- **Shell**: zsh (macOS default) - fish is NOT installed
- **Terminal**: Ghostty, Tabby
- **Platform**: macOS Darwin

## Node.js Version Management

This system uses **nvm** for Node version management. The shell is configured to automatically use the correct Node version, so no manual nvm activation is needed.

## Cursor Rules

**IMPORTANT**: When working in any project, check for and read `.cursor/rules/*.mdc` files if they exist. These contain project-specific coding standards that MUST be followed.

Common rule files:
- `workflow.mdc` - Development workflow requirements
- `standards.mdc` - General coding guidelines
- `svelte.mdc` - Svelte/frontend conventions
- `typescript.mdc` - TypeScript/testing patterns

## Code Style Preferences

### General
- Arrow functions ONLY: `const fn = () => {}`
- Always use `await`, never `.then()`
- Avoid nested code - use early returns
- Max 200 lines per file preferred
- Clean up unused code completely

### Early Returns Pattern
```typescript
// GOOD: Flat code with early returns
if (error) {
  console.error(error);
  return;
}
// main logic here

// BAD: Nested code
if (!error) {
  // main logic here
}
```

## Package Managers

| Project Type | Package Manager | Install Command |
|--------------|-----------------|-----------------|
| Node.js/TypeScript | pnpm | `pnpm install` |
| Python | uv | `uv sync` |

## Searching Past Conversations
- Claude Code stores conversation history in `~/.claude/`. The main transcript log is `history.jsonl`, and per-project session transcripts (JSONL files) live under `projects/<encoded-project-path>/`. You can grep these files to find past conversations, tool calls, code snippets, or decisions from previous sessions.

## MCP Servers
When adding MCP servers, mention `--scope user` for global availability.

## Quality Checks

Always run quality checks before committing:

**Frontend (SvelteKit)**:
```bash
cd client
pnpm github-checks  # lint + test + types
```

**Backend (Python)**:
```bash
cd server
ruff check && ruff format && pytest
```
