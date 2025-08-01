#!/bin/bash
set -euo pipefail

echo "🔌 MCP Server SSH Test Suite"
echo "============================"
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

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SSH_CMD="ssh -p 10022 node@${APP_NAME}.fly.dev"

echo "🎯 Testing MCP on: $APP_NAME"
echo ""

# Test 1: Claude Code Installation
echo "Test 1: Claude Code availability..."
if $SSH_CMD "which claude" > /dev/null 2>&1; then
    CLAUDE_VERSION=$($SSH_CMD "claude --version" 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✅ Claude Code installed: $CLAUDE_VERSION${NC}"
else
    echo -e "${RED}❌ Claude Code not found${NC}"
    exit 1
fi

# Test 2: MCP Configuration
echo ""
echo "Test 2: MCP configuration..."
if $SSH_CMD "test -f ~/.claude.json" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MCP config exists${NC}"
    
    # Check config content
    CONFIG_SIZE=$($SSH_CMD "wc -c < ~/.claude.json" 2>/dev/null || echo "0")
    echo "   Config size: ${CONFIG_SIZE} bytes"
else
    echo -e "${YELLOW}⚠️  MCP config not found - may need initialization${NC}"
fi

# Test 3: List MCP Servers
echo ""
echo "Test 3: MCP server listing..."
MCP_OUTPUT=$($SSH_CMD "claude mcp list" 2>&1 || echo "Failed to list servers")
echo "$MCP_OUTPUT"

if echo "$MCP_OUTPUT" | grep -q "Available MCP servers"; then
    echo -e "${GREEN}✅ MCP servers accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Could not list MCP servers${NC}"
fi

# Test 4: Environment Variables
echo ""
echo "Test 4: MCP environment check..."
ENV_VARS=$($SSH_CMD "env | grep -E 'ANTHROPIC|CLAUDE|MCP' | sort" 2>/dev/null || echo "")
if [ -n "$ENV_VARS" ]; then
    echo "$ENV_VARS"
    echo -e "${GREEN}✅ Environment configured${NC}"
else
    echo -e "${YELLOW}⚠️  No MCP-related environment variables found${NC}"
fi

# Test 5: File System Access for MCP
echo ""
echo "Test 5: MCP file access test..."
$SSH_CMD "mkdir -p /workspace/.claude/test" 2>/dev/null
if $SSH_CMD "echo 'MCP test' > /workspace/.claude/test/mcp-test.txt && cat /workspace/.claude/test/mcp-test.txt" 2>/dev/null | grep -q "MCP test"; then
    echo -e "${GREEN}✅ MCP can write to workspace${NC}"
    $SSH_CMD "rm -rf /workspace/.claude/test" 2>/dev/null
else
    echo -e "${RED}❌ MCP file access issue${NC}"
fi

# Test 6: Node.js Availability (for MCP servers)
echo ""
echo "Test 6: Node.js for MCP servers..."
NODE_VERSION=$($SSH_CMD "node --version" 2>/dev/null || echo "Not found")
NPM_VERSION=$($SSH_CMD "npm --version" 2>/dev/null || echo "Not found")
echo "Node: $NODE_VERSION, npm: $NPM_VERSION"

if [[ "$NODE_VERSION" == v* ]]; then
    echo -e "${GREEN}✅ Node.js available for MCP${NC}"
else
    echo -e "${RED}❌ Node.js not available${NC}"
fi

# Test 7: MCP Server Execution Test
echo ""
echo "Test 7: MCP server execution..."
# Try to initialize MCP if not already done
$SSH_CMD "cd /workspace && bash scripts/hooks/modules/setup-mcp.sh" > /dev/null 2>&1 || true

# Check if any MCP servers are configured
if $SSH_CMD "test -f ~/.claude.json && grep -q 'mcpServers' ~/.claude.json" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MCP servers configured${NC}"
else
    echo -e "${YELLOW}⚠️  No MCP servers in configuration${NC}"
fi

echo ""
echo "======================================"
echo "🎯 MCP SSH Test Summary:"
echo ""
echo "• Claude Code: $([ -n "$CLAUDE_VERSION" ] && echo "✅ Installed" || echo "❌ Missing")"
echo "• MCP Config: $($SSH_CMD "test -f ~/.claude.json" && echo "✅ Present" || echo "⚠️  Missing")"
echo "• Node.js: $([ "$NODE_VERSION" != "Not found" ] && echo "✅ Available" || echo "❌ Missing")"
echo ""

# Final connectivity test through Claude
echo "Test 8: Claude connectivity test..."
TEST_RESULT=$($SSH_CMD "echo 'test' | claude 'Echo back the input'" 2>&1 || echo "Failed")
if echo "$TEST_RESULT" | grep -qi "test"; then
    echo -e "${GREEN}✅ Claude fully functional over SSH${NC}"
else
    echo -e "${YELLOW}⚠️  Claude may need API key configuration${NC}"
    echo "   Set with: fly secrets set ANTHROPIC_API_KEY=sk-ant-..."
fi