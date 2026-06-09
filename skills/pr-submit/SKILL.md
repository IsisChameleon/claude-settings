---
name: pr-submit
description: Create and submit a GitHub PR from the current branch
---

Submit the current changes as a GitHub pull request.

## Instructions

1. Check the current state of the repository:
   - Run `git status` to see staged, unstaged, and untracked changes
   - Run `git diff` to see current changes
   - Run `git log --oneline -10` to see recent commits

2. If there are uncommitted changes relevant to the PR:
   - Ask the user if they want a specific prefix for the branch name (e.g., `alice/`, `fix/`, `feat/`)
   - Create a new branch based on the current branch
   - Commit the changes using multiple commits if the changes are unrelated

3. Push the branch and create the PR:
   - Push with `-u` flag to set upstream tracking
   - Create the PR using `gh pr create`

4. After the PR is created:
   - Run `/changelog <pr_number>` to generate changelog files, then commit and push them
   - Run `/pr-description <pr_number>` to update the PR description

5. Verify CI checks pass:
   - Run `gh pr checks <pr_number> --watch --interval 10` to wait for all checks to complete
   - If any check fails, run `gh run view <run_id> --log-failed` to get the failure details
   - Fix the failures, commit, and push — then re-run `gh pr checks <pr_number> --watch` to confirm green
   - Do not report the PR as done until all checks pass

6. Return the PR URL to the user.
