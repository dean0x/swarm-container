#!/bin/bash
set -euo pipefail

echo "🔧 Remote MCP Setup Helper"
echo "========================="
echo ""

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

SSH_CMD="ssh -p 10022 node@${APP_NAME}.fly.dev"

echo "🎯 Setting up MCP on: $APP_NAME"
echo ""

# Step 1: Run MCP setup remotely
echo "1. Running MCP setup script..."
$SSH_CMD "cd /workspace && bash scripts/hooks/modules/setup-mcp.sh" || {
    echo "❌ Failed to run MCP setup"
    exit 1
}

# Step 2: Verify configuration
echo ""
echo "2. Verifying MCP configuration..."
if $SSH_CMD "test -f ~/.claude.json && grep -q 'mcpServers' ~/.claude.json"; then
    echo "✅ MCP configuration created"
else
    echo "❌ MCP configuration not found"
    exit 1
fi

# Step 3: List configured servers
echo ""
echo "3. Configured MCP servers:"
$SSH_CMD "claude mcp list" || echo "⚠️  Could not list servers"

# Step 4: Set API key if needed
echo ""
echo "4. API Key configuration:"
if $SSH_CMD "test -n \"\${ANTHROPIC_API_KEY:-}\""; then
    echo "✅ API key is configured"
else
    echo "⚠️  No API key found"
    echo ""
    echo "To set API key:"
    echo "  fly secrets set ANTHROPIC_API_KEY=sk-ant-... -a $APP_NAME"
fi

echo ""
echo "✅ MCP setup complete!"
echo ""
echo "💡 Tips:"
echo "• Use 'claude mcp list' to see available servers"
echo "• MCP servers run locally in the container"
echo "• Configuration persists across deployments"