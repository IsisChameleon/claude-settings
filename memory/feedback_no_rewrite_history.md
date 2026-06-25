---
name: feedback-no-rewrite-history
description: User dislikes rewriting git history — prefer merge over rebase, never force-push shared branches
metadata:
  type: feedback
---

The user does not like rewriting git history. Integrate `main` into a feature
branch with `git merge origin/main`, NOT `git rebase`. Never force-push a branch
that has an open PR.

**Why:** Rewriting published history on a shared/PR branch is destructive, breaks
others' checkouts, and obscures the real timeline. The user explicitly stated
this preference (2026-06-21, on PR #146 in the readme repo).

**How to apply:** When asked to "rebase off main" or "get up to date with main,"
interpret it as `git fetch origin main && git merge origin/main` (a merge commit
is fine). Only rebase/force-push if the user explicitly asks for it in that
specific instance. Aligns with the global rule to never run destructive git
commands without approval.
