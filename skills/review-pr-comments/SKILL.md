---
name: review-pr-comments
description: Review all comments on a GitHub PR and provide actionable analysis
---

Analyze all comments (review comments, issue comments, and review threads) on a GitHub pull request and provide a comprehensive report on what needs to be addressed.

## Arguments

```
/review-pr-comments [PR_NUMBER]
```

- `PR_NUMBER` (optional): The pull request number to analyze. If not provided, will attempt to detect from:
  1. Current branch's open PR (using `gh pr status`)
  2. Status line context (if PR number is visible)

Examples:
- `/review-pr-comments` - Auto-detect PR from current branch
- `/review-pr-comments 1234` - Explicitly review PR #1234
- `/review-pr-comments 42` - Override auto-detection with PR #42

## Instructions

### 0. Determine PR Number

**If PR_NUMBER is provided as an argument:**
- Use the provided PR number (it overrides any auto-detection)

**If PR_NUMBER is NOT provided:**
1. First, check the current git branch for an associated PR:
```bash
gh pr status --json number,headRefName -q '.currentBranch.number'
```

2. If no PR is found from the branch, check if there's a PR number in the conversation context (status line, recent messages, etc.)

3. If still no PR number is found, ask the user which PR to review

**Once you have the PR number, proceed with gathering information.**

### 1. Gather PR Information

Use the GitHub CLI to collect all comment data:

```bash
# Get PR details
gh pr view <PR_NUMBER> --json number,title,author,state,url

# Get review comments (inline code comments)
gh api repos/:owner/:repo/pulls/<PR_NUMBER>/comments --paginate

# Get issue comments (general PR comments)
gh api repos/:owner/:repo/issues/<PR_NUMBER>/comments --paginate

# Get reviews (approved, changes requested, etc.)
gh api repos/:owner/:repo/pulls/<PR_NUMBER>/reviews --paginate
```

### 2. Organize Comments by Type

Group the comments into categories:
- **Review comments**: Inline code comments on specific lines
- **General comments**: Top-level comments on the PR
- **Review threads**: Groups of related review comments
- **Review decisions**: Approve, Request Changes, Comment only

### 3. Analyze Each Comment

For each comment, evaluate:

**Priority Assessment:**
- **Critical**: Blocks merging (security, bugs, breaking changes)
- **Important**: Should be addressed (code quality, performance, maintainability)
- **Optional**: Nice to have (style preferences, suggestions)
- **Informational**: No action needed (questions already answered, acknowledgments)

**Action Required:**
- What specific change is being requested?
- Is the comment clear and actionable?
- Has it already been addressed in later commits?

**Context:**
- Who made the comment (reviewer, maintainer, author)?
- Is it part of a resolved thread?
- Does it reference other issues or PRs?

### 4. Generate Report

Create a structured report with:

#### Summary Statistics
- Total comments: X
- Critical issues: Y
- Important issues: Z
- Optional suggestions: W
- Already addressed: A

#### Critical Issues (if any)

For each critical issue:
```markdown
### 🔴 Critical: [Brief description]

**Comment by @username on [file:line]:**
> [Original comment text]

**Why it's necessary:**
[Explain the impact/risk if not addressed]

**Suggested fix:**
[Concrete steps or code changes to resolve]

**File:** `path/to/file.ts:123`
```

#### Important Issues (if any)

Same format as critical, but with 🟡 emoji.

#### Optional Suggestions (if any)

Same format, but with 🔵 emoji. Be brief for optional items.

#### Already Addressed

List comments that appear to be resolved:
```markdown
- ✅ "Fix typo in variable name" - Fixed in commit abc123
- ✅ "Add error handling" - Addressed in latest changes
```

#### No Action Needed

List informational comments that don't require changes.

## Guidelines

**Be Objective:**
- Don't dismiss legitimate concerns, even if they seem minor
- Consider the reviewer's perspective and expertise
- Note if a comment is unclear or needs clarification

**Be Specific:**
- Quote the exact comment text
- Link to the file and line number
- Provide concrete fix suggestions, not vague advice

**Be Efficient:**
- Group related comments together
- Identify patterns (e.g., "Multiple comments about error handling")
- Skip duplicate or superseded comments

**Prioritize:**
- Start with critical/blocking issues
- Security and correctness always come first
- Style preferences are lower priority

**Context Matters:**
- Check if the commenter is a maintainer or subject matter expert
- Consider if this is a recurring feedback pattern
- Note if comments conflict with each other

## Example Output

```markdown
# PR #1234 Comment Review

## Summary
- **Total comments:** 12
- **Critical:** 2
- **Important:** 4
- **Optional:** 3
- **Already addressed:** 2
- **Informational:** 1

---

## 🔴 Critical Issues

### 🔴 SQL Injection Vulnerability

**Comment by @security-reviewer on `server/db.py:45`:**
> This query concatenates user input directly. Use parameterized queries to prevent SQL injection.

**Why it's necessary:**
This is a critical security vulnerability. User-supplied data is directly interpolated into SQL queries, allowing attackers to execute arbitrary SQL commands and potentially access or modify database contents.

**Suggested fix:**
Replace the string concatenation with parameterized queries:
```python
# Current (vulnerable)
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# Fixed
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```

**File:** `server/db.py:45`

---

## 🟡 Important Issues

### 🟡 Missing Error Handling

**Comment by @reviewer on `client/api.ts:123`:**
> What happens if the API call fails? We should handle network errors gracefully.

**Why it's necessary:**
Without error handling, the app will crash or hang if the network request fails. This creates a poor user experience and makes debugging difficult.

**Suggested fix:**
Wrap the API call in try-catch and show user-friendly error:
```typescript
try {
  const data = await fetchData();
  return data;
} catch (error) {
  console.error('Failed to fetch data:', error);
  toast.error('Unable to load data. Please try again.');
  return null;
}
```

**File:** `client/api.ts:123`

---

## 🔵 Optional Suggestions

### 🔵 Extract Magic Number to Constant

**Comment by @reviewer on `utils/timer.ts:67`:**
> Consider extracting 5000 to a named constant like `DEFAULT_TIMEOUT_MS`

**Why it might be helpful:**
Makes the code more readable and easier to maintain if the timeout needs to change.

**Suggested fix:**
```typescript
const DEFAULT_TIMEOUT_MS = 5000;
// ... use DEFAULT_TIMEOUT_MS instead of 5000
```

---

## ✅ Already Addressed

- ✅ "Add type annotations to function" - Added in commit `abc123`
- ✅ "Fix typo in comment" - Corrected in latest push

---

## Informational Only

- "Thanks for the fix!" by @teammate
- "LGTM after the security fix" by @reviewer
```

## Checklist

Before presenting the report:

- [ ] Collected all comment types (reviews, inline, general)
- [ ] Verified each issue hasn't been addressed in later commits
- [ ] Provided specific, actionable fix suggestions
- [ ] Prioritized issues correctly (security/correctness first)
- [ ] Included file paths and line numbers
- [ ] Grouped related feedback together
- [ ] Checked for conflicting feedback from different reviewers
