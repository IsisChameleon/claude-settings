# Claude Code Notes

## Plugin Marketplace

### Adding a marketplace

```bash
/plugin marketplace add pipecat-ai/skills
```

**What it does**: Adds a third-party skill marketplace to Claude Code. In this case, it registers the `pipecat-ai/skills` repository as a marketplace source named `pipecat-skills`. Once added, skills published in that marketplace become available for use with the `/plugin` command. This lets you install and use community-contributed skills (e.g., from the Pipecat AI project) directly within Claude Code.

### Installing a plugin from a marketplace

```bash
/plugin install pipecat-mcp-server@pipecat-skills
```

**What it does**: Installs a specific plugin from a registered marketplace. The format is `<plugin-name>@<marketplace-name>`. Here it installs the `pipecat-mcp-server` plugin from the `pipecat-skills` marketplace. After installation, restart Claude Code to load the new plugin. This makes the plugin's skills available (e.g., `pipecat-mcp-server:init`, `pipecat-mcp-server:deploy`, `pipecat-mcp-server:talk`, etc.).

## Pipecat MCP Server (Voice)

### Setup (one-time)

```bash
# Clone the repo
git clone https://github.com/pipecat-ai/pipecat-mcp-server.git ~/src/pipecat-mcp-server

# Install as editable uv tool
uv tool install -e /Users/isabelleredactive/src/pipecat-mcp-server

# Register with Claude Code (must use http transport, not stdio)
claude mcp add pipecat --transport http http://localhost:9090/mcp --scope user

# Install the talk skill plugin (run inside Claude Code)
# /plugin marketplace add pipecat-ai/skills
# /plugin install pipecat-mcp-server@pipecat-skills
```

### Starting a voice session

1. Start the server in a separate terminal:
   ```bash
   pipecat-mcp-server
   ```
   Server runs at `http://localhost:9090/mcp`

2. Open the Pipecat Playground at http://localhost:7860 in your browser (this handles audio I/O)

3. Start or restart Claude Code, then run `/talk`

### Notes

- Models (~1.5 GB) download on first connection, so initial startup is slow
- The MCP server must be running before starting Claude Code (or restart Claude Code after starting it)
- Audio goes through the browser playground, not Claude Code itself
- Source repo: `~/src/pipecat-mcp-server` (installed as editable, so local changes take effect)

## Excalidraw MCP Server

Provides 26 tools for creating/editing Excalidraw diagrams: element CRUD, layout, grouping, scene management, export (image/URL/mermaid), snapshots, and more.

### Setup (one-time)

```bash
# Clone the repo
git clone https://github.com/yctimlin/mcp_excalidraw.git ~/src/mcp_excalidraw

# Install dependencies and build
cd ~/src/mcp_excalidraw
npm ci
npm run build

# Register with Claude Code (user scope)
claude mcp add excalidraw --scope user \
  -e EXPRESS_SERVER_URL=http://localhost:3000 \
  -e ENABLE_CANVAS_SYNC=true \
  -- node /Users/isabelleredactive/src/mcp_excalidraw/dist/index.js
```

### Starting a session

1. Start the canvas server in a separate terminal:
   ```bash
   cd ~/src/mcp_excalidraw && HOST=0.0.0.0 PORT=3000 npm run canvas
   ```
   Canvas runs at `http://localhost:3000`

2. Start or restart Claude Code — the MCP server launches automatically via stdio

### Verification

```bash
claude mcp list        # should show excalidraw: ✓ Connected
claude mcp get excalidraw
```

### Notes

- Requires Node.js >= 18
- The canvas server must be running for real-time sync features (ENABLE_CANVAS_SYNC=true)
- Source repo: `~/src/mcp_excalidraw`
- To remove: `claude mcp remove excalidraw -s user`
- GitHub: https://github.com/yctimlin/mcp_excalidraw
