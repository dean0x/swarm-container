#!/bin/bash
# Runtime integration tests for SwarmContainer
# Run these tests INSIDE the container to verify functionality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Test helper functions
test_pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    ((TESTS_PASSED++)) || true
}

test_fail() {
    echo -e "${RED}FAIL${NC}: $1"
    FAILED_TESTS+=("$1: $2")
    ((TESTS_FAILED++)) || true
}

test_skip() {
    echo -e "${YELLOW}SKIP${NC}: $1 - $2"
    ((TESTS_SKIPPED++)) || true
}

echo -e "${BLUE}===========================================>${NC}"
echo -e "${BLUE}  SwarmContainer Runtime Integration Tests${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# ===========================================
# Test 1: Node.js is available and correct version
# ===========================================
echo -e "${BLUE}Test 1: Node.js availability${NC}"
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    if [[ "$NODE_VERSION" =~ ^v20\. ]]; then
        test_pass "Node.js $NODE_VERSION is available"
    else
        test_fail "Node.js version mismatch" "Expected v20.x, got $NODE_VERSION"
    fi
else
    test_fail "Node.js not found" "node command not available"
fi

# ===========================================
# Test 2: Claude Code is installed
# ===========================================
echo -e "${BLUE}Test 2: Claude Code installation${NC}"
if command -v claude &>/dev/null; then
    test_pass "Claude Code is installed and in PATH"
elif [[ -f "$HOME/.npm-global/bin/claude" ]]; then
    test_pass "Claude Code is installed in npm-global"
else
    test_fail "Claude Code not found" "Neither 'claude' in PATH nor in ~/.npm-global/bin"
fi

# ===========================================
# Test 3: Memory configuration is valid
# ===========================================
echo -e "${BLUE}Test 3: Memory configuration${NC}"
if [[ -n "$NODE_OPTIONS" ]]; then
    HEAP_SIZE=$(echo "$NODE_OPTIONS" | grep -oE 'max-old-space-size=[0-9]+' | cut -d= -f2)
    if [[ -n "$HEAP_SIZE" ]] && [[ "$HEAP_SIZE" -ge 512 ]]; then
        test_pass "NODE_OPTIONS configured with heap size ${HEAP_SIZE}MB"
    else
        test_fail "Invalid heap size" "Got '$HEAP_SIZE', expected >= 512MB"
    fi
else
    test_fail "NODE_OPTIONS not set" "Memory configuration missing"
fi

# ===========================================
# Test 4: Memory parsing handles decimals
# ===========================================
echo -e "${BLUE}Test 4: Memory parsing (decimal handling)${NC}"
if [[ -f "/scripts/hooks/set-node-memory.sh" ]]; then
    # Source the script in a subshell to test parsing
    export CONTAINER_MEMORY="4.5gb"
    # shellcheck source=/dev/null
    OUTPUT=$(bash -c 'source /scripts/hooks/set-node-memory.sh 2>&1')
    DETECTED=$(echo "$OUTPUT" | grep "Container memory detected" | grep -oE '[0-9]+')
    if [[ "$DETECTED" -ge 4500 ]] && [[ "$DETECTED" -le 4700 ]]; then
        test_pass "Decimal memory parsing works (4.5gb -> ${DETECTED}MB)"
    else
        test_fail "Decimal parsing failed" "Expected ~4608MB, got ${DETECTED}MB"
    fi
    unset CONTAINER_MEMORY
else
    test_skip "Memory parsing test" "set-node-memory.sh not found"
fi

# ===========================================
# Test 5: Security state file exists (for non-development)
# ===========================================
echo -e "${BLUE}Test 5: Security state tracking${NC}"
SECURITY_PRESET="${SECURITY_PRESET:-development}"
if [[ "$SECURITY_PRESET" != "development" ]]; then
    if [[ -f "/var/log/security-state.json" ]]; then
        if jq -e '.' /var/log/security-state.json &>/dev/null; then
            test_pass "Security state file exists and is valid JSON"
        else
            test_fail "Security state file invalid" "Not valid JSON"
        fi
    else
        test_fail "Security state file missing" "/var/log/security-state.json not found"
    fi
else
    test_skip "Security state test" "Development mode doesn't require security state"
fi

# ===========================================
# Test 6: Security blocking works (paranoid mode only)
# ===========================================
echo -e "${BLUE}Test 6: Security blocking (paranoid mode)${NC}"
if [[ "$SECURITY_PRESET" == "paranoid" ]]; then
    # Try to connect to a domain that should be blocked
    if curl -s --connect-timeout 5 https://example.com &>/dev/null; then
        test_fail "Security blocking failed" "example.com should have been blocked"
    else
        test_pass "Blocked domain (example.com) is inaccessible"
    fi
else
    test_skip "Security blocking test" "Only runs in paranoid mode (current: $SECURITY_PRESET)"
fi

# ===========================================
# Test 7: Allowed domains work (paranoid/enterprise)
# ===========================================
echo -e "${BLUE}Test 7: Allowed domains accessible${NC}"
if [[ "$SECURITY_PRESET" == "paranoid" ]] || [[ "$SECURITY_PRESET" == "enterprise" ]]; then
    # Test that api.anthropic.com is reachable (should be allowed)
    if curl -s --connect-timeout 10 -o /dev/null -w "%{http_code}" https://api.anthropic.com 2>/dev/null | grep -qE "^[245]"; then
        test_pass "Allowed domain (api.anthropic.com) is accessible"
    else
        test_fail "Allowed domain blocked" "api.anthropic.com should be accessible"
    fi
else
    test_skip "Allowed domains test" "Only runs in paranoid/enterprise mode"
fi

# ===========================================
# Test 8: Required tools are installed
# ===========================================
echo -e "${BLUE}Test 8: Required tools installation${NC}"
REQUIRED_TOOLS=("git" "jq" "curl" "npm")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [[ ${#MISSING_TOOLS[@]} -eq 0 ]]; then
    test_pass "All required tools installed: ${REQUIRED_TOOLS[*]}"
else
    test_fail "Missing required tools" "${MISSING_TOOLS[*]}"
fi

# ===========================================
# Test 9: Workspace is accessible and writable
# ===========================================
echo -e "${BLUE}Test 9: Workspace accessibility${NC}"
if [[ -d "/workspace" ]]; then
    if [[ -w "/workspace" ]]; then
        # Try to create a test file
        TEST_FILE="/workspace/.runtime-test-$$"
        if touch "$TEST_FILE" 2>/dev/null; then
            rm -f "$TEST_FILE"
            test_pass "Workspace is readable and writable"
        else
            test_fail "Workspace not writable" "Could not create test file"
        fi
    else
        test_fail "Workspace not writable" "/workspace exists but is not writable"
    fi
else
    test_fail "Workspace missing" "/workspace directory does not exist"
fi

# ===========================================
# Test 10: Health check script works
# ===========================================
echo -e "${BLUE}Test 10: Health check script${NC}"
if [[ -f "/scripts/health-check.sh" ]]; then
    if /scripts/health-check.sh; then
        test_pass "Health check passes"
    else
        test_fail "Health check failed" "Exit code: $?"
    fi
else
    test_skip "Health check test" "health-check.sh not found"
fi

# ===========================================
# Test Summary
# ===========================================
echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}===========================================${NC}"
echo -e "  ${GREEN}Passed${NC}: $TESTS_PASSED"
echo -e "  ${RED}Failed${NC}: $TESTS_FAILED"
echo -e "  ${YELLOW}Skipped${NC}: $TESTS_SKIPPED"
echo ""

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo -e "${RED}Failed tests:${NC}"
    for failure in "${FAILED_TESTS[@]}"; do
        echo "  - $failure"
    done
    echo ""
fi

# Exit with failure if any tests failed
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}RUNTIME TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}ALL RUNTIME TESTS PASSED${NC}"
    exit 0
fi
