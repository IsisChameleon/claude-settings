#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory from workspace
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')

# Get git branch (skip optional locks for better performance)
git_branch=$(cd "$current_dir" 2>/dev/null && git --no-optional-locks branch --show-current 2>/dev/null)

# Extract token usage information
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Build status line with bold colors
# Bold colors: \033[1;34m for blue, \033[1;32m for green, \033[1;33m for yellow
# Reset: \033[0m

status=""

# Current directory (bold blue)
if [ -n "$current_dir" ]; then
    dir_name=$(basename "$current_dir")
    status="${status}$(printf '\033[1;34m%s\033[0m' "$dir_name")"
fi

# Git branch (bold green)
if [ -n "$git_branch" ]; then
    [ -n "$status" ] && status="${status} "
    status="${status}$(printf '\033[1;32m%s\033[0m' "$git_branch")"
fi

# Token usage (bold yellow)
if [ -n "$used_pct" ]; then
    [ -n "$status" ] && status="${status} "
    status="${status}$(printf '\033[1;33mtokens: %s%% (%s in / %s out)\033[0m' "$used_pct" "$total_input" "$total_output")"
fi

echo "$status"
