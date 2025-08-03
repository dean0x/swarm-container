# Task 012: Create Troubleshooting Guide

## Objective
Create a comprehensive troubleshooting guide for common issues users might encounter with Fly.io remote development.

## Prerequisites
- [ ] Tasks 001-011 completed: Full implementation and documentation done
- [ ] Real-world testing performed to identify common issues

## Workflow

### 1. Prerequisites Check
- Compile list of potential issues from testing
- Review Fly.io documentation for known issues
- Consider user feedback patterns

### 2. Implementation

#### Step 2.1: Create Troubleshooting Guide
Create `docs/fly-io-troubleshooting.md`:

```markdown
# Fly.io Remote Development Troubleshooting

This guide helps resolve common issues with SwarmContainer on Fly.io.

## Quick Diagnostics

Run this command to check your setup:
```bash
./scripts/tests/test-fly-ssh.sh
```

## Common Issues

### 🔌 Connection Problems

#### "Connection refused" when SSHing

**Symptoms:**
```
ssh: connect to host app.fly.dev port 10022: Connection refused
```

**Solutions:**
1. Check if app is running:
   ```bash
   flyctl status -a your-app-name
   ```

2. If stopped, start it:
   ```bash
   flyctl machine start -a your-app-name
   ```

3. If no machines exist, redeploy:
   ```bash
   flyctl deploy
   ```

#### "Connection timeout"

**Symptoms:**
- SSH hangs without error
- Takes forever to connect

**Solutions:**
1. Check your internet connection
2. Verify firewall not blocking port 10022
3. Try different region:
   ```bash
   flyctl regions list
   flyctl regions set lax  # or closer region
   ```

### 🔑 SSH Key Issues

#### "Permission denied (publickey)"

**Symptoms:**
```
Permission denied (publickey).
```

**Solutions:**
1. Re-run SSH setup:
   ```bash
   ./scripts/fly-ssh-setup.sh
   ```

2. Verify key in Fly secrets:
   ```bash
   flyctl secrets list -a your-app-name
   # Should show SSH_AUTHORIZED_KEYS
   ```

3. Check local SSH key:
   ```bash
   ssh-add -l  # List loaded keys
   ssh-add ~/.ssh/id_ed25519  # Add if missing
   ```

#### Multiple SSH keys

**Problem:** Wrong key being used

**Solution:**
Force specific key:
```bash
ssh -i ~/.ssh/specific_key -p 10022 node@app.fly.dev
```

### 💾 Volume Issues

#### "No space left on device"

**Symptoms:**
```
Error: ENOSPC: no space left on device
```

**Solutions:**
1. Check disk usage:
   ```bash
   ssh -p 10022 node@app.fly.dev "df -h"
   ```

2. Clean up:
   ```bash
   # Remove node_modules
   ssh -p 10022 node@app.fly.dev "rm -rf /workspace/*/node_modules"
   
   # Clear npm cache
   ssh -p 10022 node@app.fly.dev "npm cache clean --force"
   ```

3. Extend volume:
   ```bash
   flyctl volumes list -a your-app-name
   flyctl volumes extend <volume-id> --size 40
   ```

#### Volumes not mounting

**Symptoms:**
- `/workspace` is empty
- Files don't persist

**Solutions:**
1. Check volume attachment:
   ```bash
   flyctl volumes list -a your-app-name
   ```

2. Recreate if needed:
   ```bash
   ./scripts/fly-volume-setup.sh
   flyctl deploy
   ```

### 🚀 Deployment Issues

#### "Build failed"

**Common causes:**
1. **Dockerfile syntax error**
   ```bash
   docker build --target remote -t test .
   ```

2. **fly.toml misconfiguration**
   ```bash
   flyctl config validate
   ```

3. **Resource limits**
   - Increase builder resources in fly.toml

#### "Unhealthy allocation"

**Symptoms:**
- Deploy succeeds but app marked unhealthy

**Solutions:**
1. Check logs:
   ```bash
   flyctl logs -a your-app-name
   ```

2. Common fixes:
   - Ensure SSH daemon starts
   - Check entrypoint script
   - Verify health checks

### 🐌 Performance Issues

#### Slow SSH connection

**Solutions:**
1. **Choose closer region:**
   ```bash
   # Find your location
   curl -s https://ipinfo.io/city
   
   # List regions
   flyctl regions list
   
   # Set closer region
   flyctl regions set <region-code>
   ```

2. **Upgrade machine:**
   ```bash
   flyctl scale vm shared-cpu-4x -a your-app-name
   ```

3. **Enable SSH compression:**
   ```bash
   ssh -C -p 10022 node@app.fly.dev
   ```

#### Container feels sluggish

**Solutions:**
1. Check resource usage:
   ```bash
   flyctl scale show -a your-app-name
   ```

2. Monitor during use:
   ```bash
   ssh -p 10022 node@app.fly.dev "htop"
   ```

3. Scale up if needed:
   ```bash
   # More CPU
   flyctl scale vm performance-2x
   
   # More memory
   flyctl scale memory 4096
   ```

### 🔧 MCP Server Issues

#### "MCP servers not found"

**Solutions:**
1. Run MCP setup:
   ```bash
   ./scripts/fly-mcp-setup.sh
   ```

2. Check configuration:
   ```bash
   ssh -p 10022 node@app.fly.dev "cat ~/.claude.json"
   ```

#### Claude Code not working

**Solutions:**
1. Check API key:
   ```bash
   flyctl secrets list -a your-app-name
   ```

2. Set if missing:
   ```bash
   flyctl secrets set ANTHROPIC_API_KEY=sk-ant-... -a your-app-name
   ```

### 💰 Billing Issues

#### Unexpected charges

**Common causes:**
1. **Machine didn't auto-stop**
   - Check fly.toml has `auto_stop_machines = true`
   
2. **Large volumes**
   - Review volume sizes: `flyctl volumes list`
   
3. **Multiple machines**
   - Check: `flyctl machine list`
   - Remove extras: `flyctl machine destroy <id>`

#### How to minimize costs

```toml
# In fly.toml
[[services]]
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0
```

## Advanced Debugging

### Enable Debug Logging

1. **SSH debug mode:**
   ```bash
   ssh -vvv -p 10022 node@app.fly.dev
   ```

2. **Fly.io debug mode:**
   ```bash
   LOG_LEVEL=debug flyctl deploy
   ```

### Direct Machine Access

```bash
# List machines
flyctl machine list -a your-app-name

# SSH directly to machine
flyctl ssh console -a your-app-name
```

### Container Logs

```bash
# Live logs
flyctl logs -a your-app-name

# Last 100 lines
flyctl logs -n 100 -a your-app-name
```

## Recovery Procedures

### Complete Reset

If nothing else works:

```bash
# 1. Backup data
./scripts/fly-volume-backup.sh your-app-name

# 2. Destroy app (careful!)
flyctl apps destroy your-app-name

# 3. Recreate
flyctl launch --name your-app-name --copy-config
./scripts/fly-volume-setup.sh
./scripts/fly-ssh-setup.sh
flyctl deploy

# 4. Restore data if needed
```

### Emergency SSH Access

If normal SSH fails:

```bash
# Use Fly SSH (root access)
flyctl ssh console -a your-app-name

# Fix permissions/issues
chown -R node:node /workspace
chmod 700 /home/node/.ssh
```

## Getting Help

### Before Asking for Help

1. Run diagnostics: `./scripts/tests/test-fly-ssh.sh`
2. Check logs: `flyctl logs -a your-app-name`
3. Review this guide

### Where to Get Help

1. **SwarmContainer Issues**: [GitHub Issues](https://github.com/your-repo/issues)
2. **Fly.io Problems**: [community.fly.io](https://community.fly.io)
3. **Emergency**: Fly.io support (paid plans)

### Information to Provide

When reporting issues, include:
- Output of diagnostic script
- Relevant logs
- fly.toml configuration
- Steps to reproduce
```

#### Step 2.2: Create Quick Fix Script
Create `scripts/fly-quick-fix.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🔧 SwarmContainer Quick Fix Tool"
echo "==============================="
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

echo "🎯 Checking: $APP_NAME"
echo ""

# Fix 1: Wake up machine
echo "1. Waking up machine..."
flyctl machine list -a "$APP_NAME" | grep stopped && {
    echo "   Machine is stopped, starting..."
    flyctl machine start -a "$APP_NAME"
    sleep 5
}

# Fix 2: Check SSH keys
echo ""
echo "2. Checking SSH keys..."
if ! flyctl secrets list -a "$APP_NAME" | grep -q SSH_AUTHORIZED_KEYS; then
    echo "   ❌ No SSH keys found!"
    echo "   Run: ./scripts/fly-ssh-setup.sh"
else
    echo "   ✅ SSH keys configured"
fi

# Fix 3: Test connectivity
echo ""
echo "3. Testing connectivity..."
if timeout 5 ssh -o ConnectTimeout=3 -p 10022 node@${APP_NAME}.fly.dev "echo OK" > /dev/null 2>&1; then
    echo "   ✅ SSH connection working"
else
    echo "   ❌ SSH connection failed"
    echo "   Checking app status..."
    flyctl status -a "$APP_NAME"
fi

# Fix 4: Check volumes
echo ""
echo "4. Checking volumes..."
VOLUME_COUNT=$(flyctl volumes list -a "$APP_NAME" | grep -c "created" || echo 0)
if [ "$VOLUME_COUNT" -lt 2 ]; then
    echo "   ⚠️  Missing volumes! Found: $VOLUME_COUNT, expected: 2"
    echo "   Run: ./scripts/fly-volume-setup.sh"
else
    echo "   ✅ Volumes configured"
fi

echo ""
echo "=============================="
echo "Quick fix complete!"
echo ""
echo "Still having issues? See: docs/fly-io-troubleshooting.md"
```

### 3. Testing

#### Test 3.1: Validate Solutions
- Test each troubleshooting step
- Ensure solutions actually work
- Time how long fixes take

#### Test 3.2: Quick Fix Script
```bash
chmod +x scripts/fly-quick-fix.sh
./scripts/fly-quick-fix.sh
```

### 4. Documentation

Link troubleshooting from other docs:

In `fly-io-setup.md`:
```markdown
## Having Issues?

See our comprehensive [Troubleshooting Guide](fly-io-troubleshooting.md) for solutions to common problems.

Quick diagnostics:
```bash
./scripts/fly-quick-fix.sh
```
```

### 5. Completion Criteria
- [ ] Common issues documented
- [ ] Solutions tested and verified
- [ ] Quick fix script created
- [ ] Advanced debugging covered
- [ ] Recovery procedures included
- [ ] Help resources listed

## Troubleshooting Categories

### Must Cover
1. **Connection Issues**: Most common
2. **SSH Key Problems**: Authentication
3. **Volume Issues**: Storage problems
4. **Performance**: Slow response
5. **Deployment**: Build/deploy failures
6. **Costs**: Billing concerns

### Issue Template
For each issue:
1. **Symptoms**: What user sees
2. **Diagnosis**: How to confirm
3. **Solutions**: Step-by-step fixes
4. **Prevention**: How to avoid

## User Experience
- Start with quick fixes
- Progress to advanced solutions
- Provide escape hatches
- Link to human help