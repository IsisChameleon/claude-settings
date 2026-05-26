---
name: update-playwright-token
description: Use when user says /update-playwright-token to update the Playwright MCP extension token and restart the server
---

# Update Playwright Token

Updates the Playwright MCP browser extension token and restarts the MCP server.

## Usage

```
/update-playwright-token <TOKEN>
```

## Steps

1. Read the argument as the new token value
2. Update the file `/Users/isabelleredactive/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json` — set the new token under `env.PLAYWRIGHT_MCP_EXTENSION_TOKEN`. The token MUST be an environment variable; `@playwright/mcp` does not accept it as a CLI flag (there is no `--extension-token`). The CLI side just needs the bare `--extension` flag, otherwise the server spawns its own headless Chromium and ignores the bridge entirely. Correct shape:
   ```json
   {
     "playwright": {
       "command": "npx",
       "args": [
         "@playwright/mcp@latest",
         "--extension"
       ],
       "env": {
         "PLAYWRIGHT_MCP_EXTENSION_TOKEN": "<TOKEN>"
       }
     }
   }
   ```
3. After updating the file, run `/mcp` to restart MCP servers so the new token takes effect
4. Confirm the update to the user
