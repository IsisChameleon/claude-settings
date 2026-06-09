# claude-settings

Personal [Claude Code](https://code.claude.com/docs/en/overview.md) configuration — skills, subagents, plugins, hooks, and guidance — synced across machines.

## Setup

Clone into your Claude config directory:

```bash
git clone https://github.com/IsisChameleon/claude-settings.git ~/.claude
cd ~/.claude
```

If `~/.claude` already exists with local data, merge or symlink the repo contents instead.

**Environment:** macOS, zsh, nvm for Node, pnpm for JS/TS, uv for Python.

---

## What this setup provides

Quick map of everything configured here. Each section below has the details.

| Type | What it is | Count |
|------|-----------|-------|
| [Skills](#skills) | On-demand instruction packs Claude loads to do a specific task | 6 local |
| [Subagents](#subagents) | Specialized agents Claude can delegate work to | 2 local |
| [Slash commands](#slash-commands) | Custom `/commands` you type | 1 |
| [Plugins](#plugins) | Bundles of skills/commands installed from marketplaces | 4 user + 2 project |
| [Hooks](#hooks) | Scripts the harness runs automatically on events | 1 |
| [Status line](#status-line) | Custom terminal status bar | 1 |
| [Guidance files](#guidance-files) | `CLAUDE.md` instructions Claude always follows | 2 |
| [MCP servers](#mcp-servers) | External tool integrations (configured outside this repo) | — |

---

## Skills

Local skills live in [`skills/`](skills/). Each is a folder with a `SKILL.md` that Claude loads on demand when the task matches. → [Skills docs](https://code.claude.com/docs/en/skills.md)

| Skill | What it does | Source |
|-------|--------------|--------|
| **worktree-manager** | Create, validate, and clean up git worktrees with Claude agents across projects; manages a global registry and the local dev stack (start/stop). | [`skills/worktree-manager/`](skills/worktree-manager/) |
| **pr-submit** | Create and submit a GitHub PR from the current branch, then watch CI checks and only report done once they pass. | [`skills/pr-submit/SKILL.md`](skills/pr-submit/SKILL.md) |
| **pr-description** | Update an existing GitHub PR's description with a summary of the changes. | [`skills/pr-description/SKILL.md`](skills/pr-description/SKILL.md) |
| **review-pr-comments** | Pull all comments on a GitHub PR and turn them into an actionable analysis. | [`skills/review-pr-comments/SKILL.md`](skills/review-pr-comments/SKILL.md) |
| **start-excalidraw** | Start the Excalidraw MCP canvas on `localhost:3333` for drawing diagrams. | [`skills/start-excalidraw/SKILL.md`](skills/start-excalidraw/SKILL.md) |
| **html-architecture-diagrams** | Generate architecture / system / flow diagrams as a designed standalone HTML page (rather than mermaid/excalidraw-style output). | [`skills/html-architecture-diagrams/`](skills/html-architecture-diagrams/) |

> Many more skills are available at runtime via the [plugins](#plugins) below (e.g. `superpowers:*`, `slack:*`, `Notion:*`).

---

## Subagents

Specialized agents defined in [`agents/`](agents/) that Claude can delegate to. → [Subagents docs](https://code.claude.com/docs/en/sub-agents.md)

| Subagent | What it's for | Source |
|----------|---------------|--------|
| **senior-react-nextjs-frontend** | React / Next.js (App or Pages Router) front-end work on Vercel + Tailwind + shadcn-ui: components, RSC/Suspense data fetching, route handlers, middleware, perf, a11y. | [`agents/senior-react-nextjs-frontend.md`](agents/senior-react-nextjs-frontend.md) |
| **senior-svelte-frontend** | Svelte / SvelteKit + Tailwind front-end work: components, UX patterns, responsive design, accessibility, performance. | [`agents/senior-svelte-frontend.md`](agents/senior-svelte-frontend.md) |

Claude Code also ships **built-in** subagents (`general-purpose`, `Explore`, `Plan`, `statusline-setup`) that need no configuration.

---

## Slash commands

Custom commands in [`commands/`](commands/), invoked by typing `/name`. → [Slash commands docs](https://code.claude.com/docs/en/commands.md)

| Command | What it does | Source |
|---------|--------------|--------|
| **/copy2** | Copy Claude's most recent response to the system clipboard as clean text. | [`commands/copy2.md`](commands/copy2.md) |

---

## Plugins

Installed from marketplaces; each bundles skills and/or commands. Enabled plugins are listed in [`settings.json`](settings.json) under `enabledPlugins`. → [Plugins docs](https://code.claude.com/docs/en/plugins.md) · [Marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces.md)

### User-scoped (always on)

| Plugin | What it provides | Installation source |
|--------|------------------|---------------------|
| **superpowers** | Large workflow-skill library: brainstorming, test-driven development, systematic debugging, writing/executing plans, git worktrees, parallel agents, and code-review rituals. | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) |
| **frontend-design** | Generates distinctive, production-grade frontend UIs that avoid generic "AI-looking" output. | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) |
| **slack** | Slack skills: channel digests, search, draft announcements, standup generation, channel summaries. | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) |
| **notion-workspace-plugin** | Notion automation: create/query pages and databases, manage tasks, search the workspace. | [makenotion/claude-code-notion-plugin](https://github.com/makenotion/claude-code-notion-plugin) |

### Project-scoped

| Plugin | Project | What it provides | Installation source |
|--------|---------|------------------|---------------------|
| **codex** | `~/src/readme` | OpenAI Codex integration. | [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) |
| **qz-knowledge-pack** | `~/src/toocan-app` | Quarterzip internal knowledge/skill pack. | quarterzip/toocan-app (private) |

> Marketplace registry and cloned plugin content under `plugins/` are machine-specific and [git-ignored](#ignored-runtime-data).

---

## Hooks

Scripts the harness runs automatically on tool events, configured in [`settings.json`](settings.json). → [Hooks docs](https://code.claude.com/docs/en/hooks-guide.md)

| Hook | Trigger | What it does | Source |
|------|---------|--------------|--------|
| **block-commit-on-main** | `PreToolUse` on `git commit` | Blocks committing directly to `main`, enforcing the feature-branch workflow. | [`hooks/block-commit-on-main.sh`](hooks/block-commit-on-main.sh) |

---

## Status line

Custom terminal status bar showing git branch and token usage. → [Status line docs](https://code.claude.com/docs/en/statusline.md)

- [`statusline-command.sh`](statusline-command.sh) — wired up via `statusLine` in [`settings.json`](settings.json).

---

## Guidance files

Markdown instructions Claude reads as standing rules.

| File | Scope |
|------|-------|
| [`CLAUDE.md`](CLAUDE.md) | Global guidance: investigation discipline, coding/testing standards, git & PR workflow, environment, credential isolation. |
| [`CLAUDE-toocan-app.md`](CLAUDE-toocan-app.md) | Project-specific guidance for `toocan-app`. |

Settings reference: [settings.json docs](https://code.claude.com/docs/en/settings.md).

---

## MCP servers

[Model Context Protocol](https://code.claude.com/docs/en/mcp.md) servers add external tool integrations (Notion, Slack, Linear, Gmail/Calendar/Drive, PostHog, Excalidraw, context7, voice-testing, Quarterzip, etc.). These are configured in `~/.claude.json`, which is **machine-specific and not tracked in this repo**.

---

## Ignored (runtime data)

Session history, caches, debug output, the worktree registry, server-pushed policy cache, and cloned plugin content are excluded via [`.gitignore`](.gitignore) and stay local to each machine.
