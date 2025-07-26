# PostCreate Modules

This directory contains modular scripts that are called by the main `postCreate.sh` script. Each module handles a specific aspect of container initialization.

## Modules

### setup-permissions.sh
- Sets executable permissions on security scripts
- Ensures proper ownership of workspace directories
- Must run first to enable other scripts

### init-npm.sh
- Configures npm registry settings
- Sets up npm cache and prefix paths (if needed)

### init-claude-code.sh
- Checks for ANTHROPIC_API_KEY
- Initializes Claude Code if API key is present
- Provides instructions for authentication options

### setup-mcp.sh
- Reads MCP configuration from /workspace/.devcontainer/config/.mcp.config
- Merges mcpServers into /home/node/.claude.json
- Preserves existing .claude.json properties
- Substitutes environment variables for API keys

### setup-workspace.sh
- Creates workspace directory structure
- Manages .gitignore file creation/updates
- Sets proper permissions for workspace

### setup-shell.sh
- Installs Oh My Zsh plugins (autosuggestions, syntax highlighting)
- Creates shell history initialization script
- Adds useful commands to shell history
- Configures shell RC files

## Adding New Modules

To add a new module:

1. Create a new script in this directory
2. Make it executable: `chmod +x module-name.sh`
3. Add error handling (scripts should not use `set -e`)
4. Add the module call to `/scripts/hooks/postCreate.sh`

## Module Guidelines

- Each module should be self-contained
- Use clear echo statements to show progress
- Handle errors gracefully (don't exit on failure)
- Test for prerequisites before executing
- Clean up after themselves if needed

## Execution Order

The modules are executed in this order:
1. setup-permissions.sh (enables other scripts)
2. init-npm.sh (npm configuration)
3. init-claude-code.sh (Claude Code setup)
4. setup-mcp.sh (MCP servers configuration)
5. setup-workspace.sh (workspace structure)
6. setup-shell.sh (shell environment)

The order can be adjusted in `postCreate.sh` if dependencies change.