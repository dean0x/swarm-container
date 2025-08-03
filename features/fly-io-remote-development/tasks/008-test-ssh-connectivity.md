# Task 008: Test SSH Connectivity

## Objective
Validate SSH connectivity to Fly.io deployed containers, including key authentication, connection stability, and VS Code Remote-SSH integration.

## Prerequisites
- [ ] Task 005 completed: SSH key handling implemented
- [ ] Task 006 completed: Volumes configured
- [ ] Fly.io account created and CLI installed

## Workflow

### 1. Prerequisites Check
- Verify `flyctl` is installed: `flyctl version`
- Ensure SSH key exists: `ls ~/.ssh/id_*.pub`
- Confirm previous tasks completed

### 2. Implementation

#### Step 2.1: Create SSH Test Script
Create `scripts/tests/test-fly-ssh.sh`:

```bash
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
```

#### Step 2.2: Create VS Code SSH Config Generator
Create `scripts/fly-vscode-ssh-config.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🔧 VS Code SSH Configuration Generator"
echo "====================================="
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

SSH_CONFIG_FILE="$HOME/.ssh/config"
HOST_ALIAS="fly-$APP_NAME"

echo "📝 Generating SSH config for: $APP_NAME"
echo ""

# Create SSH config entry
CONFIG_ENTRY="
# SwarmContainer on Fly.io - $APP_NAME
Host $HOST_ALIAS
    HostName ${APP_NAME}.fly.dev
    Port 10022
    User node
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
"

# Check if entry already exists
if grep -q "Host $HOST_ALIAS" "$SSH_CONFIG_FILE" 2>/dev/null; then
    echo "⚠️  Configuration already exists for: $HOST_ALIAS"
    echo "   Remove existing entry first if you want to regenerate"
else
    # Backup existing config
    if [ -f "$SSH_CONFIG_FILE" ]; then
        cp "$SSH_CONFIG_FILE" "${SSH_CONFIG_FILE}.backup"
        echo "📋 Backed up existing config to: ${SSH_CONFIG_FILE}.backup"
    fi
    
    # Add new entry
    echo "$CONFIG_ENTRY" >> "$SSH_CONFIG_FILE"
    echo "✅ Configuration added to: $SSH_CONFIG_FILE"
fi

echo ""
echo "📡 VS Code Remote-SSH Instructions:"
echo "1. Open VS Code"
echo "2. Press Cmd/Ctrl + Shift + P"
echo "3. Type: 'Remote-SSH: Connect to Host'"
echo "4. Select: '$HOST_ALIAS'"
echo ""
echo "🚀 Direct SSH command:"
echo "   ssh $HOST_ALIAS"
```

#### Step 2.3: Create Connection Monitor
Create `scripts/fly-ssh-monitor.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "📊 SSH Connection Monitor"
echo "======================="

APP_NAME="${1:-}"
INTERVAL="${2:-5}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [interval-seconds]"
    exit 1
fi

echo "Monitoring: $APP_NAME (every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Test connection and measure latency
    if LATENCY=$(ssh -o ConnectTimeout=5 -p 10022 node@${APP_NAME}.fly.dev \
        "echo 'pong'" 2>&1 | grep -oE '[0-9]+ms' || echo "timeout"); then
        echo "[$TIMESTAMP] ✅ Connected - Latency: $LATENCY"
    else
        echo "[$TIMESTAMP] ❌ Connection failed"
    fi
    
    sleep $INTERVAL
done
```

### 3. Testing

#### Test 3.1: Run SSH Tests
```bash
chmod +x scripts/tests/test-fly-ssh.sh
chmod +x scripts/fly-vscode-ssh-config.sh
chmod +x scripts/fly-ssh-monitor.sh

# Deploy first
fly deploy

# Set SSH keys
./scripts/fly-ssh-setup.sh

# Run tests
./scripts/tests/test-fly-ssh.sh
```

#### Test 3.2: VS Code Remote-SSH Test
1. Generate config: `./scripts/fly-vscode-ssh-config.sh`
2. Open VS Code
3. Connect to remote host
4. Open folder: `/workspace`
5. Verify features work

#### Test 3.3: Connection Stability
```bash
# Monitor connection for 1 minute
timeout 60 ./scripts/fly-ssh-monitor.sh your-app-name 5
```

### 4. Documentation

Add SSH testing guide:

```markdown
## Testing SSH Connectivity

### Automated Tests
Run the comprehensive SSH test suite:
```bash
./scripts/tests/test-fly-ssh.sh
```

### Manual Testing
1. Basic connection: `ssh node@your-app.fly.dev -p 10022`
2. File transfer: `scp -P 10022 file.txt node@your-app.fly.dev:/workspace/`
3. Port forwarding: `ssh -L 8080:localhost:8080 node@your-app.fly.dev -p 10022`

### VS Code Setup
Generate SSH config:
```bash
./scripts/fly-vscode-ssh-config.sh
```

Then connect via VS Code Remote-SSH extension.
```

### 5. Completion Criteria
- [ ] SSH test script validates all aspects
- [ ] VS Code config generator works
- [ ] Connection monitoring available
- [ ] All tests pass reliably
- [ ] Documentation complete
- [ ] Latency is acceptable

## Expected Results

### Good Connection
- Latency: < 100ms (same region)
- Stability: No drops over 5 minutes
- Throughout: Can transfer large files

### Acceptable Issues
- First connection: May take 5-10s (container wake)
- After idle: Brief delay (auto-stop feature)

## Troubleshooting

### Connection Refused
1. Check app status: `fly status`
2. Check logs: `fly logs`
3. Verify SSH keys: `fly secrets list`

### Permission Denied
1. Re-run SSH setup: `./scripts/fly-ssh-setup.sh`
2. Check key format: Must be single line in secret
3. Verify user: Must be 'node', not 'root'

### Slow Connection
1. Check region: `fly regions list`
2. Consider closer region
3. Check machine size: May need more resources

## Security Notes
- SSH on non-standard port (10022)
- Key-only authentication
- No root access
- Fail2ban can be added for production