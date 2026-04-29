---
name: start-excalidraw
description: "Start the Excalidraw MCP canvas on localhost:3333. Use when user says 'start excalidraw', 'open excalidraw', 'start the canvas', or wants to draw diagrams."
allowed-tools:
  - Bash(cmd:cd /Users/isabelleredactive/src/mcp_excalidraw && HOST=0.0.0.0 PORT=3333 npm run canvas)
  - Bash(cmd:curl -s http://localhost:3333/health)
---

# Start Excalidraw Canvas

Starts the Excalidraw MCP canvas server on localhost:3333.

## Workflow

### Step 1: Check if already running

```bash
curl -s http://localhost:3333/health
```

If the health check succeeds, tell the user the canvas is already running and skip to Step 3.

### Step 2: Start the canvas

Run in the background:

```bash
cd /Users/isabelleredactive/src/mcp_excalidraw && HOST=0.0.0.0 PORT=3333 npm run canvas
```

Wait a few seconds, then verify with the health check:

```bash
curl -s http://localhost:3333/health
```

### Step 3: Confirm

Tell the user the Excalidraw canvas is running at http://localhost:3333 and the MCP tools are now available.
