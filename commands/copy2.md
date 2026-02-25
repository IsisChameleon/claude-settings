# Copy your most recent response to the clipboard as clean text.

Recall the text you output immediately before this command was invoked
Copy it to the system clipboard:
    macOS: printf '%s' '...' | pbcopy
    Linux: xclip -selection clipboard or xsel --clipboard
    Windows/WSL: clip.exe
For multi-line text, use a heredoc or properly escaped string

If the last response was very long, confirm before copying
Confirm to the user that the text was copied.