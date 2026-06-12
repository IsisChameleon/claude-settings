# Feature Flag Implementation Patterns


## Keep the old code path completely untouched
- Don't extract shared helpers (e.g. a mapper function) between old and new paths just to reduce duplication.
- The old path should remain identical to how it was before the FF was added — makes it trivial to verify no regressions and easy to delete later.
- Duplication between old/new paths is acceptable and expected.

## Place the FF check as upstream as possible with early return
```python
if not ff_enabled:
    # old code, untouched
    return

# new code
```
- Shared setup (e.g. fetching data, building common inputs) stays above the FF check.
- The FF gate goes right after shared setup, with the old path returning early.

## Specific to project toocan-app (or any of its worktrees)
- The feature flag is a config in toocan.yaml. 