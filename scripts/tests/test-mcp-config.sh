#!/bin/bash
# Test MCP Configuration functionality

echo "🧪 Testing MCP Configuration..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track test results
FAILED=0

# Test 1: Validate default .mcp.config JSON syntax
echo "1️⃣ Validating default .mcp.config..."
if [ -f "config/.mcp.config" ]; then
    # Try jq first, fall back to python
    if command -v jq >/dev/null 2>&1; then
        if jq empty config/.mcp.config 2>/dev/null; then
            echo -e "   ${GREEN}✓${NC} .mcp.config has valid JSON syntax (jq)"
        else
            echo -e "   ${RED}✗${NC} .mcp.config has invalid JSON syntax"
            jq . config/.mcp.config 2>&1 | head -10
            FAILED=$((FAILED + 1))
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -m json.tool config/.mcp.config >/dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} .mcp.config has valid JSON syntax (python)"
        else
            echo -e "   ${RED}✗${NC} .mcp.config has invalid JSON syntax"
            python3 -m json.tool config/.mcp.config 2>&1 | head -10
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "   ${YELLOW}⚠${NC} Cannot validate JSON (jq/python3 not found)"
    fi
else
    echo -e "   ${RED}✗${NC} config/.mcp.config not found"
    FAILED=$((FAILED + 1))
fi

# Test 2: Check MCP setup module exists and is executable
echo ""
echo "2️⃣ Checking MCP setup module..."
MODULE_PATH="scripts/hooks/modules/setup-mcp.sh"
if [ -f "$MODULE_PATH" ]; then
    echo -e "   ${GREEN}✓${NC} setup-mcp.sh exists"
    
    if [ -x "$MODULE_PATH" ]; then
        echo -e "   ${GREEN}✓${NC} setup-mcp.sh is executable"
    else
        echo -e "   ${RED}✗${NC} setup-mcp.sh is not executable"
        FAILED=$((FAILED + 1))
    fi
    
    # Check for required commands in the script
    if grep -q "jq" "$MODULE_PATH" && grep -q "envsubst" "$MODULE_PATH"; then
        echo -e "   ${GREEN}✓${NC} setup-mcp.sh uses required tools (jq, envsubst)"
    else
        echo -e "   ${RED}✗${NC} setup-mcp.sh missing required tool usage"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "   ${RED}✗${NC} setup-mcp.sh not found"
    FAILED=$((FAILED + 1))
fi

# Test 3: Test JSON merge functionality (simulated)
echo ""
echo "3️⃣ Testing JSON merge logic..."

if command -v jq >/dev/null 2>&1; then
    # Create test files
    TEST_DIR="/tmp/mcp-test-$$"
    mkdir -p "$TEST_DIR"

    # Create a mock .claude.json with existing properties
    cat > "$TEST_DIR/.claude.json" << 'EOF'
{
  "existingProp": "should-be-preserved",
  "mcpServers": {
    "old-server": {
      "command": "old-command"
    }
  },
  "anotherProp": {
    "nested": "value"
  }
}
EOF

    # Create a test MCP config
    cat > "$TEST_DIR/.mcp.config" << 'EOF'
{
  "mcpServers": {
    "new-server": {
      "command": "new-command"
    }
  }
}
EOF

    # Test the merge logic with jq
    MERGED=$(jq -s '.[0] * {"mcpServers": .[1].mcpServers}' "$TEST_DIR/.claude.json" "$TEST_DIR/.mcp.config" 2>/dev/null)

    if echo "$MERGED" | jq -e '.existingProp == "should-be-preserved"' >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Existing properties preserved during merge"
    else
        echo -e "   ${RED}✗${NC} Existing properties lost during merge"
        FAILED=$((FAILED + 1))
    fi

    if echo "$MERGED" | jq -e '.mcpServers["new-server"].command == "new-command"' >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} New MCP servers added correctly"
    else
        echo -e "   ${RED}✗${NC} New MCP servers not added correctly"
        FAILED=$((FAILED + 1))
    fi

    # Clean up
    rm -rf "$TEST_DIR"
else
    echo -e "   ${YELLOW}⚠${NC} Skipping merge test (jq not available)"
fi

# Test 4: Test environment variable substitution
echo ""
echo "4️⃣ Testing environment variable substitution..."
TEST_VAR="test-value-123"
export TEST_VAR

# Create test config with env var
TEST_CONFIG='{"mcpServers": {"test": {"env": {"API_KEY": "${TEST_VAR}"}}}}'
RESULT=$(echo "$TEST_CONFIG" | envsubst)

if echo "$RESULT" | grep -q "test-value-123"; then
    echo -e "   ${GREEN}✓${NC} Environment variables substituted correctly"
else
    echo -e "   ${RED}✗${NC} Environment variable substitution failed"
    FAILED=$((FAILED + 1))
fi

# Test 5: Check for required dependencies in Dockerfile
echo ""
echo "5️⃣ Checking Dockerfile dependencies..."
if grep -q "jq" Dockerfile; then
    echo -e "   ${GREEN}✓${NC} jq is installed in Dockerfile"
else
    echo -e "   ${RED}✗${NC} jq not found in Dockerfile"
    FAILED=$((FAILED + 1))
fi

if grep -q "gettext-base" Dockerfile; then
    echo -e "   ${GREEN}✓${NC} gettext-base (envsubst) is installed in Dockerfile"
else
    echo -e "   ${RED}✗${NC} gettext-base not found in Dockerfile"
    FAILED=$((FAILED + 1))
fi

# Test 6: Validate MCP server structure
echo ""
echo "6️⃣ Validating MCP server configurations..."
if [ -f "config/.mcp.config" ]; then
    if command -v jq >/dev/null 2>&1; then
        # Check each server has required fields
        SERVERS=$(jq -r '.mcpServers | keys[]' config/.mcp.config 2>/dev/null)
        for server in $SERVERS; do
            if jq -e ".mcpServers[\"$server\"] | has(\"command\")" config/.mcp.config >/dev/null 2>&1; then
                echo -e "   ${GREEN}✓${NC} $server has required 'command' field"
            else
                echo -e "   ${RED}✗${NC} $server missing 'command' field"
                FAILED=$((FAILED + 1))
            fi
        done
    else
        echo -e "   ${YELLOW}⚠${NC} Skipping structure validation (jq not available)"
    fi
fi

# Summary
echo ""
echo "============================"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All MCP configuration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED MCP configuration test(s) failed${NC}"
    exit 1
fi