#!/bin/bash
# launch-agent.sh - Launch Claude Code in a new Ghostty terminal for a worktree
#
# Usage: ./launch-agent.sh <worktree-path> [task-description]
#
# Examples:
#   ./launch-agent.sh ~/tmp/worktrees/my-project/feature-auth
#   ./launch-agent.sh ~/tmp/worktrees/my-project/feature-auth "Implement OAuth login"

set -e

WORKTREE_PATH="$1"
TASK="$2"

# Validate input
if [ -z "$WORKTREE_PATH" ]; then
    echo "Error: Worktree path required"
    echo "Usage: $0 <worktree-path> [task-description]"
    exit 1
fi

# Find script directory and config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
REGISTRY="${HOME}/.claude/worktree-registry.json"

# Load config (with defaults)
if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    TERMINAL=$(jq -r '.terminal // "ghostty"' "$CONFIG_FILE")
    SHELL_CMD=$(jq -r '.shell // "fish"' "$CONFIG_FILE")
    CLAUDE_CMD=$(jq -r '.claudeCommand // "cc"' "$CONFIG_FILE")
else
    TERMINAL="ghostty"
    SHELL_CMD="fish"
    CLAUDE_CMD="cc"
fi

# Note: CLAUDE_CMD (default "cc") is configurable in config.json
# It runs inside the target shell (fish) which should have the alias defined
# Falls back to "claude" if the alias/command fails

# Expand ~ in path
WORKTREE_PATH="${WORKTREE_PATH/#\~/$HOME}"

# Convert to absolute path if relative
if [[ "$WORKTREE_PATH" != /* ]]; then
    WORKTREE_PATH="$(pwd)/$WORKTREE_PATH"
fi

# Verify worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Error: Worktree directory does not exist: $WORKTREE_PATH"
    exit 1
fi

# Verify it's a git worktree (has .git file or directory)
if [ ! -e "$WORKTREE_PATH/.git" ]; then
    echo "Error: Not a git worktree: $WORKTREE_PATH"
    exit 1
fi

# Get branch name
BRANCH=$(cd "$WORKTREE_PATH" && git branch --show-current 2>/dev/null || basename "$WORKTREE_PATH")

# Get project name from path
PROJECT=$(basename "$(dirname "$WORKTREE_PATH")")

# Get color and index from registry if available
WORKTREE_COLOR=""
WORKTREE_INDEX=""
WORKTREE_BG=""
WORKTREE_PROMPT_COLOR=""
WORKTREE_EMOJI=""

if [ -f "$REGISTRY" ] && command -v jq &> /dev/null; then
    REGISTRY_ENTRY=$(jq -r ".worktrees[] | select(.worktreePath == \"$WORKTREE_PATH\")" "$REGISTRY")
    if [ -n "$REGISTRY_ENTRY" ]; then
        WORKTREE_COLOR=$(echo "$REGISTRY_ENTRY" | jq -r '.color // ""')
        WORKTREE_INDEX=$(echo "$REGISTRY_ENTRY" | jq -r '.index // ""')

        # Map colors to background tints and prompt colors
        case "$WORKTREE_COLOR" in
            yellow)
                WORKTREE_BG="#2e2e1a"
                WORKTREE_PROMPT_COLOR="yellow"
                ;;
            red)
                WORKTREE_BG="#2e1a1a"
                WORKTREE_PROMPT_COLOR="red"
                ;;
            green)
                WORKTREE_BG="#1a2e1a"
                WORKTREE_PROMPT_COLOR="green"
                ;;
            blue)
                WORKTREE_BG="#1a1a2e"
                WORKTREE_PROMPT_COLOR="blue"
                ;;
            purple)
                WORKTREE_BG="#2e1a2e"
                WORKTREE_PROMPT_COLOR="magenta"
                ;;
        esac

        # Set emoji based on index
        if [ -n "$WORKTREE_INDEX" ]; then
            WORKTREE_EMOJI="[$WORKTREE_INDEX]"
        fi
    fi
fi

# Build the command to run in the new terminal
# Set tab title and prompt color
TAB_TITLE="$WORKTREE_EMOJI $BRANCH"

if [ "$SHELL_CMD" = "fish" ]; then
    # Fish shell syntax
    if [ -n "$TASK" ]; then
        INNER_CMD="cd '$WORKTREE_PATH'; and echo '📋 Task: $TASK'; and echo ''; and $CLAUDE_CMD; or claude"
    else
        INNER_CMD="cd '$WORKTREE_PATH'; and echo ''; and $CLAUDE_CMD; or claude"
    fi
else
    # bash/zsh syntax - Set tab title via escape sequence and configure prompt
    SETUP_CMD="printf '\033]0;$TAB_TITLE\007'"

    # Set up colored prompt for zsh
    if [ "$SHELL_CMD" = "zsh" ] && [ -n "$WORKTREE_PROMPT_COLOR" ]; then
        PROMPT_CMD="export PS1='%F{$WORKTREE_PROMPT_COLOR}$WORKTREE_EMOJI%f %~ %# '"
        SETUP_CMD="$SETUP_CMD && $PROMPT_CMD"
    fi

    if [ -n "$TASK" ]; then
        INNER_CMD="cd '$WORKTREE_PATH' && $SETUP_CMD && echo '📋 Task: $TASK' && echo '' && ($CLAUDE_CMD || claude)"
    else
        INNER_CMD="cd '$WORKTREE_PATH' && $SETUP_CMD && echo '' && ($CLAUDE_CMD || claude)"
    fi
fi

# Launch based on terminal type
case "$TERMINAL" in
    ghostty)
        if ! command -v ghostty &> /dev/null && [ ! -d "/Applications/Ghostty.app" ]; then
            echo "Error: Ghostty not found"
            exit 1
        fi
        # Launch Ghostty with background color and title
        GHOSTTY_ARGS=(-e "$SHELL_CMD" -c "$INNER_CMD")
        if [ -n "$WORKTREE_BG" ]; then
            GHOSTTY_ARGS+=(--background="$WORKTREE_BG")
        fi
        if [ -n "$TAB_TITLE" ]; then
            GHOSTTY_ARGS+=(--title="$TAB_TITLE")
        fi
        open -na "Ghostty.app" --args "${GHOSTTY_ARGS[@]}"
        ;;

    iterm2|iterm)
        osascript <<EOF
tell application "iTerm2"
    create window with default profile
    tell current session of current window
        write text "cd '$WORKTREE_PATH' && $CLAUDE_CMD"
    end tell
end tell
EOF
        ;;

    tmux)
        if ! command -v tmux &> /dev/null; then
            echo "Error: tmux not found"
            exit 1
        fi
        SESSION_NAME="wt-$PROJECT-$(echo "$BRANCH" | tr '/' '-')"
        tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_PATH" "$SHELL_CMD -c '$CLAUDE_CMD'"
        echo "   tmux session: $SESSION_NAME (attach with: tmux attach -t $SESSION_NAME)"
        ;;

    wezterm)
        if ! command -v wezterm &> /dev/null; then
            echo "Error: WezTerm not found"
            exit 1
        fi
        wezterm start --cwd "$WORKTREE_PATH" -- "$SHELL_CMD" -c "$INNER_CMD"
        ;;

    kitty)
        if ! command -v kitty &> /dev/null; then
            echo "Error: Kitty not found"
            exit 1
        fi
        kitty --detach --directory "$WORKTREE_PATH" "$SHELL_CMD" -c "$INNER_CMD"
        ;;

    alacritty)
        if ! command -v alacritty &> /dev/null; then
            echo "Error: Alacritty not found"
            exit 1
        fi
        alacritty --working-directory "$WORKTREE_PATH" -e "$SHELL_CMD" -c "$INNER_CMD" &
        ;;

    *)
        echo "Error: Unknown terminal type: $TERMINAL"
        echo "Supported: ghostty, iterm2, tmux, wezterm, kitty, alacritty"
        exit 1
        ;;
esac

echo "✅ Launched Claude Code agent"
echo "   Terminal: $TERMINAL"
echo "   Project: $PROJECT"
echo "   Branch: $BRANCH"
if [ -n "$WORKTREE_COLOR" ]; then
    echo "   Visual: $WORKTREE_EMOJI $WORKTREE_COLOR"
fi
echo "   Path: $WORKTREE_PATH"
if [ -n "$TASK" ]; then
    echo "   Task: $TASK"
fi
