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
2. Update the file `/Users/isabelleredactive/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json` — replace the existing token in the `args` array with the new one. The config structure is:
   ```json
   {
     "playwright": {
       "command": "npx",
       "args": [
         "@playwright/mcp@latest",
         "--extension-token",
         "<TOKEN>"
       ]
     }
   }
   ```
3. After updating the file, run `/mcp` to restart MCP servers so the new token takes effect
4. Confirm the update to the user
