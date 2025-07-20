# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a VS Code development container for running claude-flow swarms in a secure, isolated environment. It's based on Anthropic's Claude Code devcontainer reference implementation, adapted specifically for claude-flow development.

### Recent Updates
- **Organized script structure**: All scripts moved to logical subdirectories under `.devcontainer/scripts/`
- **Clean workspace**: Container starts with empty `/workspace`, source code cloned to `/workspace/deps/`
- **Simplified setup**: Uses npx for claude-flow and ruv-swarm - no installation failures
- **Comprehensive testing**: Full test suite validates container configuration and functionality
- **MCP optimization**: MCP servers configured to use npx for always-latest versions

## Key Components

### Dev Container Configuration
- `.devcontainer/devcontainer.json` - VS Code container settings with dynamic security
- `.devcontainer/Dockerfile` - Node.js 20 base with security tools  
- `.devcontainer/scripts/` - Organized scripts directory:
  - `security/init-security.sh` - Dynamic firewall based on security preset
  - `security/security-config.json` - Security preset definitions
  - `security/security-monitor.sh` - Runtime security monitoring
  - `hooks/docker-entrypoint.sh` - Container entrypoint with security initialization
  - `hooks/postCreate.sh` - Post-creation setup (claude-flow, MCP servers, etc.)
  - `tests/` - Comprehensive test suite for container validation

### Claude Flow Setup
- Source code cloned to `/workspace/deps/claude-flow` for reference and development
- Execution via npx ensures you always use the latest version
- No installation required - just works out of the box
- Source available for exploration and contributions

### ruv-FANN Setup
- Cloned to `/workspace/deps/ruv-FANN` for reference and development
- ruv-swarm accessed via npx - no installation needed
- MCP server automatically configured to use npx

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
- `.env.development` - Relaxed local development settings (default)

### Key Features
- **Clean workspace**: Container starts with empty `/workspace` directory
- **Organized scripts**: All scripts in logical subdirectories
- **Robust installation**: Multiple fallback strategies for dependencies
- **Comprehensive testing**: Full test suite for validation
- **Docker entrypoint**: Proper security initialization and user switching

## Common Commands

### Security Configuration
```bash
# Switch security preset
cp .env.paranoid .env  # or .env.enterprise, .env.development

# Check current security level
echo $SECURITY_PRESET

# Run security monitor
bash .devcontainer/scripts/security/security-monitor.sh

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
npx claude-flow@alpha --help
npx claude-flow@alpha hive-mind wizard
npx claude-flow@alpha hive-mind spawn "task description" --claude
```

### Using Claude Flow
```bash
# Claude Flow is always up-to-date when using npx
npx claude-flow@alpha --version

# Pull latest source for development
cd /workspace/deps/claude-flow
git pull origin main
```

### MCP Servers
The container automatically configures two MCP servers:
- **claude-flow**: Uses npx to always run the latest version
- **ruv-swarm**: Uses npx to always run the latest version

To manually reconfigure:
```bash
# Remove and re-add claude-flow
claude mcp remove claude-flow
claude mcp add claude-flow npx claude-flow@alpha mcp start

# Remove and re-add ruv-swarm
claude mcp remove ruv-swarm
claude mcp add ruv-swarm npx ruv-swarm@latest mcp start
```


### Development
```bash
# Check logs
docker logs <container-name>
```

## Installing from Source (Advanced)

If you prefer to install claude-flow and ruv-swarm locally instead of using npx:

### Claude Flow Local Installation
```bash
# Navigate to source directory
cd /workspace/deps/claude-flow

# Install dependencies
npm install

# Install globally
npm install -g . --force

# Configure MCP to use local installation
claude mcp remove claude-flow
claude mcp add claude-flow claude-flow mcp start
```

### ruv-swarm Local Installation
```bash
# Navigate to source directory
cd /workspace/deps/ruv-FANN/ruv-swarm/npm

# Install dependencies (skip devDependencies to avoid wasm-opt issues)
npm install --omit=dev

# Install globally
npm install -g . --force

# Configure MCP to use local installation
claude mcp remove ruv-swarm
claude mcp add ruv-swarm ruv-swarm mcp start
```

### Benefits of Local Installation
- Faster startup times (no network requests)
- Ability to modify and test local changes
- Work offline without internet connection
- Pin to specific versions

### Benefits of npx (Default)
- Always use the latest version
- No installation failures
- Simpler setup and maintenance
- Smaller container size

## Architecture Notes

- Container based on official Node.js devcontainer image
- Persistent command history via volume mount
- Node modules cached in named volume for performance
- Workspace mounted at `/workspace` with proper permissions
- Zsh as default shell with autosuggestions and syntax highlighting

## Adding New Dependencies

When adding new npm packages that require network access:
1. Identify the package registry domain
2. Add IP ranges to `.devcontainer/scripts/security/init-security.sh`
3. Rebuild the container

## Troubleshooting

### npx Command Not Working
If npx commands fail to run:

1. **Check network connectivity**: npx requires internet access
   ```bash
   curl -I https://registry.npmjs.org
   ```

2. **Clear npm cache**:
   ```bash
   npm cache clean --force
   ```

3. **Use local installation** (see "Installing from Source" section above)

### MCP Server Connection Issues
If MCP servers fail to connect:

1. **Check MCP configuration**:
   ```bash
   claude mcp list
   ```

2. **Reinstall MCP servers**:
   ```bash
   claude mcp remove claude-flow
   claude mcp add claude-flow npx claude-flow@alpha mcp start
   ```

### Source Code Not Cloned
If the source code wasn't cloned during setup:

```bash
cd /workspace/deps
git clone https://github.com/ruvnet/claude-flow.git
git clone https://github.com/ruvnet/ruv-FANN.git
```

### Known Working Versions
- Claude Code: v1.0.51
- Claude Flow: v2.0.0-alpha.53
- ruv-FANN/ruv-swarm: v1.0.18
- Node.js: 20.x
- VS Code Dev Containers: Latest

For detailed version information, see [VERSIONS.md](VERSIONS.md).

## Container Structure

### Workspace Organization
```
/workspace/                 # Clean workspace directory
├── deps/                   # Dependencies (in .gitignore)
│   ├── claude-flow/       # Claude Flow source code
│   └── ruv-FANN/         # ruv-FANN with ruv-swarm
└── [your project files]   # Your development work
```

### Scripts Organization
```
.devcontainer/scripts/
├── security/              # Security-related scripts
├── hooks/                # Container lifecycle hooks
└── tests/               # Test suite
```

## Testing

Run the comprehensive test suite before using:
```bash
# From repository root
./.devcontainer/scripts/tests/test-devcontainer.sh
```

Tests verify:
1. JSON configuration validity
2. Container build success
3. Tool installations
4. Security script syntax
5. VS Code integration
6. Container persistence
7. Mount configurations

Manual verification:
1. Container builds successfully
2. Claude Code activates (with API key or /login command)
3. Claude Flow wizard launches
4. Network restrictions work (try `curl google.com` - should fail in paranoid/enterprise)
5. Allowed services work (npm install, git operations)