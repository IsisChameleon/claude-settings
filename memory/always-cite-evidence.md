# Always cite evidence — be scientific

**Every factual claim needs a clickable reference a reviewer can verify.** No bare assertions about how a library behaves, what a service returns, what a log shows, or what an internal function does — link to the evidence, every time. Memory of how something works is a hypothesis until cited.

## The reference types

- **Our own code** → `path/to/file.py:LINE`, or a GitHub permalink to a pinned SHA when posting outside the repo.
- **External library / SDK / service** → GitHub permalink at a pinned tag or SHA: `https://github.com/<repo>/blob/<tag>/<path>#L<line>`. Cite the upstream docstring or implementation, not your recall of it.
- **Runtime behavior in prod** → log excerpt with timestamp + groupId, or a direct GCP / Linear / Slack URL.
- **Documented behavior** → docs URL anchored to the section.
- **PostHog / dashboards / analytics tools** → the full app URL as a markdown link, e.g. `[insight](https://us.posthog.com/project/<id>/insights/<short_id>)` or `/dashboard/<id>`. Surface any `*url` field a tool returns verbatim. An ad-hoc query run this session is NOT a citable reference — inline the SQL/query so it's reproducible, or say "ad-hoc query, this session."

## Every reference must be a clickable link — never bare text

A reference is only useful if the reviewer can click it. `file.py:line` (editor-jumpable), a GitHub permalink, a full PostHog/GCP/Linear/docs URL — all fine. A bare string like "PostHog Dev — events table (this session)" or a plain insight name is NOT a reference; it's an unverifiable assertion wearing a `[1]` badge. If you cannot produce a link, either inline the evidence (the query, the log line) or say so plainly.

## When this applies

Everywhere — not just in formal write-ups. PR descriptions, Linear comments, Slack replies, conversation answers about how something works, design docs, debugging hypotheses. Whenever you are about to state a fact, ask:

> Can a reviewer click to verify this?

If no — pause and find the citation before posting. If you genuinely cannot find one, say so explicitly ("Cannot derive — <reason>") rather than asserting.

## Why

PRO-1130 through PRO-1134 (May 2026 prod-errors batch) shipped a wave of PR bodies and Linear comments asserting library behavior — "dramatiq stores `actor.options` verbatim", "Firebase rejects with `UNAUTHORIZED_DOMAIN`", "Daily redelivers the webhook ~35s later" — with zero clickable citations. A reviewer asked "what does this blurb even mean? Can you link the dramatiq source?" — exposing that the analysis was unverifiable from the diff alone.

The fix in that case was real, but the prose read like trust-me confidence instead of evidence. Citations would have:
- Forced the author to actually read the source instead of relying on training-data recall (which is sometimes wrong).
- Turned the PR description from prose into auditable evidence.
- Made the review take 30 seconds instead of "what does that blurb mean?"

## How to apply

- About to write "X library does Y"? Go to that library's GitHub, find the line, link it at a pinned tag/SHA.
- About to paste a log claim? Include the timestamp + groupId + URL.
- About to reference internal code? Use `file.py:line` format that the editor can jump to.
- Citing dramatiq, redis-py, Firebase, Daily, Pipecat, FastAPI — same standard. No "I'm sure this is how it works."
- The same standard applies to subagents you dispatch. Brief them with "cite by permalink" upfront.

Related: this generalizes the existing `feedback_prod_errors_slack_substance` rule (code excerpt + factual customer impact for Slack replies) to every surface you produce evidence on.
