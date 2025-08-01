#!/bin/bash
set -euo pipefail

echo "🔌 SwarmContainer SSH Connectivity Test"
echo "======================================"
echo ""

# Configuration
APP_NAME="${1:-}"
SSH_PORT="10022"
SSH_USER="node"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Get app name from fly.toml if not provided
if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

SSH_HOST="${APP_NAME}.fly.dev"

echo "🎯 Testing SSH to: $SSH_USER@$SSH_HOST:$SSH_PORT"
echo ""

# Test 1: Basic connectivity
echo "Test 1: Basic SSH connectivity..."
if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
    -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${GREEN}✅ Basic connectivity: PASSED${NC}"
else
    echo -e "${RED}❌ Basic connectivity: FAILED${NC}"
    echo "   Check: Is the app running? Try: fly status -a $APP_NAME"
    exit 1
fi

# Test 2: Environment verification
echo ""
echo "Test 2: Environment verification..."
ENV_CHECK=$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "env | grep -E 'FLY_APP_NAME|NODE_ENV' | sort")
echo "$ENV_CHECK"
if echo "$ENV_CHECK" | grep -q "FLY_APP_NAME=$APP_NAME"; then
    echo -e "${GREEN}✅ Environment: CORRECT${NC}"
else
    echo -e "${RED}❌ Environment: INCORRECT${NC}"
fi

# Test 3: File system access
echo ""
echo "Test 3: File system access..."
FS_TEST=$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "ls -la / | grep -E 'workspace|home' | wc -l")
if [ "$FS_TEST" -ge 2 ]; then
    echo -e "${GREEN}✅ File system: ACCESSIBLE${NC}"
else
    echo -e "${RED}❌ File system: PROBLEM${NC}"
fi

# Test 4: User permissions
echo ""
echo "Test 4: User permissions..."
USER_TEST=$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "whoami; id")
echo "$USER_TEST"
if echo "$USER_TEST" | grep -q "uid=1000(node)"; then
    echo -e "${GREEN}✅ User permissions: CORRECT${NC}"
else
    echo -e "${RED}❌ User permissions: INCORRECT${NC}"
fi

# Test 5: Workspace persistence
echo ""
echo "Test 5: Workspace persistence..."
TEST_FILE="workspace-test-$(date +%s).txt"
ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'Persistence test' > /workspace/$TEST_FILE"
if ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "cat /workspace/$TEST_FILE" | grep -q "Persistence test"; then
    echo -e "${GREEN}✅ Workspace write: SUCCESS${NC}"
    ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "rm /workspace/$TEST_FILE"
else
    echo -e "${RED}❌ Workspace write: FAILED${NC}"
fi

# Test 6: SSH stability
echo ""
echo "Test 6: SSH connection stability..."
if ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "sleep 5 && echo 'Stable connection'"; then
    echo -e "${GREEN}✅ Connection stability: GOOD${NC}"
else
    echo -e "${RED}❌ Connection stability: POOR${NC}"
fi

# Test 7: Command execution
echo ""
echo "Test 7: Remote command execution..."
NODE_VERSION=$(ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "node --version")
echo "Node version: $NODE_VERSION"
if [[ "$NODE_VERSION" == v* ]]; then
    echo -e "${GREEN}✅ Command execution: WORKING${NC}"
else
    echo -e "${RED}❌ Command execution: FAILED${NC}"
fi

echo ""
echo "======================================"
echo -e "${GREEN}✅ All SSH tests completed!${NC}"