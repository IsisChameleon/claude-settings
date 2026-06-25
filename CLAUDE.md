# CLAUDE.md

This file provides general guidance to Claude Code (claude.ai/code).

## Local Development

- If a project has a docker compose stack (or equivalent), use it to start services. Do NOT start ad-hoc dev servers (`next dev`, `pnpm dev`, `uvicorn`, etc.) when the project's convention is to run via docker.
- When testing a change that requires the stack to be up and the project has a local docker compose stack, always restart the docker stack after config changes rather than testing against running ports. The stack might otherwise be running against another worktree.
- Before debugging build/lint failures, check for stale caches (`.next`, `node_modules`, `.svelte-kit`, `__pycache__`) and missing dev deps (e.g., vitest) before deep-diving into infrastructure (lefthook, pre-commit hooks, venv setup).

## Investigation Discipline

- Do not speculate about root causes. Add logs, read source, or check docs to verify a hypothesis BEFORE applying fixes.
- Do not state guesses or hypothesis as fact. Work like a scientific. Identify and verify assumptions, using a test script, researching the documentation, providing references.
- Never run destructive commands (`git reset --hard`, force-push, `rm -rf`, worktree deletion) without explicitly proposing them first and waiting for approval.
- When the user asks a direct question, answer it directly; do not launch exploratory bash commands or clarifying-question dialogues unless the question is truly ambiguous.

## Coding Discipline

Bias toward caution over speed. For trivial tasks, use judgment — otherwise default to:

- **Surface assumptions before coding.** If multiple interpretations of the request exist, present them — don't pick silently. If a simpler approach exists, say so and push back when warranted. If something is unclear, name what's confusing and ask. Don't hide confusion under code.
- **Simplicity first — minimum code that solves the problem.** No features, abstractions, configurability, or error handling beyond what was asked. Single-use code doesn't need a generic interface. If you wrote 200 lines and it could be 50, rewrite it. Sanity check: "would a senior engineer say this is overcomplicated?"
- **Surgical changes — every changed line should trace to the request.** Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing style even if you'd write it differently. If you spot unrelated dead code, mention it — don't delete it. Only remove orphans (imports/vars/functions) that YOUR changes made unused.
- **Define verifiable success before starting.** Convert vague asks into checkable goals:
  - "Add validation" → write tests for invalid inputs, then make them pass.
  - "Fix the bug" → write a test that reproduces it, then make it pass.
  - "Refactor X" → ensure tests pass before AND after.

  For multi-step tasks, state a brief plan with a verify step per item. Strong success criteria let you loop independently; weak ones ("make it work") require constant clarification.

- **Parallel flows are the bug factory — collapse them when you can.** When the same field or logic exists in sibling code paths (create/duplicate, web/SDK, multiple transports), first try extracting the shared piece so there is one place to change. If they must stay parallel: grep for the field before editing, and update every flow in the same change — per-flow tests cannot catch the drift, because each flow stays internally consistent.
- **Fix the pattern, not the detail.** When a root cause is a design/config smell (not a typo), name the canonical pattern before proposing a fix: *what's the standard pattern for this class of problem, is this code fighting a framework convention/default, what change makes the whole class of bug impossible?* Lead with that; offer a local patch only as an explicit fallback. **Tells you've missed the principle:** the fix forces a tradeoff between two valid contexts (host vs prod, web vs SDK); you're about to present 2+ variants of the same patch; a comment asserting "this can't happen" turns out false; the same setting has confused us before. Gate: for a genuine one-liner (typo, off-by-one, missing `await`), just fix it — don't pontificate. See `~/.claude/memory/fix-the-pattern-not-the-detail.md`.

Source: Karpathy on common LLM coding pitfalls — https://x.com/karpathy/status/2015883857489522876

## Reporting to the user

Report the result of your coding or investigation to the user in plain english, with code snippets or doc extracts when required so that the user does not need to go and look the files /docs but still can follow your argument. Do not use unnecessary jargon. Like in a scientific paper, link your references (be in code paht+line or documentation links) using [1] etc.. in your response and adding the references links at the ned.

## Git & PR Workflow

- Never commit directly to `main`. Always create a feature branch first, even for small changes.
- Before resolving merge conflicts, check whether `main` already contains the branch's changes (`git log main..HEAD`) and consider a fresh-branch cherry-pick instead of manual conflict resolution.
- Keep wrap-up summaries brief; the user often has follow-up requests.

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

Always adhere to the codebase patterns in the current repo. If it doesn't seem like the right choice for your task, just ASK the user - and if the user specifically asked not to be interrupted use your best judgment and surface the decision in your report to the user.

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

## Memory Location

- Write global memories (rules, gotchas, requirements) to the top-level `~/.claude/memory/` directory — this is tracked in git. Do NOT write them to `projects/-Users-isabelleredactive--claude/memory/`; that path is under the gitignored `projects/` tree and will never be committed, even though the harness memory instructions point there.
- The curated global memories and their `MEMORY.md` index live in `~/.claude/memory/`.

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

## Testing Discipline

- **Mock at external boundaries, not at internal abstractions.** Mock the network client (Firestore, HTTP, Daily, S3), the filesystem, time/UUID generation, and LLM/AI calls. Do NOT mock our own data-access classes (`SomeRef.get`, `Repository.get`, service-layer methods) when testing the code that calls them — the production code path through your own abstractions must still execute, or bugs inside them go undetected. Use the project's `tests/fakes/` (or equivalent) for in-memory stand-ins that preserve real serialization/deserialization semantics.
- **When adding a field to a model that round-trips through storage, extend the deserializer AND its test in the same change.** Pydantic-style defaults (usually `None`) silently hide a missing field in the deserializer — no validation error fires. The test must assert the new field round-trips through a snapshot/dict.
- **Setter/getter pairs need a round-trip test through the production API**, not through dedicated single-field helpers. The bug-revealing test is: write via the prod setter into a fake store, read back via the prod getter (the API the rest of the code actually uses), and assert the values match.
- **Trace the full data flow before claiming "done".** Read the code path from entry-point to final output — actor or route handler → data layer → consumers → rendered prompt or response body. Verify each layer actually uses the value the previous one produced; a single ignored field or default-to-empty mid-flow silently degrades the feature even when every unit test passes. For prompt/UI features, render the final output and inspect it. For data features, point to the write line, the read line, and every consumer that uses the deserialized value.
- **Implicit defaults can mask missing wiring.** `field: str = ""` lets every caller silently produce a degraded result. Prefer required parameters or no-default fields when a value is essential to the feature; reserve defaults for cases where "empty" is a legitimate state, not a synonym for "I forgot."
- **`mock.patch` targets where the name is used, not where it's defined.** `from pkg.utils import fn` copies the reference into the importing module; patching `pkg.utils.fn` rebinds the original but the copy still points at the real function — the patch applies without error and the real dependency keeps running. Patch the using module's attribute.
- **Use `MagicMock(spec=Cls)` whenever production code runs `isinstance()` on the mocked object.** A bare `MagicMock` is an instance of nothing: the check returns False, production code silently takes the other branch, and the test passes while exercising a path the real object never takes.

## Async Python

- **A coroutine's body does not execute until awaited.** Calling an async function without `await` builds a coroutine object and discards it — nothing runs, no error, just a "never awaited" warning in logs nobody reads. With async SDK clients (Firestore `AsyncClient`, httpx), an un-awaited write silently doesn't happen.
- **Never call synchronous network-bound functions inside `async def`.** The event loop runs every request on one thread — one blocking call freezes all in-flight requests, works fine in dev, and degrades the whole service under load. Use `await asyncio.to_thread(...)` or the async client.

## API Boundaries (FastAPI/Pydantic)

- **Declare typed params (`datetime`, enums) and let the framework parse — never accept `str` and parse by hand.** Hand-parsing turns malformed input into an unhandled exception → 500, where the declared type gives a 422 with a field-level message, and the type flows into the OpenAPI schema (and any generated client SDK).

## Frontend A11y

- **Animated show/hide keeps the element mounted — and focusable.** Elements hidden by CSS (`translate-x-full`, `opacity-0`) stay in the focus order and accessibility tree; Tab lands on invisible controls and screen readers announce them. Pair the hiding class with `inert={!visible}` driven by the same boolean.

## Defensive Code — Earn the Raise

Before adding a validator, assertion, `raise`, or guard, run this gate:

1. **Cost:** does the check add code, branches, or failure modes the reader has to track? (Almost always yes.)
2. **Benefit:** if the check is absent and the bad state occurs, does something *actually awful* happen — data corruption, security hole, silent wrong answer, crashed user flow? Or just a cosmetic glitch, a slightly weird log line, a degraded-but-correct output?
3. **Likelihood:** how plausible is the bad state in practice given the producers? LLM structured output with a clear schema + clear prompt? Internal code paths with strong types? Very low likelihood lowers the benefit further.

If **cost = yes** and **awful = no**, **do not add the check**. Let the value flow through; the system tolerates it.

Validators on a model are especially expensive because they raise from anywhere the model is constructed — including deserialization on read. A single bad row poisons every read for that key. The blast radius is almost always wider than the bug it catches.

If you are unsure whether the failure mode is awful, **ask** — don't default to defensive.

This is the *spirit* of "no error handling for scenarios that can't happen" in the system prompt, restated: validate at real system boundaries (untrusted user input, external APIs); trust the inside.

## Quality Checks

Always run quality checks before committing, check repo specific quality checks.
