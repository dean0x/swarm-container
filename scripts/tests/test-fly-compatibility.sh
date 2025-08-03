#!/bin/bash
set -euo pipefail

echo "🧪 SwarmContainer Fly.io Compatibility Test Suite"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Dockerfile syntax
echo "📋 Running Dockerfile tests..."
run_test "Dockerfile syntax" "docker run --rm -i hadolint/hadolint < Dockerfile"
run_test "Base stage builds" "docker build --target base -t test:base ."
run_test "Local stage builds" "docker build --target local -t test:local ."
run_test "Remote stage builds" "docker build --target remote -t test:remote ."

# Test 2: Local stage isolation
echo ""
echo "📋 Testing local stage isolation..."
run_test "No SSH in local stage" "! docker run --rm test:local which sshd"
run_test "PostCreate exists in local" "docker run --rm test:local test -f /workspace/scripts/hooks/postCreate.sh"

# Test 3: File structure
echo ""
echo "📋 Testing file structure..."
run_test "fly.toml exists" "test -f fly.toml"
run_test "fly-entrypoint.sh exists" "test -f fly-entrypoint.sh"
run_test "devcontainer.json unchanged" "grep -q 'SwarmContainer' devcontainer.json"

# Test 4: Build target compatibility
echo ""
echo "📋 Testing build targets..."
run_test "Default build uses last stage" "docker build -t test:default . && docker run --rm test:default which sshd"
run_test "Explicit local target" "docker build --target local -t test:explicit-local . && ! docker run --rm test:explicit-local which sshd"

# Test 5: Scripts executable
echo ""
echo "📋 Testing script permissions..."
for script in scripts/fly-*.sh; do
    if [ -f "$script" ]; then
        run_test "$(basename $script) is executable" "test -x $script"
    fi
done

# Summary
echo ""
echo "========================================"
echo "Test Summary:"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All compatibility tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix issues before proceeding.${NC}"
    exit 1
fi