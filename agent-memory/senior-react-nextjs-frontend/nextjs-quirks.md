---
name: nextjs-quirks
description: Next.js 16 / React 19 compiler lint gotchas seen in the readme bot-ui client
metadata:
  type: project
---

# readme bot-ui — React 19 + Next 16 lint gotchas

Client lint (`eslint` flat config, `react-hooks` plugin with the React Compiler rules) is STRICTER than typical:

- **`react-hooks/refs` — "Cannot update ref during render"**: writing `someRef.current = value` in the component body (a common "live ref" pattern) is a lint ERROR. Sync refs inside `useEffect(() => { ref.current = x }, [x])` instead. Note: a component may pass lint with this pattern when the compiler bails out of optimizing it; simplifying the component can *newly* trigger the rule.

- **`react-hooks/immutability` — "Cannot reassign variable after render completes"**: a `let acc = 0; arr.map(() => { acc += ... })` accumulator in the render body is an ERROR. Precompute with `.reduce`/derived arrays before the JSX instead.

Both rules fire only on components the React Compiler actually analyzes. Removing props/state (making a component "simpler") can flip a previously-clean file to failing, even when you didn't touch the offending lines.

Verification commands (node_modules live in the container, not the host):
- `docker exec -w /workspace/client readme-dev-client-1 pnpm vitest run <path>`
- `docker exec -w /workspace/client readme-dev-client-1 pnpm exec eslint --no-cache <paths>`
- `docker exec -w /workspace/client readme-dev-client-1 pnpm exec tsc --noEmit` (scope-grep output; pre-existing errors in `app/admin/design/favicon/page.tsx` and `components/call/MicMutePill.tsx` are unrelated).
