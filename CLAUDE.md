# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a VS Code development container for running claude-flow swarms in a secure, isolated environment. It's based on Anthropic's Claude Code devcontainer reference implementation, adapted specifically for claude-flow development.

## Key Components

### Dev Container Configuration
- `.devcontainer/devcontainer.json` - VS Code container settings with dynamic security
- `.devcontainer/Dockerfile` - Node.js 20 base with security tools  
- `.devcontainer/init-security.sh` - Dynamic firewall based on security preset
- `.devcontainer/postCreate.sh` - Container initialization
- `.devcontainer/security-config.json` - Security preset definitions
- `.devcontainer/security-monitor.sh` - Runtime security monitoring

### Claude Flow Installation
- Installed globally from npm for reliability
- Source code cloned to `/workspace/deps/claude-flow` for development
- Easy updates with `npm update -g claude-flow@alpha`
- Source available for exploration and contributions

### ruv-FANN Installation
- Cloned to `/workspace/deps/ruv-FANN` for development and updates
- ruv-swarm installed with `--production` flag to skip devDependencies
- Local ruv-swarm MCP server automatically configured

### Development Benefits
- Both repositories available in workspace for contributions
- Easy to pull latest updates with `git pull`
- Modify and test changes locally
- Submit PRs directly from the container

### Security Architecture
- **Presets**: Paranoid, Enterprise, Development modes
- **Network**: Dynamic firewall with domain allowlisting/blocklisting
- **Filesystem**: Configurable read-only paths and workspace isolation
- **Process**: Capability dropping, resource limits, privilege restrictions
- **Monitoring**: Security audit logging and integrity checking

### Environment Files
- `.env.paranoid` - Maximum security configuration
- `.env.enterprise` - Corporate environment settings
- `.env.development` - Relaxed local development settings

## Common Commands

### Security Configuration
```bash
# Switch security preset
cp .env.paranoid .env  # or .env.enterprise, .env.development

# Check current security level
echo $SECURITY_PRESET

# Run security monitor
bash .devcontainer/security-monitor.sh

# View security logs
tail -f .devcontainer/security.log
```

### Container Management
```bash
# Rebuild container (after Dockerfile changes)
code . # Then: F1 > "Remote-Containers: Rebuild Container"

# Check firewall rules
sudo iptables -L -n -v

# Check blocked connection attempts (paranoid mode)
dmesg | grep "BLOCKED-OUT:"
```

### Claude Flow Operations
```bash
# Set API key (optional - can also use /login command)
export ANTHROPIC_API_KEY='sk-ant-...'
# Or leave empty and use /login command after activating Claude Code

# Activate Claude Code
claude --dangerously-skip-permissions

# Claude Flow commands
claude-flow --help
claude-flow hive-mind wizard
claude-flow hive-mind spawn "task description" --claude
```

### Updating Claude Flow
```bash
# Update from npm (recommended)
npm update -g claude-flow@alpha

# Or pull latest source for development
cd /workspace/deps/claude-flow
git pull origin main

# Verify update
claude-flow --version
```

### MCP Servers
The container automatically configures two local MCP servers for faster connections:
- **claude-flow**: Uses the locally installed claude-flow package
- **ruv-swarm**: Uses the locally cloned ruv-FANN installation

To manually reconfigure:
```bash
# Remove and re-add claude-flow
claude mcp remove claude-flow
claude mcp add claude-flow claude-flow

# Remove and re-add ruv-swarm
claude mcp remove ruv-swarm
claude mcp add ruv-swarm /workspace/deps/ruv-FANN/ruv-swarm/npm/bin/ruv-swarm-secure.js

# Start MCP servers
claude mcp start
```

### Development
```bash
# Update packages
npm update -g claude-flow@alpha
npm update -g @anthropic-ai/claude-code

# Check logs
docker logs <container-name>
```

## Architecture Notes

- Container based on official Node.js devcontainer image
- Persistent command history via volume mount
- Node modules cached in named volume for performance
- Workspace mounted at `/workspace` with proper permissions
- Zsh as default shell with autosuggestions and syntax highlighting

## Adding New Dependencies

When adding new npm packages that require network access:
1. Identify the package registry domain
2. Add IP ranges to `.devcontainer/init-firewall.sh`
3. Rebuild the container

## Troubleshooting

### ruv-swarm npm install fails
If the ruv-swarm installation fails during container creation:

**Common issue: wasm-opt platform error**
The wasm-opt npm package doesn't support all platforms (e.g., certain ARM architectures).

**Solution implemented**: Since wasm-opt is only a devDependency in ruv-swarm, we install with `npm install --production` to skip all devDependencies, including the problematic wasm-opt package. This allows ruv-swarm to install successfully without any platform compatibility issues.

If you need to manually reinstall:
```bash
cd /workspace/deps/ruv-FANN/ruv-swarm/npm
npm install --production
# or for newer npm versions:
npm install --omit=dev
```

The MCP configuration will work normally since wasm-opt is not required for runtime operation of ruv-swarm.

## Testing

To verify the setup:
1. Container builds successfully
2. Claude Code activates (with API key or /login command)
3. Claude Flow wizard launches
4. Network restrictions work (try `curl google.com` - should fail)
5. Allowed services work (npm install, git operations)