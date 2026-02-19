---
name: worktree-manager
description: Create, manage, and cleanup git worktrees with Claude Code agents across all projects. USE THIS SKILL when user says "create worktree", "spin up worktrees", "new worktree for X", "worktree status", "cleanup worktrees", "sync worktrees", or wants parallel development branches. Also use when creating PRs from a worktree branch (to update registry with PR number). Handles worktree creation, dependency installation, validation, agent launching in Ghostty, and global registry management.
allowed-tools: Bash(git worktree:*), Bash(git rev-parse:*), Bash(docker compose:*), Bash(mkdir:*), Bash(cp:*), Bash(curl:*), Bash(sleep:*), Bash(lsof:*), Bash(~/.claude/skills/worktree-manager/scripts/*), Bash(open:*), Bash(uuidgen:*), Bash(jq:*), Bash(cat:*)
---

# Global Worktree Manager

Manage parallel development across ALL projects using git worktrees with Claude Code agents. Each worktree is an isolated copy of the repo on a different branch, stored at a user-configured location.

**IMPORTANT**: You (Claude) can perform ALL operations manually using standard tools (jq, git, bash). Scripts are helpers, not requirements. If a script fails, fall back to manual operations described in this document.

**CRITICAL - Load Config First**: Before ANY operation, you MUST load configuration. Never assume paths, terminals, or other settings.

### 0. Load Configuration (and First-Run Setup)

**First, check if the user has a local config file:**

```bash
ls ~/.claude/worktree-local.json 2>/dev/null
```

**If `~/.claude/worktree-local.json` does NOT exist**, run first-time setup:
1. Tell the user: "This is your first time using worktree-manager. I need to set up your local config."
2. Show the available settings with their defaults (see the Settings table at the bottom of this file)
3. Ask the user for their preferences:
   - Which terminal do they use? (ghostty, iterm2, tmux, tabby, wezterm, kitty, alacritty)
   - Where should worktrees be stored? (default: ~/tmp/worktrees)
   - Which shell? (default: zsh)
   - Node.js version for nvm? (default: none)
4. Create `~/.claude/worktree-local.json` with their answers (only include non-default values)
5. Then proceed with the original request

**Once config exists, load it by merging local overrides with defaults:**

```bash
# Read local overrides (may not exist)
LOCAL_CONFIG=$(cat ~/.claude/worktree-local.json 2>/dev/null || echo '{}')
# Read shared defaults
SKILL_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo ~/.claude/skills/worktree-manager")")"
DEFAULT_CONFIG=$(cat ~/.claude/skills/worktree-manager/config.defaults.json 2>/dev/null || echo '{}')
# Merge: local overrides defaults
CONFIG=$(echo "$DEFAULT_CONFIG $LOCAL_CONFIG" | jq -s '.[0] * .[1]')
```

Extract values from merged config:
```bash
WORKTREE_BASE=$(echo "$CONFIG" | jq -r '.worktreeBase')
TERMINAL=$(echo "$CONFIG" | jq -r '.terminal')
SHELL_CMD=$(echo "$CONFIG" | jq -r '.shell')
NODE_VERSION=$(echo "$CONFIG" | jq -r '.nodeVersion // empty')
CLAUDE_CMD=$(echo "$CONFIG" | jq -r '.claudeCommand')
REGISTRY_PATH=$(echo "$CONFIG" | jq -r '.registryPath')
PORT_START=$(echo "$CONFIG" | jq -r '.portPool.start')
PORT_END=$(echo "$CONFIG" | jq -r '.portPool.end')
PORTS_PER_WT=$(echo "$CONFIG" | jq -r '.portsPerWorktree')
```

**Use these variables throughout. Never hardcode paths like `~/tmp/worktrees` or terminals like `ghostty`.**

## When This Skill Activates

**Trigger phrases:**
- "spin up worktrees for X, Y, Z"
- "create 3 worktrees for features A, B, C"
- "new worktree for feature/auth"
- "what's the status of my worktrees?"
- "show all worktrees" / "show worktrees for this project"
- "clean up merged worktrees"
- "clean up the auth worktree"
- "launch agent in worktree X"
- "sync worktrees" / "sync worktree registry"
- "create PR" (when in a worktree - updates registry with PR number)
- "audit worktree settings" / "what Claude data is in this worktree?"
- "check Claude config for worktree X"

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/worktree-local.json` | **User-local config** - per-user overrides (terminal, shell, worktree base path, node version) |
| `~/.claude/skills/worktree-manager/config.defaults.json` | **Shared defaults** - fallback values for all settings |
| `~/.claude/worktree-registry.json` | **Global registry** - tracks all worktrees across all projects (runtime state) |
| `~/.claude/skills/worktree-manager/scripts/` | **Helper scripts** - optional, can do everything manually |
| `$WORKTREE_BASE/` | **Worktree storage** - all worktrees live here (path from config) |
| `.claude/worktree.json` (per-project) | **Project config** - optional custom settings |

---

## Core Concepts

### Centralized Worktree Storage
All worktrees live in `$WORKTREE_BASE/<project-name>/<branch-slug>/` (path from config).

```
$WORKTREE_BASE/
├── obsidian-ai-agent/
│   ├── feature-auth/           # branch: feature/auth
│   ├── feature-payments/       # branch: feature/payments
│   └── fix-login-bug/          # branch: fix/login-bug
└── another-project/
    └── feature-dark-mode/
```

### Branch Slug Convention
Branch names are slugified for filesystem safety by replacing `/` with `-`:
- `feature/auth` → `feature-auth`
- `fix/login-bug` → `fix-login-bug`
- `feat/user-profile` → `feat-user-profile`

**Slugify manually:** `echo "feature/auth" | tr '/' '-'` → `feature-auth`

### Port Allocation Rules
- **Global pool**: `$PORT_START`-`$PORT_END` (from config, default 8100-8199)
- **Per worktree**: `$PORTS_PER_WT` ports allocated (from config, default 2)
- **Globally unique**: Ports are tracked globally to avoid conflicts across projects
- **Check before use**: Always verify port isn't in use by system: `lsof -i :<port>`

---

## Global Registry

### Location
`~/.claude/worktree-registry.json`

### Schema
```json
{
  "worktrees": [
    {
      "id": "unique-uuid",
      "project": "obsidian-ai-agent",
      "repoPath": "/Users/rasmus/Projects/obsidian-ai-agent",
      "branch": "feature/auth",
      "branchSlug": "feature-auth",
      "worktreePath": "/Users/rasmus/tmp/worktrees/obsidian-ai-agent/feature-auth",
      "ports": [8100, 8101],
      "composeProjectName": "qz-feature-auth",
      "createdAt": "2025-12-04T10:00:00Z",
      "validatedAt": "2025-12-04T10:02:00Z",
      "agentLaunchedAt": "2025-12-04T10:03:00Z",
      "task": "Implement OAuth login",
      "prNumber": null,
      "status": "active"
    }
  ],
  "portPool": {
    "start": 8100,
    "end": 8199,
    "allocated": [8100, 8101]
  }
}
```

### Field Descriptions

**Worktree entry fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (UUID) |
| `project` | string | Project name (from git remote or directory) |
| `repoPath` | string | Absolute path to original repository |
| `branch` | string | Full branch name (e.g., `feature/auth`) |
| `branchSlug` | string | Filesystem-safe name (e.g., `feature-auth`) |
| `worktreePath` | string | Absolute path to worktree |
| `ports` | number[] | Allocated port numbers (usually 2) |
| `createdAt` | string | ISO 8601 timestamp |
| `validatedAt` | string\|null | When validation passed |
| `agentLaunchedAt` | string\|null | When agent was launched |
| `task` | string\|null | Task description for the agent |
| `prNumber` | number\|null | Associated PR number if exists |
| `composeProjectName` | string\|null | Docker Compose project name (from `.claude/worktree.json`) |
| `status` | string | `active`, `orphaned`, or `merged` |

**Port pool fields:**
| Field | Type | Description |
|-------|------|-------------|
| `start` | number | First port in pool (default: 8100) |
| `end` | number | Last port in pool (default: 8199) |
| `allocated` | number[] | Currently allocated ports |

### Manual Registry Operations

**Read entire registry:**
```bash
cat ~/.claude/worktree-registry.json | jq '.'
```

**List all worktrees:**
```bash
cat ~/.claude/worktree-registry.json | jq '.worktrees[]'
```

**List worktrees for specific project:**
```bash
cat ~/.claude/worktree-registry.json | jq '.worktrees[] | select(.project == "my-project")'
```

**Get allocated ports:**
```bash
cat ~/.claude/worktree-registry.json | jq '.portPool.allocated'
```

**Find worktree by branch (partial match):**
```bash
cat ~/.claude/worktree-registry.json | jq '.worktrees[] | select(.branch | contains("auth"))'
```

**Add worktree entry manually:**
```bash
TMP=$(mktemp)
jq '.worktrees += [{
  "id": "'$(uuidgen)'",
  "project": "my-project",
  "repoPath": "/path/to/repo",
  "branch": "feature/auth",
  "branchSlug": "feature-auth",
  "worktreePath": "/Users/me/tmp/worktrees/my-project/feature-auth",
  "ports": [8100, 8101],
  "composeProjectName": "qz-feature-auth",
  "createdAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "validatedAt": null,
  "agentLaunchedAt": null,
  "task": "My task",
  "prNumber": null,
  "status": "active"
}]' ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
```

**Add ports to allocated pool:**
```bash
TMP=$(mktemp)
jq '.portPool.allocated += [8100, 8101] | .portPool.allocated |= unique | .portPool.allocated |= sort_by(.)' \
  ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
```

**Remove worktree entry:**
```bash
TMP=$(mktemp)
jq 'del(.worktrees[] | select(.project == "my-project" and .branch == "feature/auth"))' \
  ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
```

**Release ports from pool:**
```bash
TMP=$(mktemp)
jq '.portPool.allocated = (.portPool.allocated | map(select(. != 8100 and . != 8101)))' \
  ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
```

**Initialize empty registry (if missing):**
```bash
mkdir -p ~/.claude
cat > ~/.claude/worktree-registry.json << 'EOF'
{
  "worktrees": [],
  "portPool": {
    "start": 8100,
    "end": 8199,
    "allocated": []
  }
}
EOF
```

---

## Manual Port Allocation

If `scripts/allocate-ports.sh` fails, allocate ports manually:

**Step 1: Get currently allocated ports**
```bash
ALLOCATED=$(cat ~/.claude/worktree-registry.json | jq -r '.portPool.allocated[]' | sort -n)
echo "Currently allocated: $ALLOCATED"
```

**Step 2: Find first available port (not in allocated list AND not in use by system)**
```bash
for PORT in $(seq 8100 8199); do
  # Check if in registry
  if ! echo "$ALLOCATED" | grep -q "^${PORT}$"; then
    # Check if in use by system
    if ! lsof -i :"$PORT" &>/dev/null; then
      echo "Available: $PORT"
      break
    fi
  fi
done
```

**Step 3: Add to allocated pool**
```bash
TMP=$(mktemp)
jq '.portPool.allocated += [8100] | .portPool.allocated |= unique | .portPool.allocated |= sort_by(.)' \
  ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
```

---

## What You (Claude) Do vs What Scripts Do

| Task | Script Available | Manual Fallback |
|------|------------------|-----------------|
| Determine project name | No | Parse `git remote get-url origin` or `basename $(pwd)` |
| Detect package manager | No | Check for lockfiles (see Detection section) |
| Create git worktree | No | `git worktree add <path> -b <branch>` |
| Copy .agents/ directory | No | `cp -r .agents <worktree-path>/` |
| Copy .claude/ directory | No | `cp -r .claude <worktree-path>/` |
| Copy .cursor/ directory | No | `cp -r .cursor <worktree-path>/` |
| Install dependencies | No | Run detected install command |
| Validate (health check) | No | Start server, curl endpoint, stop server |
| Allocate ports | `scripts/allocate-ports.sh 2` | Manual (see above) |
| Register worktree | `scripts/register.sh` | Manual jq (see above) |
| Launch agent in terminal | `scripts/launch-agent.sh` | Manual (see below) |
| Show status | `scripts/status.sh` | `cat ~/.claude/worktree-registry.json \| jq ...` |
| Cleanup worktree | `scripts/cleanup.sh` | Manual (see Cleanup section) |
| Audit Claude settings | No | Manual inspection (see Audit section) |
| Pre-cleanup checks | No | Check untracked .md files + review Claude memory |

---

## Workflows

### 1. Create Multiple Worktrees with Agents

**User says:** "Spin up 3 worktrees for feature/auth, feature/payments, and fix/login-bug"

**You do (can parallelize with subagents):**

```
For EACH branch (can run in parallel):

1. SETUP
   a. Get project name:
      PROJECT=$(basename $(git remote get-url origin 2>/dev/null | sed 's/\.git$//') 2>/dev/null || basename $(pwd))
   b. Get repo root:
      REPO_ROOT=$(git rev-parse --show-toplevel)
   c. Slugify branch:
      BRANCH_SLUG=$(echo "feature/auth" | tr '/' '-')
   d. Determine worktree path:
      WORKTREE_PATH=$WORKTREE_BASE/$PROJECT/$BRANCH_SLUG
   e. Determine Docker Compose project name (if project uses Docker):
      # Check if .claude/worktree.json exists and has compose config
      if [ -f "$REPO_ROOT/.claude/worktree.json" ]; then
        COMPOSE_PATTERN=$(jq -r '.startServices.command // .stopServices.command // .cleanup.preCleanup[0] // ""' "$REPO_ROOT/.claude/worktree.json" | grep -o 'COMPOSE_PROJECT_NAME=[^ ]*' | cut -d= -f2)
        # Replace {{BRANCH_SLUG}} placeholder with actual branch slug
        COMPOSE_PROJECT_NAME=$(echo "$COMPOSE_PATTERN" | sed "s/{{BRANCH_SLUG}}/$BRANCH_SLUG/g")
      else
        COMPOSE_PROJECT_NAME=null
      fi

1.5. PRE-FLIGHT CHECK — branch conflict
   **Do this BEFORE allocating ports or creating any directories.**
   Git disallows checking out the same branch in two worktrees simultaneously.
   Check whether the branch is already checked out somewhere:
      git worktree list | grep "$BRANCH"
   If it IS checked out (including the main repo):
   - Tell the user which worktree/path has it checked out
   - Ask them to resolve it (switch that worktree to another branch) before continuing
   - Do NOT allocate ports or create directories until this is resolved
   This avoids orphaned port allocations that need manual rollback.

2. ALLOCATE PORTS
   Option A (script): ~/.claude/skills/worktree-manager/scripts/allocate-ports.sh 2
   Option B (manual): Find $PORTS_PER_WT unused ports from $PORT_START-$PORT_END, add to registry

3. CREATE WORKTREE
   mkdir -p $WORKTREE_BASE/$PROJECT
   git worktree add $WORKTREE_PATH $BRANCH
   # Note: omit -b flag when the branch already exists locally

4. COPY UNCOMMITTED RESOURCES
   cp -r .agents $WORKTREE_PATH/ 2>/dev/null || true
   cp -r .claude $WORKTREE_PATH/ 2>/dev/null || true
   cp -r .cursor $WORKTREE_PATH/ 2>/dev/null || true
   cp .env.example $WORKTREE_PATH/.env 2>/dev/null || true

5. INSTALL DEPENDENCIES
   cd $WORKTREE_PATH
   # Detect and run: npm install / uv sync / etc.

6. VALIDATE (start server, health check, stop)
   a. Start server with allocated port
   b. Wait and health check: curl -sf http://localhost:$PORT/health
   c. Stop server
   d. If FAILS: report error but continue with other worktrees

7. REGISTER IN GLOBAL REGISTRY
   Option A (script): ~/.claude/skills/worktree-manager/scripts/register.sh ...
   Option B (manual): Update ~/.claude/worktree-registry.json with jq

8. LAUNCH AGENT
   Option A (script): ~/.claude/skills/worktree-manager/scripts/launch-agent.sh $WORKTREE_PATH "task"
   Option B (manual): Open terminal manually, cd to path, run claude

AFTER ALL COMPLETE:
- Report summary table to user
- Note any failures with details
```

### 2. Check Status

**With script:**
```bash
~/.claude/skills/worktree-manager/scripts/status.sh
~/.claude/skills/worktree-manager/scripts/status.sh --project my-project
```

**Manual:**
```bash
# All worktrees
cat ~/.claude/worktree-registry.json | jq -r '.worktrees[] | "\(.project)\t\(.branch)\t\(.ports | join(","))\t\(.status)\t\(.task // "-")"'

# For current project
PROJECT=$(basename $(git remote get-url origin 2>/dev/null | sed 's/\.git$//'))
cat ~/.claude/worktree-registry.json | jq -r ".worktrees[] | select(.project == \"$PROJECT\") | \"\(.branch)\t\(.ports | join(\",\"))\t\(.status)\""
```

### 3. Launch Agent Manually

If `launch-agent.sh` fails, use the terminal from config (`$TERMINAL`):

**For Ghostty:**
```bash
open -na "Ghostty.app" --args -e $SHELL_CMD -c "cd '$WORKTREE_PATH' && $CLAUDE_CMD"
```

**For iTerm2:**
```bash
osascript -e 'tell application "iTerm2" to create window with default profile' \
  -e 'tell application "iTerm2" to tell current session of current window to write text "cd '"$WORKTREE_PATH"' && claude"'
```

**For tmux:**
```bash
tmux new-session -d -s "wt-$PROJECT-$BRANCH_SLUG" -c "$WORKTREE_PATH" "$SHELL_CMD -c '$CLAUDE_CMD'"
```

### 4. Cleanup Worktree

**IMPORTANT: Before running cleanup, perform these pre-cleanup checks:**

#### Pre-Cleanup Step A: Identify untracked markdown files
Check for any untracked `*.md` files in the worktree that may contain notes, plans, or documentation the user wants to keep:
```bash
cd $WORKTREE_PATH
git ls-files --others --exclude-standard -- '*.md'
```
If any are found, present them to the user and ask where to save them (e.g., copy to main repo, save to `~/.claude/`, or discard).

#### Pre-Cleanup Step B: Review Claude memory for the worktree
Check if the worktree's Claude Code project has memory files worth preserving globally:
```bash
CLAUDE_PROJECT_DIR="${HOME}/.claude/projects/$(echo "$WORKTREE_PATH" | tr '/' '-')"
ls "$CLAUDE_PROJECT_DIR/memory/" 2>/dev/null
# If files exist, read them and present a summary to the user
# Ask if any insights should be saved to the main project's memory or global memory
```

#### Running cleanup

**With script:**
```bash
# Basic cleanup (worktree + ports + registry)
~/.claude/skills/worktree-manager/scripts/cleanup.sh my-project feature/auth

# Also delete local and remote git branches
~/.claude/skills/worktree-manager/scripts/cleanup.sh my-project feature/auth --delete-branch

# Also remove Claude Code project data (sessions, memory)
~/.claude/skills/worktree-manager/scripts/cleanup.sh my-project feature/auth --clean-claude

# Full cleanup (everything)
~/.claude/skills/worktree-manager/scripts/cleanup.sh my-project feature/auth --delete-branch --clean-claude

# Cleanup ALL merged worktrees at once (flags can be combined)
~/.claude/skills/worktree-manager/scripts/cleanup.sh --merged --delete-branch --clean-claude
```

**Optional flags:**
| Flag | Effect |
|------|--------|
| `--delete-branch` | Delete local and remote git branches |
| `--clean-claude` | Remove Claude Code project data (`~/.claude/projects/<path>/` — sessions, memory, etc.) |

**Manual cleanup:**
```bash
# 1. Get worktree info from registry
ENTRY=$(cat ~/.claude/worktree-registry.json | jq '.worktrees[] | select(.project == "my-project" and .branch == "feature/auth")')
WORKTREE_PATH=$(echo "$ENTRY" | jq -r '.worktreePath')
PORTS=$(echo "$ENTRY" | jq -r '.ports[]')
REPO_PATH=$(echo "$ENTRY" | jq -r '.repoPath')
COMPOSE_PROJECT_NAME=$(echo "$ENTRY" | jq -r '.composeProjectName // empty')

# 2. Run project-specific preCleanup (Docker Compose cleanup, etc.)
if [ -n "$COMPOSE_PROJECT_NAME" ] && [ "$COMPOSE_PROJECT_NAME" != "null" ]; then
  cd "$REPO_PATH"
  COMPOSE_PROJECT_NAME="$COMPOSE_PROJECT_NAME" docker compose down --volumes --remove-orphans 2>/dev/null || true
fi

# 3. Kill processes on ports
for PORT in $PORTS; do
  lsof -ti:"$PORT" | xargs kill -9 2>/dev/null || true
done

# 4. Remove worktree
cd "$REPO_PATH"
git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || rm -rf "$WORKTREE_PATH"
git worktree prune

# 5. Remove from registry
TMP=$(mktemp)
jq 'del(.worktrees[] | select(.project == "my-project" and .branch == "feature/auth"))' \
  ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json

# 6. Release ports
TMP=$(mktemp)
for PORT in $PORTS; do
  jq ".portPool.allocated = (.portPool.allocated | map(select(. != $PORT)))" \
    ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
done

# 7. Remove Claude Code project data (optional)
CLAUDE_PROJECT_DIR="${HOME}/.claude/projects/$(echo "$WORKTREE_PATH" | tr '/' '-')"
rm -rf "$CLAUDE_PROJECT_DIR"

# 8. Optionally delete branch
git branch -D feature/auth
git push origin --delete feature/auth
```

### 5. Create PR from Worktree

When creating a PR from a worktree branch, update the registry with the PR number:

```bash
# After gh pr create succeeds, get the PR number
BRANCH=$(git branch --show-current)
PR_NUM=$(gh pr view --json number -q '.number')

# Update registry with PR number
if [ -n "$PR_NUM" ] && [ -f ~/.claude/worktree-registry.json ]; then
    TMP=$(mktemp)
    jq "(.worktrees[] | select(.branch == \"$BRANCH\")).prNumber = $PR_NUM" \
      ~/.claude/worktree-registry.json > "$TMP" && mv "$TMP" ~/.claude/worktree-registry.json
    echo "Updated worktree registry with PR #$PR_NUM"
fi
```

This enables `cleanup.sh --merged` to automatically find and clean up worktrees after their PRs are merged.

### 6. Audit Claude Settings for a Worktree

**User says:** "what Claude data is in this worktree?", "audit worktree settings", "check Claude config for worktree X"

Identify all custom Claude Code settings, memory, skills, commands, and session data associated with a specific worktree and its corresponding Claude project directory. Present findings to the user so they can decide what to keep, move, or discard.

**What to check:**

```bash
WORKTREE_PATH="<worktree-path>"
CLAUDE_PROJECT_DIR="${HOME}/.claude/projects/$(echo "$WORKTREE_PATH" | tr '/' '-')"

# 1. Claude project memory files
ls -la "$CLAUDE_PROJECT_DIR/memory/" 2>/dev/null
# Read each file and summarize contents

# 2. Session transcripts (count and total size)
find "$CLAUDE_PROJECT_DIR" -name "*.jsonl" -type f 2>/dev/null | wc -l
du -sh "$CLAUDE_PROJECT_DIR" 2>/dev/null

# 3. Session memory summaries
find "$CLAUDE_PROJECT_DIR" -path "*/session-memory/summary.md" 2>/dev/null
# Read each and summarize

# 4. In-worktree Claude config (CLAUDE.md, .claude/ directory)
ls "$WORKTREE_PATH/CLAUDE.md" 2>/dev/null
ls -la "$WORKTREE_PATH/.claude/" 2>/dev/null

# 5. In-worktree custom skills
ls "$WORKTREE_PATH/.claude/skills/" 2>/dev/null

# 6. In-worktree custom commands
ls "$WORKTREE_PATH/.claude/commands/" 2>/dev/null

# 7. In-worktree MCP settings
ls "$WORKTREE_PATH/.claude/mcp*.json" 2>/dev/null
```

**Present to user as a summary table:**
```
Claude data for worktree: feature/auth
─────────────────────────────────────────────────────────
Project dir:  ~/.claude/projects/-Users-...-feature-auth/
Sessions:     12 transcripts (2.3M)
Memory:       1 file (MEMORY.md - 45 lines)
Summaries:    3 session summaries

In-worktree:
  CLAUDE.md:  yes (same as main repo)
  Skills:     none
  Commands:   none
  MCP config: none
─────────────────────────────────────────────────────────
```

**Ask the user for each item:**
- **Memory files**: Save to main project memory / global memory / discard?
- **Session summaries**: Review and extract useful insights / discard?
- **Custom skills/commands**: Move to main repo / global skills / discard?
- **Session transcripts**: Keep for reference / discard?

### 7. Sync Registry

Reconcile registry with actual worktrees and PR status:

```bash
# Check status (no changes)
~/.claude/skills/worktree-manager/scripts/sync.sh

# Auto-fix issues (update PR numbers, remove missing entries)
~/.claude/skills/worktree-manager/scripts/sync.sh --fix

# Quiet mode (only show problems)
~/.claude/skills/worktree-manager/scripts/sync.sh --quiet
```

---

## Package Manager Detection

Detect by checking for lockfiles in priority order:

| File | Package Manager | Install Command |
|------|-----------------|-----------------|
| `bun.lockb` | bun | `bun install` |
| `pnpm-lock.yaml` | pnpm | `pnpm install` |
| `yarn.lock` | yarn | `yarn install` |
| `package-lock.json` | npm | `npm install` |
| `uv.lock` | uv | `uv sync` |
| `pyproject.toml` (no uv.lock) | uv | `uv sync` |
| `requirements.txt` | pip | `pip install -r requirements.txt` |
| `go.mod` | go | `go mod download` |
| `Cargo.toml` | cargo | `cargo build` |

**Detection logic:**
```bash
cd $WORKTREE_PATH
if [ -f "bun.lockb" ]; then bun install
elif [ -f "pnpm-lock.yaml" ]; then pnpm install
elif [ -f "yarn.lock" ]; then yarn install
elif [ -f "package-lock.json" ]; then npm install
elif [ -f "uv.lock" ]; then uv sync
elif [ -f "pyproject.toml" ]; then uv sync
elif [ -f "requirements.txt" ]; then pip install -r requirements.txt
elif [ -f "go.mod" ]; then go mod download
elif [ -f "Cargo.toml" ]; then cargo build
fi
```

---

## Dev Server Detection

Look for dev commands in this order:

1. **docker-compose.yml / compose.yml**: `docker-compose up -d` or `docker compose up -d`
2. **package.json scripts**: Look for `dev`, `start:dev`, `serve`
3. **Python with uvicorn**: `uv run uvicorn app.main:app --port $PORT`
4. **Python with Flask**: `flask run --port $PORT`
5. **Go**: `go run .`

**Port injection**: Most servers accept `PORT` env var or `--port` flag

---

## Project-Specific Config (Optional)

Projects can provide `.claude/worktree.json` for custom settings:

```json
{
  "ports": {
    "count": 2,
    "services": ["api", "frontend"]
  },
  "install": "uv sync && cd frontend && npm install",
  "validate": {
    "start": "docker-compose up -d",
    "healthCheck": "curl -sf http://localhost:{{PORT}}/health",
    "stop": "docker-compose down"
  },
  "copyDirs": [".agents", ".claude", ".env.example", "data/fixtures"]
}
```

If this file exists, use its settings. Otherwise, auto-detect.

---

## Parallel Worktree Creation

When creating multiple worktrees, use subagents for parallelization:

```
User: "Spin up worktrees for feature/a, feature/b, feature/c"

You:
1. Allocate ports for ALL worktrees upfront (6 ports total)
2. Spawn 3 subagents, one per worktree
3. Each subagent:
   - Creates its worktree
   - Installs deps
   - Validates
   - Registers (with its pre-allocated ports)
   - Launches agent
4. Collect results from all subagents
5. Report unified summary with any failures noted
```

---

## Safety Guidelines

1. **Before cleanup**, check PR status:
   - PR merged → safe to clean everything
   - PR open → warn user, confirm before proceeding
   - No PR → warn about unsubmitted work

2. **Before deleting branches**, confirm if:
   - PR not merged
   - No PR exists
   - Worktree has uncommitted changes

3. **Port conflicts**: If port in use by non-worktree process, pick different port

4. **Orphaned worktrees**: If original repo deleted, mark as `orphaned` in status

5. **Max worktrees**: With 100-port pool and 2 ports each, max ~50 concurrent worktrees

---

## Script Reference

Scripts are in `~/.claude/skills/worktree-manager/scripts/`

### allocate-ports.sh
```bash
~/.claude/skills/worktree-manager/scripts/allocate-ports.sh <count>
# Returns: space-separated port numbers (e.g., "8100 8101")
# Automatically updates registry
```

### register.sh
```bash
~/.claude/skills/worktree-manager/scripts/register.sh \
  <project> <branch> <branch-slug> <worktree-path> <repo-path> <ports> [compose-project-name] [task]
# Example:
~/.claude/skills/worktree-manager/scripts/register.sh \
  "my-project" "feature/auth" "feature-auth" \
  "$HOME/tmp/worktrees/my-project/feature-auth" \
  "/path/to/repo" "8100,8101" "qz-feature-auth" "Implement OAuth"
```

### launch-agent.sh
```bash
~/.claude/skills/worktree-manager/scripts/launch-agent.sh <worktree-path> [task]
# Opens new terminal window (from config) with Claude Code
```

### status.sh
```bash
~/.claude/skills/worktree-manager/scripts/status.sh [--project <name>]
# Shows all worktrees, or filtered by project
```

### cleanup.sh
```bash
~/.claude/skills/worktree-manager/scripts/cleanup.sh <project> <branch> [--delete-branch] [--clean-claude]
# Kills ports, removes worktree, updates registry
# --delete-branch also removes local and remote git branches
# --clean-claude also removes Claude Code project data (sessions, memory in ~/.claude/projects/)

# Or cleanup ALL merged worktrees at once:
~/.claude/skills/worktree-manager/scripts/cleanup.sh --merged [--delete-branch] [--clean-claude]
# Finds all worktrees with merged PRs and cleans them up
```

### sync.sh
```bash
~/.claude/skills/worktree-manager/scripts/sync.sh [--quiet] [--fix]
# Reconciles registry with actual worktrees and PR status
# --quiet: Only show issues, not OK entries
# --fix: Automatically remove missing entries and update PR numbers/status

# Example: Check status without changing anything
~/.claude/skills/worktree-manager/scripts/sync.sh

# Example: Auto-fix registry issues
~/.claude/skills/worktree-manager/scripts/sync.sh --fix
```

### release-ports.sh
```bash
~/.claude/skills/worktree-manager/scripts/release-ports.sh <port1> [port2] ...
# Releases ports back to pool
```

---

## Skill Config

**Two-layer config: local overrides shared defaults.**

### Shared Defaults
Location: `~/.claude/skills/worktree-manager/config.defaults.json`

Contains sensible defaults for all settings. This file ships with the skill and should not be edited by users.

### User-Local Overrides
Location: `~/.claude/worktree-local.json`

Each user creates this file to override any defaults. Only include the keys you want to change.

**Example `~/.claude/worktree-local.json`:**
```json
{
  "terminal": "iterm2",
  "shell": "fish",
  "nodeVersion": "22.0.0",
  "worktreeBase": "~/dev/worktrees"
}
```

### Available Settings

| Key | Default | Description |
|-----|---------|-------------|
| `terminal` | `ghostty` | Terminal to launch agents in (`ghostty`, `iterm2`, `tmux`, `wezterm`, `kitty`, `alacritty`, `tabby`) |
| `shell` | `zsh` | Shell to use in launched terminals |
| `nodeVersion` | `null` | Node.js version to activate via nvm before installs (null = skip) |
| `claudeCommand` | `claude` | Command to launch Claude Code |
| `worktreeBase` | `~/tmp/worktrees` | Base directory for all worktrees |
| `registryPath` | `~/.claude/worktree-registry.json` | Path to the global worktree registry |
| `portPool.start` | `8100` | First port in allocation pool |
| `portPool.end` | `8199` | Last port in allocation pool |
| `portsPerWorktree` | `2` | Number of ports allocated per worktree |
| `defaultCopyDirs` | `[".agents", ".env.example", ".env"]` | Dirs/files to copy into new worktrees |
| `healthCheckTimeout` | `30` | Seconds to wait for health check |
| `healthCheckRetries` | `6` | Number of health check retries |

---

## Common Issues

### "Worktree already exists"
```bash
git worktree list
git worktree remove <path> --force
git worktree prune
```

### "Branch already exists"
```bash
# Use existing branch (omit -b flag)
git worktree add <path> <branch>
```

### "Port already in use"
```bash
lsof -i :<port>
# Kill if stale, or pick different port
```

### Registry out of sync
```bash
# Compare registry to actual worktrees
cat ~/.claude/worktree-registry.json | jq '.worktrees[].worktreePath'
find $WORKTREE_BASE -maxdepth 2 -type d

# Remove orphaned entries or add missing ones
```

### Validation failed
1. Check stderr/logs for error message
2. Common issues: missing env vars, database not running, wrong port
3. Report to user with details
4. Continue with other worktrees
5. User can fix and re-validate manually

---

## Example Session

**User:** "Spin up 2 worktrees for feature/dark-mode and fix/login-bug"

**You:**
1. Detect project: `obsidian-ai-agent` (from git remote)
2. Detect package manager: `uv` (found uv.lock)
3. Allocate 4 ports: `~/.claude/skills/worktree-manager/scripts/allocate-ports.sh 4` → `8100 8101 8102 8103`
4. Create worktrees:
   ```bash
   mkdir -p $WORKTREE_BASE/obsidian-ai-agent
   git worktree add $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode -b feature/dark-mode
   git worktree add $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug -b fix/login-bug
   ```
5. Copy .agents/, .claude/, and .cursor/:
   ```bash
   cp -r .agents $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode/
   cp -r .agents $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug/
   cp -r .claude $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode/
   cp -r .claude $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug/
   cp -r .cursor $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode/
   cp -r .cursor $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug/
   ```
6. Install deps in each worktree:
   ```bash
   (cd $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode && uv sync)
   (cd $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug && uv sync)
   ```
7. Validate each (start server, health check, stop)
8. Register both worktrees in `~/.claude/worktree-registry.json`
9. Launch agents:
   ```bash
   ~/.claude/skills/worktree-manager/scripts/launch-agent.sh \
     $WORKTREE_BASE/obsidian-ai-agent/feature-dark-mode "Implement dark mode toggle"
   ~/.claude/skills/worktree-manager/scripts/launch-agent.sh \
     $WORKTREE_BASE/obsidian-ai-agent/fix-login-bug "Fix login redirect bug"
   ```
10. Report:
    ```
    Created 2 worktrees with agents:

    | Branch | Ports | Path | Task |
    |--------|-------|------|------|
    | feature/dark-mode | 8100, 8101 | $WORKTREE_BASE/.../feature-dark-mode | Implement dark mode |
    | fix/login-bug | 8102, 8103 | $WORKTREE_BASE/.../fix-login-bug | Fix login redirect |

    Both agents running in $TERMINAL windows.
    ```
