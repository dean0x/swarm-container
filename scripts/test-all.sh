#!/bin/bash
# Comprehensive test runner for SwarmContainer

echo "🧪 SwarmContainer Test Suite"
echo "============================"
echo ""

# Track overall results
FAILED_TESTS=0
TOTAL_TESTS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to run a test and track results
run_test() {
    local test_name=$1
    local test_script=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}▶ Running: $test_name${NC}"
    echo "----------------------------------------"
    
    if [ -f "$test_script" ]; then
        if bash "$test_script"; then
            echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        else
            echo -e "${RED}❌ $test_name: FAILED${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  $test_name: SKIPPED (script not found)${NC}"
    fi
    
    echo ""
}

# Start time
START_TIME=$(date +%s)

# Run all tests
run_test "Dev Container Configuration" "scripts/tests/test-devcontainer.sh"
run_test "PostCreate Modules" "scripts/tests/test-postcreate-modules.sh"
run_test "MCP Configuration" "scripts/tests/test-mcp-config.sh"
run_test "MCP File Watcher" "scripts/tests/test-mcp-watcher.sh"
run_test "MCP Integration" "scripts/tests/test-mcp-integration.sh"

# Additional focused tests (optional, not in main suite to avoid duplication)
if [ "$1" == "--full" ]; then
    echo -e "${BLUE}Running extended test suite...${NC}"
    run_test "PostCreate Runtime" "scripts/tests/test-postcreate-runtime.sh"
fi

# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Summary
echo "============================"
echo -e "${BLUE}📊 Test Summary${NC}"
echo "============================"
echo "Total tests run: $TOTAL_TESTS"
echo "Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "Failed: $FAILED_TESTS"
echo "Duration: ${DURATION}s"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS test(s) failed${NC}"
    exit 1
fi