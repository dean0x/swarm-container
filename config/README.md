# Configuration Files

This directory contains configuration files for the SwarmContainer.

## .mcp.config

This file configures MCP (Model Context Protocol) servers for Claude Code. The configuration is automatically merged into `/home/node/.claude.json` when the container starts.

### Structure

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["package-name"],
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

### Environment Variables

You can use environment variables in the configuration using the syntax `${VARIABLE_NAME}` or `${VARIABLE_NAME:-default_value}`.

### Customization

To add or modify MCP servers:

1. Edit `.mcp.config` in this directory
2. Rebuild or restart the container
3. The changes will be automatically applied to Claude's configuration

### Default MCP Servers

- **browser-tools**: Browser automation and web scraping
- **playwright**: Web testing and automation
- **tavily**: AI-powered search (requires TAVILY_API_KEY)
- **browsermcp**: Browser interaction capabilities
- **context7**: Context management and retrieval

### API Keys

Some MCP servers require API keys. Set these as environment variables:

```bash
export TAVILY_API_KEY="your-api-key-here"
```

Or add them to your `.env` file if using docker-compose.

## Automatic Configuration Updates

The container includes an optional file watcher that automatically updates Claude's configuration when you modify `.mcp.config`.

### Enabling the File Watcher

Set the environment variable before starting the container:

```bash
export ENABLE_MCP_WATCHER=true
```

Or add to your VS Code settings:

```json
{
  "remote.containers.defaultExtensions": [],
  "remote.containers.env": {
    "ENABLE_MCP_WATCHER": "true"
  }
}
```

### Manual Control

If the watcher is not enabled at startup, you can control it manually:

```bash
# Start the watcher
mcp-watcher-start

# Check status
mcp-watcher-status

# Stop the watcher
mcp-watcher-stop

# View logs
mcp-watcher-logs

# Manually update MCP config
mcp-update
```

### How It Works

1. The watcher monitors `.mcp.config` for changes
2. When a change is detected, it waits 2 seconds (debounce)
3. Validates the JSON syntax
4. Runs the MCP setup script to merge changes
5. Logs all activity to `/tmp/mcp-watcher.log`

### Notes

- Changes are applied immediately without container restart
- Invalid JSON will be rejected (check logs)
- The watcher uses minimal resources (inotify)