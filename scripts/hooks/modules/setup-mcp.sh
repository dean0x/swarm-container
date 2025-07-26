#!/bin/bash
# Module: MCP Setup
# Purpose: Configure MCP servers in .claude.json from .mcp.config

echo "🔧 Setting up MCP configuration..."

MCP_CONFIG_PATH="/workspace/.devcontainer/config/.mcp.config"
CLAUDE_JSON_PATH="/home/node/.claude.json"

# Check if .mcp.config exists
if [ ! -f "$MCP_CONFIG_PATH" ]; then
    echo "⚠️  No .mcp.config found at $MCP_CONFIG_PATH, skipping MCP setup"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Cannot merge MCP configuration."
    exit 1
fi

# Create .claude.json if it doesn't exist
if [ ! -f "$CLAUDE_JSON_PATH" ]; then
    echo "📝 Creating new .claude.json file..."
    echo '{}' > "$CLAUDE_JSON_PATH"
fi

# Read the MCP configuration
echo "📖 Reading MCP configuration..."
MCP_CONFIG=$(cat "$MCP_CONFIG_PATH")

# Substitute environment variables in the config
# This handles ${VARIABLE_NAME:-default_value} syntax
echo "🔄 Substituting environment variables..."
MCP_CONFIG=$(echo "$MCP_CONFIG" | envsubst)

# Extract just the mcpServers object from the config
MCP_SERVERS=$(echo "$MCP_CONFIG" | jq -r '.mcpServers // {}')

# Read existing .claude.json
EXISTING_CONFIG=$(cat "$CLAUDE_JSON_PATH")

# Merge the mcpServers into the existing configuration
# This preserves all other properties and only updates/adds the root-level mcpServers
echo "🔀 Merging MCP servers configuration..."
UPDATED_CONFIG=$(echo "$EXISTING_CONFIG" | jq --argjson servers "$MCP_SERVERS" '.mcpServers = $servers')

# Write the updated configuration back
echo "$UPDATED_CONFIG" | jq '.' > "$CLAUDE_JSON_PATH"

# Ensure proper ownership
chown node:node "$CLAUDE_JSON_PATH"

# Count configured servers
SERVER_COUNT=$(echo "$MCP_SERVERS" | jq 'keys | length')

echo "✅ MCP configuration complete! Configured $SERVER_COUNT MCP servers:"
echo "$MCP_SERVERS" | jq -r 'keys[]' | sed 's/^/   - /'

# Show warning for any missing API keys
if echo "$MCP_CONFIG" | grep -q '\${.*API_KEY.*:-}'; then
    echo ""
    echo "⚠️  Note: Some MCP servers may require API keys to be set as environment variables"
fi