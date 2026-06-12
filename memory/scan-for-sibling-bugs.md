# Scan for sibling bugs after fixing one

When fixing a bug, **before declaring done**, scan the codebase for other instances of the same mistaken pattern. The same wrong assumption usually shows up in more than one place.

## What to look for

Once you've identified the root pattern of a bug (e.g. "this code reads from a buffer that's shared with another producer"), grep for:

- The same call site shape elsewhere (e.g. other consumers of the same buffer / queue / state).
- The same library API used in the same wrong way.
- The same race-condition pattern (read-then-write, check-then-act, two producers same store).
- The same data being persisted / serialized / passed to user-visible surface from a stale or polluted source.

Then ask: does this site have the same failure mode? If the original bug was caused by N preconditions, check whether all N hold here too.

If yes — fix it in the same change, or at minimum log the sibling and surface it to the user before declaring the original bug closed.

## Why

Resume-reading bug, May 2026:
- Primary bug: state_manager pulled an anchor from a downstream tracker at resume time. The tracker had been clobbered by Q&A chitchat, so the anchor was wrong.
- **Sibling that shipped unnoticed**: `bot.py` disconnect handler called `library.save_progress(sentence_anchor=position_tracker.get_anchor())` — same shape (read live tracker, persist), same failure mode (live buffer holds chitchat at disconnect time after a Q&A interrupt). The user had to point it out: "Secondly, I'm suspecting on_client_disconnect library.save_progress suffers from the same problem as the one we just had in the Live call."
- A 30-second grep for `tracker.get_anchor()` after diagnosing the primary bug would have caught the sibling immediately. Not doing that scan meant we shipped half a fix.

## How to apply

After you understand the root pattern of a bug:

1. **Name the pattern in one sentence**: "Reading X from a shared/live buffer when X needs to reflect a specific past moment, not the current moment."
2. **Grep / search for that pattern**: usually `grep -rn "<the suspect API call>"` plus a manual scan of nearby callers and any persistence / save / serialize / event-handler boundaries.
3. **Audit each match** against the same preconditions. Most won't apply; some will.
4. **Either fix in the same change, or call out explicitly** to the user before claiming the bug is closed.

This step takes 1–5 minutes and prevents the user from having to point out obvious siblings — which erodes trust in the fix and forces another round-trip.

## When this applies

Every non-trivial bug fix. Skip only for typo fixes or one-call-site dead code removal.

A specific trigger: any bug where the root cause involves **timing, shared state, persistence, or event ordering** is virtually guaranteed to have siblings worth checking.
