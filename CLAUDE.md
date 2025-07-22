# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a VS Code development container for running claude-flow swarms in a secure, isolated environment. It's based on Anthropic's Claude Code devcontainer reference implementation, adapted specifically for claude-flow development.

### Recent Updates
- **Dynamic Memory Allocation**: Auto-detects container memory and sets Node.js heap to 75% (supports cgroup v1/v2)
- **Organized script structure**: All scripts moved to logical subdirectories under `scripts/`
- **Clean workspace**: Container starts with empty `/workspace`, source code cloned to `/workspace/deps/`
- **NPX-based setup**: Uses npx for claude-flow and ruv-swarm - always latest, no installation failures
- **MCP timeout protection**: 10-second timeout prevents MCP server startup from blocking container setup
- **Versioned command history**: Guard file system allows command updates without conflicts
- **Comprehensive testing**: Full test suite validates container configuration and functionality

## Key Components

### Dev Container Configuration
- `devcontainer.json` - VS Code container settings with dynamic resource allocation
- `Dockerfile` - Node.js 20 base with security tools and dynamic NODE_OPTIONS
- `scripts/` - Organized scripts directory:
  - `security/init-security.sh` - Dynamic firewall based on security preset
  - `security/security-config.json` - Security preset definitions
  - `security/security-monitor.sh` - Runtime security monitoring
  - `hooks/docker-entrypoint.sh` - Container entrypoint with security and memory initialization
  - `hooks/postCreate.sh` - Post-creation setup (claude-flow, MCP servers, versioned history)
  - `hooks/set-node-memory.sh` - Dynamic Node.js memory allocation based on container limits
  - `tests/` - Comprehensive test suite for container validation including NODE_OPTIONS verification

### Claude Flow Setup
- **NPX-based access** - Always uses latest version, no global installation needed
- **Source code cloned** to `/workspace/deps/claude-flow` for reference and development
- **Automatic initialization** with `npx claude-flow@alpha init` during container setup
- **MCP server with timeout** - Verified and started with 10-second timeout to prevent blocking
- **Versioned command history** - Updates commands when container setup changes
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
- **Presets**: Paranoid (6GB/2CPU), Enterprise (12GB/6CPU), Development (8GB/4CPU) modes
- **Network**: Dynamic firewall with domain allowlisting/blocklisting
- **Memory**: Dynamic Node.js heap allocation (75% of container memory)
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

# Claude Flow commands (via npx)
npx claude-flow@alpha --help
npx claude-flow@alpha hive-mind wizard
npx claude-flow@alpha hive-mind spawn "task description" --claude

# Check MCP status
npx claude-flow@alpha mcp status
```

### Updating Claude Flow
```bash
# Always uses latest version via npx - no update needed!
# Just run your commands and npx will fetch the latest

# Or pull latest source for development
cd /workspace/deps/claude-flow
git pull origin main

# Verify version
npx claude-flow@alpha --version
```

### MCP Servers
MCP servers are automatically configured when you run `npx claude-flow@alpha init`:
- **claude-flow**: Automatically configured and verified during initialization
- **ruv-swarm**: Available for manual configuration if needed

The initialization process now includes MCP server startup verification to ensure reliable connections.

MCP servers provide enhanced functionality for agent coordination and tool access.


### Development
```bash
# Update packages
npm update -g @anthropic-ai/claude-code
# claude-flow always uses latest via npx

# Check logs
docker logs <container-name>
```

### Tmux Usage

The container includes a fully configured tmux setup with useful plugins for managing multiple terminal sessions.

#### Quick Start
```bash
# Start a new tmux session
tmux new-session -s dev

# Create a 6-pane layout (default 2x3)
tmux-6pane

# Create different layouts
tmux-6pane 3x2      # 3 columns, 2 rows
tmux-6pane main     # Main pane + 5 smaller panes  
tmux-6pane dev      # Development workflow layout

# Attach to existing session
tmux attach-session -t dev
```

#### Key Bindings
- **Prefix key**: `Ctrl-a` (instead of default Ctrl-b)
- **Split panes**: 
  - `Ctrl-a |` - Split vertically
  - `Ctrl-a -` - Split horizontally
- **Navigate panes**: 
  - `Ctrl-a h/j/k/l` - Vim-style navigation
  - `Alt-Arrow` - Arrow key navigation (no prefix)
- **Resize panes**: `Ctrl-a H/J/K/L` (repeatable)
- **Popup menu**: `Ctrl-a \` - Access all tmux commands
- **Copy mode**: `Ctrl-a [` then `v` to select, `y` to copy
- **Quick layouts**: `Ctrl-a 6` - Recreate 6-pane layout
- **Reload config**: `Ctrl-a r`

#### Installed Plugins
- **tmux-sensible**: Better defaults
- **tmux-pain-control**: Improved pane management 
- **tmux-yank**: System clipboard integration
- **tmux-resurrect**: Save/restore sessions (`Ctrl-a Ctrl-s` / `Ctrl-a Ctrl-r`)
- **tmux-continuum**: Automatic session saving (every 15 minutes)
- **tmux-menus**: Context menus for easy command access
- **tmux-open**: Open files/URLs from terminal
- **extrakto**: Fuzzy search text in terminal (`Ctrl-a Tab`)

## Installing from Source (Advanced)

If you want to use your local source code modifications or install ruv-swarm locally:

### Claude Flow Local Installation
```bash
# Navigate to source directory
cd /workspace/deps/claude-flow

# Install dependencies
npm install

# Install globally from your local changes
npm install -g . --force

# Reconfigure MCP to use your local installation
claude mcp remove claude-flow
claude mcp add claude-flow claude-flow mcp start
```

### ruv-swarm Local Installation
```bash
# Navigate to source directory
cd /workspace/deps/ruv-FANN/ruv-swarm/npm

# Install dependencies (skip devDependencies to avoid wasm-opt issues)
npm install --omit=dev

# Install globally from your local changes
npm install -g . --force

# Configure MCP to use your local installation
claude mcp remove ruv-swarm
claude mcp add ruv-swarm ruv-swarm mcp start
```

### Benefits of Local Installation
- Faster startup times (no network requests)
- Ability to modify and test local changes
- Work offline without internet connection
- Pin to specific versions

### Benefits of Current Approach
- Both claude-flow and ruv-swarm via npx - always latest version
- No global installation conflicts
- Aligns with official claude-flow documentation
- Source code available for development
- MCP server properly initialized and verified

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

### Claude Flow Not Working
Since we use npx, claude-flow should always work. If it doesn't:

1. **Check network connectivity**:
   ```bash
   ping registry.npmjs.org
   ```

2. **Try with explicit version**:
   ```bash
   npx claude-flow@2.0.0-alpha.53 --version
   ```

3. **Clear npx cache if needed**:
   ```bash
   rm -rf ~/.npm/_npx
   npx claude-flow@alpha --version
   ```

### MCP Server Connection Issues
If MCP servers fail to connect:

1. **Check MCP configuration**:
   ```bash
   claude mcp list
   ```

2. **Check MCP server status**:
   ```bash
   npx claude-flow@alpha mcp status --detailed
   npx claude-flow@alpha mcp logs --tail 100
   ```

3. **Restart MCP server**:
   ```bash
   npx claude-flow@alpha mcp restart
   ```

4. **Reinstall MCP servers if needed**:
   ```bash
   claude mcp remove claude-flow
   claude mcp add claude-flow npx claude-flow@alpha mcp start
   
   claude mcp remove ruv-swarm
   claude mcp add ruv-swarm npx ruv-swarm@latest mcp start
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