# Task 009: Test MCP Over SSH

## Objective
Verify that MCP (Model Context Protocol) servers work correctly when accessing SwarmContainer through SSH on Fly.io.

## Prerequisites
- [ ] Task 008 completed: SSH connectivity verified
- [ ] MCP servers configured in SwarmContainer

## Workflow

### 1. Prerequisites Check
- SSH access working to Fly.io container
- Claude Code installed in container
- MCP configuration exists

### 2. Implementation

#### Step 2.1: Create MCP Test Script
Create `scripts/tests/test-fly-mcp.sh`:

```bash
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
```

#### Step 2.2: Create MCP Remote Setup Helper
Create `scripts/fly-mcp-setup.sh`:

```bash
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
```

#### Step 2.3: Update fly-entrypoint.sh for MCP
Add MCP initialization to `fly-entrypoint.sh`:

```bash
# After workspace setup, add:

# Initialize MCP if config exists
if [ -f /workspace/scripts/hooks/modules/setup-mcp.sh ]; then
    echo "🔌 Initializing MCP servers..."
    cd /workspace
    bash scripts/hooks/modules/setup-mcp.sh || echo "⚠️  MCP setup failed - can be run later"
fi

# Ensure Claude config directory exists
mkdir -p ~/.claude

# If API key is provided via secrets, export it
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    export ANTHROPIC_API_KEY
    echo "✅ API key configured from secrets"
fi
```

### 3. Testing

#### Test 3.1: Deploy and Test
```bash
# Deploy with MCP support
fly deploy

# Run MCP tests
./scripts/tests/test-fly-mcp.sh

# Setup MCP if needed
./scripts/fly-mcp-setup.sh
```

#### Test 3.2: Interactive MCP Test
```bash
# SSH in and test MCP servers
ssh -p 10022 node@your-app.fly.dev

# Inside container:
claude mcp list
claude "Create a simple hello world Python script"
```

### 4. Documentation

Add MCP over SSH section:

```markdown
## MCP Servers Over SSH

MCP servers run locally within the Fly.io container, providing the same low-latency experience as local development.

### Setup
1. Deploy your container: `fly deploy`
2. Configure MCP: `./scripts/fly-mcp-setup.sh`
3. Set API key: `fly secrets set ANTHROPIC_API_KEY=sk-ant-...`

### Usage
Connect via SSH and use Claude normally:
```bash
ssh -p 10022 node@your-app.fly.dev
claude "Your prompt here"
```

### VS Code Integration
When connected via Remote-SSH, MCP servers work seamlessly:
1. Connect to remote container
2. Open integrated terminal
3. Use `claude` command as usual

### Troubleshooting
- If MCP servers aren't listed: Run setup-mcp.sh again
- If API key issues: Check with `fly secrets list`
- For server errors: Check logs in container
```

### 5. Completion Criteria
- [ ] MCP test script comprehensive
- [ ] Setup helper works reliably  
- [ ] MCP initializes on container start
- [ ] API key handling secure
- [ ] Documentation complete
- [ ] All tests pass

## MCP Behavior Over SSH

### Expected Functionality
- All MCP servers work identically to local
- File operations use remote filesystem
- Browser automation may need X11 forwarding
- Network operations use container's network

### Limitations
- GUI tools require X11 forwarding setup
- Some MCP servers may need additional config
- Performance depends on SSH latency

## Security Considerations
- API keys stored in Fly secrets (encrypted)
- MCP servers can only access container filesystem
- Network access controlled by security preset
- No external MCP server connections

## Performance Notes
- MCP servers run in-container (no network latency)
- File operations are local to container
- Only SSH connection adds latency
- Consider region selection for best performance