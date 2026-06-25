# Fix the pattern, not the detail

When a bug's root cause is a **design or config smell** (not a typo), stop before proposing a fix and answer out loud:

> *What is the canonical pattern for this class of problem? Is this code fighting a framework convention or default? What change makes the whole class of bug impossible — not just this instance?*

Lead with that pattern-level fix, its tradeoffs, and a recommendation. Mention any local patch only as an explicit fallback.

## Triggers — escalate to pattern level when any fire

1. The fix forces a **tradeoff between two valid contexts** (host vs prod, web vs SDK, create vs duplicate). The value/logic is probably in the wrong *layer*.
2. You're about to present **2+ variants of the same patch**. That's the tell you haven't found the principle yet.
3. A **comment or assumption asserting "this can't happen / isn't used"** turns out false. The design is fragile, not just buggy.
4. The same file/setting has **caused confusion more than once**.

## Gate — do NOT over-apply

For a genuine one-liner — typo, off-by-one, missing `await`, simple rename — just fix it. This escalation is only for root causes that are design/config smells.

## Why

The `.env` / `SUPABASE_URL` bug (June 2026): the bot couldn't load books because `load_dotenv(override=True)` (pipecat's runner + ours) clobbered the compose-provided `SUPABASE_URL` with a host value from `server/.env`, breaking Supabase calls inside the container.

I kept offering variants of the same band-aid — "comment the line" / "set it to the kong host" / "add `.env.host`" — each carrying a host-vs-container tradeoff. **Three patch-options that all leave a tradeoff was the signal I'd missed the principle.** The user had to ask "should the bot even load `.env`?" and "how do others do it?" before I named the actual pattern:

- **12-factor**: config comes from the environment, not files; deployed platforms inject env vars.
- `.env` is a **localhost gap-filler**, loaded with `override=False` (never overrides platform/compose env).
- **Wiring values get local-dev defaults in code** (`SUPABASE_URL` defaults to `http://127.0.0.1:54321` in settings), so host runs need no env var and `.env` shrinks to secrets only.

That removed the whole class of bug (container, dev/prod, and host scripts all correct with zero friction). The patches would only have moved the pain around. Those "should we even…?" and "isn't there a better way?" questions are the ones to ask *myself* before proposing anything.

Related: [[validate-design-assumptions]], [[scan-for-sibling-bugs]], [[always-cite-evidence]].
