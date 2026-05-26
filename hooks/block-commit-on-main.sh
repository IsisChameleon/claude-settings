#!/usr/bin/env bash
# PreToolUse hook: blocks `git commit` on main/master branch.
# Allows --amend (rare but legitimate — e.g., amending the just-pulled HEAD).
# Worktree-aware: detects `cd /path &&` prefixes and tool_input.cwd so a
# feature-branch worktree is not blocked by the harness's main-repo cwd.

INPUT=$(cat)
cmd=$(printf '%s' "$INPUT" | jq -r '.tool_input.command' 2>/dev/null)

# Only act on commands that actually invoke `git commit`. Match at the start of
# the command or after a shell separator (;, &&, ||, |, newline), so things
# like `echo "git commit"` or `git log --grep='commit'` aren't blocked.
if ! printf '%s' "$cmd" | grep -Eq '(^|[[:space:]]|;|&&|\|\||\|)git[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

# Allow amends.
case "$cmd" in
  *--amend*) exit 0 ;;
esac

# Determine the directory the command will actually run in:
#   1. Leading `cd <path> &&` (or `;`) prefix in the command — subagents often
#      write `cd /worktree && git commit ...`; the harness shell never cd's,
#      so the hook's own PWD is the wrong place to check the branch.
#   2. tool_input.cwd from the Bash tool payload (if present).
#   3. Fall back to PWD.
target_dir=""
if [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*(\&\&|\;) ]]; then
  target_dir="${BASH_REMATCH[1]}"
  target_dir="${target_dir%\'}"; target_dir="${target_dir#\'}"
  target_dir="${target_dir%\"}"; target_dir="${target_dir#\"}"
fi
if [ -z "$target_dir" ]; then
  target_dir=$(printf '%s' "$INPUT" | jq -r '.tool_input.cwd // empty' 2>/dev/null)
fi
if [ -z "$target_dir" ]; then
  target_dir="$PWD"
fi
target_dir="${target_dir/#\~/$HOME}"

branch=$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
case "$branch" in
  main|master)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Refusing: on %s branch in %s. Create a feature branch first (e.g., git checkout -b your/branch-name) before committing."}}' "$branch" "$target_dir"
    ;;
esac
exit 0
