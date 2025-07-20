#!/bin/bash

# Test the Node.js MCP update script
# Note: We don't use 'set -e' because we handle errors explicitly

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🧪 Testing MCP update with Node.js script..."

# Find the script relative to the project root BEFORE changing directories
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$(dirname "$0")")")" && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/fix-mcp-json.js"

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Basic update
echo -e "\n1️⃣ Testing basic npx replacement..."
cat > mcp.json << 'EOF'
{
  "mcpServers": {
    "claude-flow": {
      "command": "npx",
      "args": ["claude-flow@alpha", "mcp", "start"],
      "type": "stdio"
    },
    "ruv-swarm": {
      "command": "npx",
      "args": ["ruv-swarm@latest", "mcp", "start"],
      "type": "stdio"
    }
  }
}
EOF
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}❌ Script not found at: $SCRIPT_PATH${NC}"
    ((TESTS_FAILED++))
elif node "$SCRIPT_PATH" mcp.json 2>&1; then
    if grep -q '"command": "claude-flow"' mcp.json && grep -q '"command": "ruv-swarm"' mcp.json; then
        echo -e "${GREEN}✅ Basic replacement works${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Basic replacement failed${NC}"
        cat mcp.json
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}❌ Script execution failed with exit code: $?${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Preserve other servers
echo -e "\n2️⃣ Testing preservation of other servers..."
cat > mcp.json << 'EOF'
{
  "mcpServers": {
    "claude-flow": {
      "command": "npx",
      "args": ["claude-flow@alpha", "mcp", "start"],
      "type": "stdio"
    },
    "custom-server": {
      "command": "my-custom-command",
      "args": ["--port", "3000"],
      "type": "stdio"
    }
  }
}
EOF

if node "$SCRIPT_PATH" mcp.json; then
    if grep -q '"command": "claude-flow"' mcp.json && grep -q '"command": "my-custom-command"' mcp.json; then
        echo -e "${GREEN}✅ Other servers preserved${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Other servers not preserved${NC}"
        cat mcp.json
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}❌ Script execution failed for preservation test${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: Already correct entries
echo -e "\n3️⃣ Testing skip of already correct entries..."
cat > mcp.json << 'EOF'
{
  "mcpServers": {
    "claude-flow": {
      "command": "claude-flow",
      "args": ["mcp", "start"],
      "type": "stdio"
    }
  }
}
EOF

cp mcp.json mcp.json.original

if node "$SCRIPT_PATH" mcp.json; then
    if diff -q mcp.json mcp.json.original > /dev/null; then
        echo -e "${GREEN}✅ Already correct entries unchanged${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Already correct entries were modified${NC}"
        echo "Original:"
        cat mcp.json.original
        echo "Modified:"
        cat mcp.json
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}❌ Script execution failed for unchanged test${NC}"
    ((TESTS_FAILED++))
fi

# Test 4: No mcp.json file
echo -e "\n4️⃣ Testing missing file handling..."
rm -f mcp.json
if node "$SCRIPT_PATH" mcp.json; then
    echo -e "${GREEN}✅ Missing file handled gracefully${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Script failed on missing file (expected behavior for this test)${NC}"
    ((TESTS_FAILED++))
fi

# Clean up
cd "$OLDPWD" 2>/dev/null || true
rm -rf "$TEMP_DIR"

# Summary
echo -e "\n📊 Test Summary:"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    exit 1
fi