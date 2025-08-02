# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a VS Code development container for running Claude Code in a secure, isolated environment. It's designed to provide a safe, pre-configured development environment with intelligent resource management and customizable security levels.

### Key Features
- **🧠 Dynamic Memory Allocation**: Auto-scales resources based on number of Claude Code instances
- **🤖 Multi-Instance Support**: Run 1-100+ Claude Code instances with automatic resource calculation
- **🛡️ Three Security Presets**: Paranoid, Enterprise, and Development modes
- **🔧 MCP Server Support**: Pre-configured Model Context Protocol servers
- **📦 Auto-updating MCP Config**: Live configuration updates with file watcher
- **🧪 Comprehensive Testing**: Full test suite validates container configuration

## Key Components

### Dev Container Configuration
- `devcontainer.json` - VS Code container settings with dynamic resource allocation
- `Dockerfile` - Node.js 20 base with security tools and dynamic NODE_OPTIONS
- `scripts/` - Organized scripts directory:
  - `security/init-security.sh` - Dynamic firewall based on security preset
  - `security/security-config.json` - Security preset definitions
  - `security/security-monitor.sh` - Runtime security monitoring
  - `hooks/docker-entrypoint.sh` - Container entrypoint with security and memory initialization
  - `hooks/postCreate.sh` - Post-creation setup (Claude Code, MCP servers)
  - `hooks/set-node-memory.sh` - Dynamic Node.js memory allocation based on container limits
  - `tests/` - Comprehensive test suite for container validation

### MCP Configuration
- Default MCP servers configured in `config/.mcp.config`
- Automatic merging into user's `.claude.json`
- Support for environment variable substitution
- Optional file watcher for live updates

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

## Multi-Instance Configuration

The container automatically scales resources based on how many Claude Code instances you plan to run.

### When to Configure

1. **Before first use**: Run configuration tool before opening in VS Code
2. **Changing instances**: Exit container → Configure → Rebuild
3. **Manual setup**: Edit `.env` file directly

### Configuration Steps

```bash
# Method 1: Interactive tool (recommended)
# Run from project root BEFORE opening in VS Code
./scripts/configure-for-instances.sh

# Method 2: Manual configuration
# Edit .env file:
CLAUDE_CODE_INSTANCES=10

# Method 3: Quick one-liner
echo "CLAUDE_CODE_INSTANCES=10" >> .env
```

### Resource Scaling

The system automatically calculates:
- **Memory**: (instances × 600MB) + 2GB overhead
- **CPUs**: max(2, instances ÷ 3)
- **Heap %**: 80 - instances (bounded 40-75%)

Examples:
- **1 instance**: 3GB RAM, 2 CPUs, 75% heap (single user)
- **6 instances**: 5GB RAM, 2 CPUs, 74% heap (default)
- **10 instances**: 8GB RAM, 4 CPUs, 70% heap (team usage)
- **25 instances**: 17GB RAM, 8 CPUs, 55% heap (power user)
- **50 instances**: 32GB RAM, 16 CPUs, 40% heap (workstation)

### Important Notes

- Configuration must be done **OUTSIDE** the container
- Changes require container rebuild in VS Code
- Default is 6 instances if not specified

## Productivity Tools

The container includes modern CLI tools to supercharge your development workflow:

### Git & Docker Management
- **`lg` (lazygit)** - Visual git interface for commits, branches, and merges
- **`lzd` (lazydocker)** - Monitor and manage Docker containers visually

### Enhanced File Navigation
- **`ls/ll/la`** - Enhanced file listing with icons and Git status (via eza)
- **`tree`** - Visual directory tree with icons
- **`cd`** - Smart directory jumping that learns your habits (via zoxide)
  - Example: After visiting `/workspace/src/components` once, just type `cd components`

### System Monitoring
- **`top/htop`** - Modern system monitor with graphs (via bottom)
- **`du`** - Visual disk usage analyzer (via dust)
- **`ping`** - Ping with real-time graphs (via gping)

### Development Utilities
- **`cat`** - Syntax-highlighted file viewer (via bat)
- **`tokei`** - Fast code statistics by language
- **`jq`** - JSON processing and querying
- **`http`** - User-friendly HTTP client (HTTPie)
- **`help <command>`** - Simplified man pages (via tldr)

### Shell History
- **Ctrl+R** - Neural network powered history search (via mcfly)
- History syncs across sessions and learns from your usage patterns

## Common Commands

### Claude Code Setup
```bash
# Set API key (optional - can also use /login command)
export ANTHROPIC_API_KEY='sk-ant-...'
# Or leave empty and use /login command after activating Claude Code

# Activate Claude Code
claude --dangerously-skip-permissions

# If no API key is set, you'll be prompted to use /login
```

### Security Configuration
```bash
# Switch security preset
cp .env.paranoid .env  # or .env.enterprise, .env.development

# Check current security level
echo $SECURITY_PRESET

# Run security monitor
bash scripts/security/security-monitor.sh

# View security logs
tail -f security.log
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

### MCP Server Management
```bash
# List configured MCP servers
claude mcp list

# Update MCP configuration
mcp-update  # Alias for manual update

# MCP watcher commands (if enabled)
mcp-watcher-status
mcp-watcher-start
mcp-watcher-stop
mcp-watcher-logs
```

### Development
```bash
# Update Claude Code (use special wrapper for permissions)
update-claude
# Or use the full command:
npm-global-update update -g @anthropic-ai/claude-code

# Check container logs
docker logs <container-name>

# Check memory allocation
echo $NODE_OPTIONS
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
2. Add to `CUSTOM_ALLOWED_DOMAINS` in your `.env` file
3. Or add IP ranges to `scripts/security/init-security.sh` for permanent inclusion
4. Rebuild the container

## Troubleshooting

### Claude Code Not Working
1. **Check API key**:
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

4. **Update Claude Code** (if permissions error):
   ```bash
   # Use the special wrapper that handles permissions
   update-claude
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

### Memory Issues
1. **Check current allocation**:
   ```bash
   echo $NODE_OPTIONS
   cat /sys/fs/cgroup/memory.max  # or memory/memory.limit_in_bytes for cgroup v1
   ```

2. **Increase container memory** in `.env`:
   ```bash
   CONTAINER_MEMORY=12g
   ```

3. **Rebuild container** after changes

### Network Connectivity Issues
1. **Check security preset**:
   ```bash
   echo $SECURITY_PRESET
   ```

2. **For paranoid/enterprise modes**, add domains to `.env`:
   ```bash
   CUSTOM_ALLOWED_DOMAINS=api.mycompany.com,npm.mycompany.com
   ```

3. **Check firewall logs**:
   ```bash
   dmesg | grep "BLOCKED"
   ```

## Container Structure

### Workspace Organization
```
/workspace/                 # Your project directory
└── [your project files]   # Your development work
```

### Configuration Files
```
├── config/
│   └── .mcp.config       # Default MCP server configuration
├── scripts/
│   ├── security/         # Security-related scripts
│   ├── hooks/           # Container lifecycle hooks
│   └── tests/          # Test suite
└── devcontainer.json   # VS Code container configuration
```

## Testing

Run the comprehensive test suite before using:
```bash
# From repository root
./scripts/tests/test-devcontainer.sh
```

Tests verify:
1. JSON configuration validity
2. Container build success
3. Tool installations
4. Security script syntax
5. VS Code integration
6. Container persistence
7. Mount configurations
8. Module functionality

## Known Working Versions
- Claude Code: v1.0.56
- Node.js: 20.x
- VS Code Dev Containers: Latest

For detailed version information, see [VERSIONS.md](VERSIONS.md).