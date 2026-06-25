# Memory Index

Global memories — rules, gotchas, and requirements. One line per memory.

- [Always cite evidence — be scientific](always-cite-evidence.md) — every factual claim needs a clickable reference a reviewer can verify
- [Scan for sibling bugs after fixing one](scan-for-sibling-bugs.md) — after a fix, grep for the same mistaken pattern elsewhere before declaring done
- [Validate design assumptions before coding](validate-design-assumptions.md) — list falsifiable assumptions + a concrete validation step before implementing
- [Fix the pattern, not the detail](fix-the-pattern-not-the-detail.md) — when a root cause is a design/config smell, name the canonical pattern instead of stacking patch-variants; 2+ band-aids with tradeoffs = you missed the principle
- [Feature flag implementation patterns](feature-flags.md) — keep the old code path untouched; duplication between old/new paths is acceptable
- [Pipecat framework notes](pipecat.md) — `push_frame` vs `queue_frame` and other Pipecat pipeline behavior
- [toocan-app ↔ k8s-apps relationship](toocan-app-k8s-apps-relationship.md) — app-repo ↔ GitOps deploy-repo pair, coupled by container image name+tag (toocan/{server,client}), deployed via `qz deploy` + ArgoCD
- [Don't rewrite git history](feedback_no_rewrite_history.md) — prefer `git merge origin/main` over rebase; never force-push a PR branch; "rebase off main" means merge unless explicitly told otherwise
