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

## Plan Mode

When creating a plan, name the markdown file descriptively based on the task (e.g., `add-user-auth.md`, `fix-login-bug.md`, `refactor-api-routes.md`) instead of using a random generated name.

## MCP Servers
When adding MCP servers, mention `--scope user` for global availability.

## Credential Isolation — HARD RULE

**Never cross-share API keys, tokens, or any credentials between repos.**

When working on a task for a specific repo, only use credentials from that repo's own `.env` / config files. If a credential is missing, broken, out of credits, expired, or otherwise failing:

1. **STOP.** Tell the user the credential failed and wait for them to fix it.
2. **Never** search other directories, other repos, or `~/src/*` for a substitute key.
3. **Never** "fall back" to a working key from another project, even if it would unblock the task.

Other repos may be referenced for **code patterns and information only** — read source files freely to understand patterns, but do not read or use `.env`, `secrets/`, service-account JSON, or any credential files from those repos.

**Why this matters:** Different repos belong to different contexts — work vs personal, different clients, different billing owners. Using a work API key for a personal project (or vice versa) mis-attributes spend, can violate employer policy, and can leak personal activity into work logs. For example: `~/src/toocan-app/` is a work project; `~/tmp/worktrees/readme/` and similar personal projects must NEVER share its credentials.

**When dispatching subagents:** explicitly instruct them in the brief to only load credentials from the current repo's own config. If the key fails, the subagent must stop and report — not auto-fallback.

This rule applies to: API keys, OAuth tokens, service-account JSON, database URLs with embedded passwords, webhook secrets, JWT signing keys, and any other form of credential.

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
