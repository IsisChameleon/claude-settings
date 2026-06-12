# Memory Index

Global memories — rules, gotchas, and requirements. One line per memory.

- [Always cite evidence — be scientific](always-cite-evidence.md) — every factual claim needs a clickable reference a reviewer can verify
- [Scan for sibling bugs after fixing one](scan-for-sibling-bugs.md) — after a fix, grep for the same mistaken pattern elsewhere before declaring done
- [Validate design assumptions before coding](validate-design-assumptions.md) — list falsifiable assumptions + a concrete validation step before implementing
- [Feature flag implementation patterns](feature-flags.md) — keep the old code path untouched; duplication between old/new paths is acceptable
- [Pipecat framework notes](pipecat.md) — `push_frame` vs `queue_frame` and other Pipecat pipeline behavior
