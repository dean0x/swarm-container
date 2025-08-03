# Troubleshooting Guide

This guide covers common issues and their solutions when using SwarmContainer.

## Container Issues

### Container Build Fails
```bash
# Clean rebuild without cache
docker system prune -a
# Then reopen in VS Code
```

### VS Code doesn't show "Reopen in Container"
1. Ensure Remote-Containers extension is installed
2. Check Docker is running: `docker ps`
3. Try Command Palette (F1): "Dev Containers: Reopen in Container"

### "No space left on device" during build
1. **Clean up Docker space**:
   ```bash
   # Remove unused containers, images, and volumes
   docker system prune -a --volumes
   
   # Check Docker disk usage
   docker system df
   ```

2. **Clear Docker build cache**:
   ```bash
   docker builder prune
   ```

3. **Check your disk space**:
   ```bash
   df -h  # On macOS/Linux
   ```

4. **If using Docker Desktop**, increase the disk image size:
   - Open Docker Desktop → Settings → Resources
   - Increase "Disk image size" slider
   - Apply & Restart

## Claude Code Issues

### Claude Code Not Working
1. **Check API key** (if using API key auth):
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. **Try browser authentication**:
   ```bash
   claude --dangerously-skip-permissions
   # Then use /login command when prompted
   ```

3. **Verify installation**:
   ```bash
   which claude
   npm list -g @anthropic-ai/claude-code
   ```

4. **Update Claude Code**:
   ```bash
   update-claude  # Uses special wrapper for permissions
   ```

### MCP Server Issues
1. **Check MCP configuration**:
   ```bash
   cat ~/.claude.json
   claude mcp list
   ```

2. **Manually update MCP config**:
   ```bash
   mcp-update
   ```

3. **Check MCP config file**:
   ```bash
   cat /workspace/config/.mcp.config
   ```

## Memory Issues

### Node.js Out of Memory Errors
1. **Increase memory in .env**:
   ```bash
   CONTAINER_MEMORY=12g  # Increase from default
   ```

2. **Check current memory**:
   ```bash
   echo "Container Memory: $(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo 'unlimited')"
   echo "Node.js Heap: $NODE_OPTIONS"
   ```

3. **Temporary fix**:
   ```bash
   export NODE_OPTIONS="--max-old-space-size=8192"  # 8GB
   ```

4. **Rebuild container** after changing memory settings

### Container Disconnection
1. **Check Docker Desktop resources**:
   - Docker Desktop → Settings → Resources
   - Ensure 16GB+ memory allocated
   - Increase CPU limit if needed

2. **Add to .env**:
   ```bash
   CONTAINER_MEMORY=10g
   CONTAINER_CPUS=6
   ```

3. **Monitor container health**:
   ```bash
   # Check logs
   docker logs $(docker ps -q -f name=SwarmContainer)
   
   # Check resource usage
   docker stats
   ```

## Network Issues

### Network Connectivity Problems
Check your security preset:
```bash
echo $SECURITY_PRESET
```

- **Paranoid/Enterprise**: Only allowed domains work. Add to `.env`:
  ```bash
  CUSTOM_ALLOWED_DOMAINS=api.mycompany.com,npm.mycompany.com
  ```
- **Development**: Most connections allowed, only malicious sites blocked

### Check Blocked Connections
```bash
# View firewall logs
dmesg | grep "BLOCKED"

# Check security monitor
bash scripts/security/security-monitor.sh
```

## Common Warnings (Safe to Ignore)

### "iptables: Permission denied"
This is expected - the container applies security rules at startup with proper privileges. Does not affect functionality.

### "chown: Operation not permitted" on node_modules
Normal behavior - node_modules is a Docker volume managed by Docker.

## Still Having Issues?

1. **Check the test suite**:
   ```bash
   ./.devcontainer/scripts/tests/test-devcontainer.sh
   ```

2. **Enable debug logging**:
   ```bash
   export DEBUG=true
   # Rebuild container
   ```

3. **Report issues**:
   - Claude Code issues: https://github.com/anthropics/claude-code/issues
   - Container issues: Create an issue in this repository

## Fly.io Specific Issues

See [Fly.io Troubleshooting Guide](fly-io-troubleshooting.md) for cloud deployment issues.