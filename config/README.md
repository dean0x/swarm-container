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