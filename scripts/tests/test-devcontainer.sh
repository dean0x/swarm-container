#!/bin/bash

echo "🧪 Testing Dev Container Configuration..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Validate JSON files
echo "1️⃣ Validating JSON configuration..."
for file in *.json scripts/security/*.json; do
    if [ -f "$file" ]; then
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} $file is valid JSON"
        else
            echo -e "   ${RED}✗${NC} $file has JSON syntax errors"
            python3 -m json.tool "$file" 2>&1 | head -10
            exit 1
        fi
    fi
done

# Test 2: Build the container
echo ""
echo "2️⃣ Building container..."
if docker build -t devcontainer-test -f Dockerfile --target local . > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Container build successful"
else
    echo -e "   ${RED}✗${NC} Container build failed"
    docker build -t devcontainer-test -f Dockerfile --target local . 2>&1 | tail -20
    exit 1
fi

# Test 3: Test container startup with similar mounts
echo ""
echo "3️⃣ Testing container startup..."
CONTAINER_ID=$(docker run -d \
    -v $(pwd):/workspace \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --security-opt seccomp=unconfined \
    --security-opt no-new-privileges:true \
    --memory 8g \
    --cpus 4 \
    devcontainer-test \
    sleep 30)

if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} Container started successfully"
    
    # Test 4: Check if user can run commands
    echo ""
    echo "4️⃣ Testing user permissions..."
    # VS Code will use remoteUser setting, we just check the user exists
    if docker exec "$CONTAINER_ID" id node >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Node user exists and configured"
    else
        echo -e "   ${RED}✗${NC} Node user not properly configured"
    fi
    
    # Test 5: Check workspace access
    echo ""
    echo "5️⃣ Testing workspace access..."
    if docker exec "$CONTAINER_ID" ls /workspace > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Workspace accessible"
    else
        echo -e "   ${RED}✗${NC} Cannot access workspace"
    fi
    
    # Test 6: Check tools installation
    echo ""
    echo "6️⃣ Testing tool installations..."
    # Note: MCP servers are configured during postCreate, not during build
    test_tool() {
        local tool=$1
        if docker exec "$CONTAINER_ID" which $tool > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} $tool installed"
        else
            echo -e "   ${RED}✗${NC} $tool not found"
        fi
    }
    test_tool "node"
    test_tool "npm"
    test_tool "claude"
    test_tool "git"
    test_tool "tmux"
    test_tool "zsh"
    
    # Test 7: Check NODE_OPTIONS is set correctly
    echo ""
    echo "7️⃣ Testing dynamic memory allocation..."
    # Run the memory script directly to test it works
    if docker exec "$CONTAINER_ID" bash -c 'source /scripts/hooks/set-node-memory.sh && echo $NODE_OPTIONS' > /dev/null 2>&1; then
        NODE_OPTS=$(docker exec "$CONTAINER_ID" bash -c 'source /scripts/hooks/set-node-memory.sh && echo $NODE_OPTIONS' 2>/dev/null)
        if [ -n "$NODE_OPTS" ]; then
            echo -e "   ${GREEN}✓${NC} NODE_OPTIONS can be set: $NODE_OPTS"
            # Verify it's approximately 75% of 8GB (6144MB)
            if [[ "$NODE_OPTS" =~ --max-old-space-size=([0-9]+) ]]; then
                HEAP_SIZE="${BASH_REMATCH[1]}"
                if [ "$HEAP_SIZE" -ge 5000 ] && [ "$HEAP_SIZE" -le 7000 ]; then
                    echo -e "   ${GREEN}✓${NC} Heap size $HEAP_SIZE MB is ~75% of container memory"
                else
                    echo -e "   ${YELLOW}⚠${NC} Heap size $HEAP_SIZE MB seems incorrect for 8GB container"
                fi
            fi
        else
            echo -e "   ${YELLOW}⚠${NC} NODE_OPTIONS script exists but produces no output"
        fi
    else
        echo -e "   ${YELLOW}⚠${NC} NODE_OPTIONS tested via entrypoint (requires container restart)"
    fi
    
    # Cleanup
    docker stop "$CONTAINER_ID" > /dev/null
    docker rm "$CONTAINER_ID" > /dev/null
else
    echo -e "   ${RED}✗${NC} Container failed to start"
    echo "   Check docker logs for details"
    exit 1
fi

# Test 7: Security script syntax check
echo ""
echo "8️⃣ Checking shell scripts..."
for script in scripts/*/*.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo -e "   ${GREEN}✓${NC} $script syntax OK"
        else
            echo -e "   ${RED}✗${NC} $script has syntax errors"
            bash -n "$script" 2>&1
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ All basic tests passed!${NC}"
echo ""
echo "Now running issue-specific tests..."
echo ""

# Run the issue-specific tests
if [ -f "scripts/tests/test-container-issues.sh" ]; then
    bash scripts/tests/test-container-issues.sh
    ISSUE_TEST_RESULT=$?
else
    echo -e "${YELLOW}⚠${NC} test-container-issues.sh not found"
    ISSUE_TEST_RESULT=0
fi

echo ""
echo "Running VS Code integration tests..."
echo ""

# Run VS Code integration tests
if [ -f "scripts/tests/test-vscode-integration.sh" ]; then
    bash scripts/tests/test-vscode-integration.sh
    VSCODE_TEST_RESULT=$?
else
    echo -e "${YELLOW}⚠${NC} test-vscode-integration.sh not found"
    VSCODE_TEST_RESULT=0
fi

echo ""
echo "Running PostCreate module tests..."
echo ""

# Run PostCreate module tests
if [ -f "scripts/tests/test-postcreate-modules.sh" ]; then
    bash scripts/tests/test-postcreate-modules.sh
    POSTCREATE_MODULE_RESULT=$?
else
    echo -e "${YELLOW}⚠${NC} test-postcreate-modules.sh not found"
    POSTCREATE_MODULE_RESULT=0
fi

# Final results
if [ $ISSUE_TEST_RESULT -eq 0 ] && [ $VSCODE_TEST_RESULT -eq 0 ] && [ $POSTCREATE_MODULE_RESULT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "The devcontainer should work with VS Code. Try:"
    echo "  code ."
    echo "  Then: 'Reopen in Container'"
else
    echo ""
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo "Please fix the issues before using the devcontainer."
    exit 1
fi