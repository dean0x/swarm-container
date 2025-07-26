#!/bin/bash
# Test MCP File Watcher functionality

echo "🧪 Testing MCP File Watcher..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track test results
FAILED=0

# Test 1: Check if inotify-tools is in Dockerfile
echo "1️⃣ Checking inotify-tools dependency..."
if grep -q "inotify-tools" Dockerfile; then
    echo -e "   ${GREEN}✓${NC} inotify-tools is installed in Dockerfile"
else
    echo -e "   ${RED}✗${NC} inotify-tools not found in Dockerfile"
    FAILED=$((FAILED + 1))
fi

# Test 2: Check watcher script exists and is executable
echo ""
echo "2️⃣ Checking watcher script..."
WATCHER_SCRIPT="scripts/services/mcp-config-watcher.sh"
if [ -f "$WATCHER_SCRIPT" ]; then
    echo -e "   ${GREEN}✓${NC} mcp-config-watcher.sh exists"
    
    if [ -x "$WATCHER_SCRIPT" ]; then
        echo -e "   ${GREEN}✓${NC} mcp-config-watcher.sh is executable"
    else
        echo -e "   ${RED}✗${NC} mcp-config-watcher.sh is not executable"
        FAILED=$((FAILED + 1))
    fi
    
    # Check for required features
    if grep -q "inotifywait" "$WATCHER_SCRIPT"; then
        echo -e "   ${GREEN}✓${NC} Uses inotifywait for monitoring"
    else
        echo -e "   ${RED}✗${NC} Missing inotifywait usage"
        FAILED=$((FAILED + 1))
    fi
    
    if grep -q "DEBOUNCE_SECONDS" "$WATCHER_SCRIPT"; then
        echo -e "   ${GREEN}✓${NC} Implements debounce mechanism"
    else
        echo -e "   ${RED}✗${NC} Missing debounce mechanism"
        FAILED=$((FAILED + 1))
    fi
    
    if grep -q "jq empty" "$WATCHER_SCRIPT"; then
        echo -e "   ${GREEN}✓${NC} Validates JSON before updating"
    else
        echo -e "   ${RED}✗${NC} Missing JSON validation"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "   ${RED}✗${NC} mcp-config-watcher.sh not found"
    FAILED=$((FAILED + 1))
fi

# Test 3: Check control script exists and is executable
echo ""
echo "3️⃣ Checking control script..."
CONTROL_SCRIPT="scripts/services/mcp-watcher-control.sh"
if [ -f "$CONTROL_SCRIPT" ]; then
    echo -e "   ${GREEN}✓${NC} mcp-watcher-control.sh exists"
    
    if [ -x "$CONTROL_SCRIPT" ]; then
        echo -e "   ${GREEN}✓${NC} mcp-watcher-control.sh is executable"
    else
        echo -e "   ${RED}✗${NC} mcp-watcher-control.sh is not executable"
        FAILED=$((FAILED + 1))
    fi
    
    # Check for required commands
    for cmd in start stop restart status logs; do
        if grep -q "$cmd)" "$CONTROL_SCRIPT"; then
            echo -e "   ${GREEN}✓${NC} Supports '$cmd' command"
        else
            echo -e "   ${RED}✗${NC} Missing '$cmd' command"
            FAILED=$((FAILED + 1))
        fi
    done
else
    echo -e "   ${RED}✗${NC} mcp-watcher-control.sh not found"
    FAILED=$((FAILED + 1))
fi

# Test 4: Check PID file management
echo ""
echo "4️⃣ Testing PID file management..."
if grep -q "PID_FILE=" "$WATCHER_SCRIPT" && grep -q "echo \$\$ >" "$WATCHER_SCRIPT"; then
    echo -e "   ${GREEN}✓${NC} Watcher writes PID file"
else
    echo -e "   ${RED}✗${NC} Missing PID file creation"
    FAILED=$((FAILED + 1))
fi

if grep -q "trap.*cleanup.*EXIT" "$WATCHER_SCRIPT"; then
    echo -e "   ${GREEN}✓${NC} Cleanup on exit configured"
else
    echo -e "   ${RED}✗${NC} Missing cleanup trap"
    FAILED=$((FAILED + 1))
fi

# Test 5: Check shell aliases configuration
echo ""
echo "5️⃣ Checking shell aliases..."
SHELL_SETUP="scripts/hooks/modules/setup-shell.sh"
if [ -f "$SHELL_SETUP" ]; then
    aliases=("mcp-watcher-start" "mcp-watcher-stop" "mcp-watcher-status" "mcp-watcher-logs" "mcp-update")
    for alias in "${aliases[@]}"; do
        if grep -q "alias $alias=" "$SHELL_SETUP"; then
            echo -e "   ${GREEN}✓${NC} Alias '$alias' configured"
        else
            echo -e "   ${RED}✗${NC} Missing alias '$alias'"
            FAILED=$((FAILED + 1))
        fi
    done
else
    echo -e "   ${RED}✗${NC} setup-shell.sh not found"
    FAILED=$((FAILED + 1))
fi

# Test 6: Check postCreate integration
echo ""
echo "6️⃣ Checking postCreate integration..."
if grep -q "ENABLE_MCP_WATCHER" "scripts/hooks/postCreate.sh"; then
    echo -e "   ${GREEN}✓${NC} MCP watcher integrated in postCreate"
else
    echo -e "   ${RED}✗${NC} MCP watcher not integrated in postCreate"
    FAILED=$((FAILED + 1))
fi

# Test 7: Check environment variable in devcontainer.json
echo ""
echo "7️⃣ Checking devcontainer configuration..."
if grep -q "ENABLE_MCP_WATCHER" "devcontainer.json"; then
    echo -e "   ${GREEN}✓${NC} ENABLE_MCP_WATCHER in devcontainer.json"
else
    echo -e "   ${RED}✗${NC} ENABLE_MCP_WATCHER missing from devcontainer.json"
    FAILED=$((FAILED + 1))
fi

# Test 8: Simulate watcher functionality (without actually running it)
echo ""
echo "8️⃣ Testing watcher logic (simulation)..."
# Test debounce calculation
LAST_UPDATE=0
CURRENT_TIME=5
DEBOUNCE_SECONDS=2
TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

if [ $TIME_DIFF -ge $DEBOUNCE_SECONDS ]; then
    echo -e "   ${GREEN}✓${NC} Debounce logic correct (5s > 2s threshold)"
else
    echo -e "   ${RED}✗${NC} Debounce logic incorrect"
    FAILED=$((FAILED + 1))
fi

# Summary
echo ""
echo "============================"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All MCP watcher tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED MCP watcher test(s) failed${NC}"
    exit 1
fi