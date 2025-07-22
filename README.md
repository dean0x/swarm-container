# Swarm Container

[![CI](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml/badge.svg)](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/dean0x/swarm-container)](https://github.com/dean0x/swarm-container/releases)

A drop-in VS Code development container for running Claude Code and claude-flow swarms in a secure, isolated environment.

🔒 **Features multiple security presets**: Paranoid, Enterprise, and Development modes to match your security requirements.

## ✨ Highlights

- **🛡️ Isolated Security** - Container-level firewall and network isolation keeps your host system safe while experimenting with AI agents
- **🧠 Dynamic Memory Allocation** - Automatically sets Node.js heap to 75% of container memory, prevents OOM errors across all security presets
- **🚀 Claude Flow via npx** - Always latest version with automatic initialization on container start
- **💻 Local Development Ready** - Full source code for both claude-flow and ruv-FANN in your workspace - explore, modify, and contribute back
- **⚡ Zero-Latency MCP** - Local MCP servers with timeout protection eliminate network roundtrips for lightning-fast agent coordination
- **📦 Smart Fallbacks** - Multiple installation strategies ensure everything works on your machine (ARM, x86, Mac, Linux)
- **🧪 Battle-Tested** - Comprehensive test suite validates your setup before you even start coding

## Supported Swarm Orchestrators

| Orchestrator | Description | Status | |
|-------------|-------------|---------|---|
| [claude-flow](https://github.com/ruvnet/claude-flow) | Advanced swarm intelligence with SQLite memory system and GitHub integration | ✅ Available | Auto-initialized |
| [claude-swarm](https://github.com/parruda/claude-swarm) | Multi-agent orchestration with tree hierarchy and MCP communication | 🔜 Coming Soon | |


## Prerequisites

- [VS Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - **Windows**: Requires WSL2 backend
  - **macOS**: Intel or Apple Silicon
  - **Linux**: Native Docker
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code
- Either an [Anthropic API key](https://console.anthropic.com/account/keys) OR a [Claude Pro/Max subscription](https://claude.ai/subscription)

### Tested Versions

This container has been tested with the following versions:

| Component | Version | Last Updated |
|-----------|---------|--------------|
| **Claude Code** | v1.0.51 | July 2025 |
| **Claude Flow** | v2.0.0-alpha.53 | July 2025 |
| **ruv-FANN/ruv-swarm** | v1.0.18 | July 2025 |

For detailed version information and update instructions, see [VERSIONS.md](VERSIONS.md).

## 🚀 Quick Start

### Integration Options

#### Option 1: Git Submodule (Recommended - Easy Updates)
```bash
cd your-project
git submodule add https://github.com/dean0x/swarm-container.git .devcontainer
git commit -m "Add swarm-container devcontainer"

# To update later:
cd .devcontainer && git pull origin main
cd .. && git add .devcontainer && git commit -m "Update devcontainer"
```

#### Option 2: Git Subtree (Cleaner History)
```bash
cd your-project
git subtree add --prefix=.devcontainer https://github.com/dean0x/swarm-container.git main --squash

# To update later:
git subtree pull --prefix=.devcontainer https://github.com/dean0x/swarm-container.git main --squash
```

#### Option 3: Simple Clone (No Update Tracking)
```bash
cd your-project
git clone https://github.com/dean0x/swarm-container.git .devcontainer
rm -rf .devcontainer/.git
git add .devcontainer && git commit -m "Add devcontainer"
```

### Configure Your Environment

```bash
# Copy the appropriate environment file
cp .devcontainer/.env.development .env    # For local development (recommended)
# OR
cp .devcontainer/.env.enterprise .env     # For corporate environments
# OR
cp .devcontainer/.env.paranoid .env       # For maximum security
```

### Set Up Authentication

You have two options for Claude authentication:

#### Option A: Claude Pro/Max Subscription (Recommended)
```bash
# No configuration needed! You'll log in via browser when you start Claude Code
# Just leave the .env file as is (no API key required)
```

#### Option B: Anthropic API Key
```bash
# Edit .env and add your API key
echo "ANTHROPIC_API_KEY=sk-ant-your-key-here" >> .env

# Or manually edit .env and add:
# ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### Open in VS Code

```bash
# Open VS Code in your project directory
code .
```

**Then:**
1. VS Code will detect the `.devcontainer` folder
2. Click **"Reopen in Container"** when prompted
3. Or use Command Palette (F1/Cmd+Shift+P): "Dev Containers: Reopen in Container"

**First-time setup will:**
- Download the base Docker image
- Install all dependencies
- Clone claude-flow and ruv-FANN sources
- Initialize claude-flow with `npx claude-flow@alpha init`
- Verify and start MCP servers
- Set up your development environment

⏱️ **This takes 3-5 minutes on first run**

### 4. Container Setup Prompts

During setup, you'll see:

1. **Deno PATH prompt**: 
   ```
   Edit shell configs to add deno to the PATH? (Y/n)
   ```
   **➜ Type `Y` and press Enter** (required for claude-flow to work properly)

2. **Progress messages** showing:
   - Security level initialization
   - Claude Flow initialization via npx
   - MCP server verification and startup

### 5. Start Using Claude Flow

Once the container is ready:

```bash
# Step 1: Activate Claude Code (required for claude-flow)
claude --dangerously-skip-permissions

# If using Option A (Claude Pro/Max), you'll see:
# "Please visit: https://[...] to authenticate"
# Click the link and log in with your Claude account

# Step 2: Verify installation
npx claude-flow@alpha --version

# Step 3: Start building!
# Quick swarm spawn
npx claude-flow@alpha hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude

# Or use the interactive wizard
npx claude-flow@alpha hive-mind wizard

# Or explore example commands (press ↑ arrow for history)
# We've pre-loaded useful commands in your shell history!
```

### 📋 Configuration Options

#### Security Presets Explained

| Preset | Network Access | Use Case | Firewall Rules | Memory | CPUs |
|--------|---------------|----------|----------------|---------|------|
| **development** | Most permissive | Local development, learning | Blocks only known malicious | 8GB | 4 |
| **enterprise** | Balanced | Corporate environments | Allows dev tools, blocks risky | 12GB | 6 |
| **paranoid** | Highly restricted | Untrusted code, sensitive data | Explicit allowlist only | 6GB | 2 |

📄 **See [security-config.json](.devcontainer/scripts/security/security-config.json) for detailed preset definitions**

#### Resource Requirements

The container now **dynamically allocates Node.js heap memory** based on container memory (75% of total):

| Container Memory | Node.js Heap | Use Case |
|-----------------|--------------|-----------|
| 4GB | 3GB | Basic single agent operations |
| 6GB | 4.5GB | Paranoid mode with limited agents |
| 8GB | 6GB | Standard development (default) |
| 12GB | 9GB | Enterprise multi-agent swarms |
| 16GB+ | 12GB+ | Large-scale swarm operations |

**Minimum Requirements**:
- Single Claude Code instance: 4GB memory, 2 CPUs
- Small swarm (3-5 agents): 8GB memory, 4 CPUs  
- Medium swarm (6-10 agents): 12GB memory, 6 CPUs
- Large swarm (10+ agents): 16GB+ memory, 8+ CPUs

#### Environment Variables

Create or edit `.env` to customize:

```bash
# Authentication (choose one)
ANTHROPIC_API_KEY=sk-ant-...          # For API key auth
# OR leave empty for browser auth

# Security
SECURITY_PRESET=development            # Options: development, enterprise, paranoid
                                      # Default set in: .devcontainer/devcontainer.json
CUSTOM_ALLOWED_DOMAINS=api.myco.com    # Additional allowed domains (comma-separated)

# Resources (optional, defaults shown for development preset)
CONTAINER_MEMORY=8g                    # Container memory limit
CONTAINER_CPUS=4                       # CPU core limit
# Note: Node.js heap is automatically set to 75% of container memory

# Advanced (optional)
NO_NEW_PRIVILEGES=true                 # Security: prevent privilege escalation
```

### 🔧 Advanced Configuration

#### Custom Domain Allowlist
For `enterprise` or `paranoid` modes, add custom domains:

```bash
# In .env
CUSTOM_ALLOWED_DOMAINS=api.company.com,npm.company.com,registry.company.com
```

#### Workspace Persistence
Your project files are mounted at `/workspace` in the container:
- All your project files persist between container restarts
- Dependencies installed in the container are cached in Docker volumes
- Command history is preserved

#### Shell Customization
The container includes:
- Zsh with Oh My Zsh
- Auto-suggestions and syntax highlighting
- Pre-loaded command history
- Versioned command history system

📚 **For detailed security configuration, see [SECURITY.md](SECURITY.md)**

## What's Included

### 🧰 Development Environment
- **Node.js 20** with npm for modern JavaScript development
- **Zsh with Oh My Zsh** - Enhanced terminal with autosuggestions and syntax highlighting
- **Modern CLI tools** - ripgrep, fzf, bat, delta for better development experience
- **VS Code extensions** - ESLint, Prettier, GitLens, and more pre-configured

### 🤖 Claude Development Tools
- **Claude Code** - Latest version installed globally from npm
- **Claude Flow** - v2.0.0-alpha with advanced swarm orchestration
  - ✅ Accessed via npx - always runs latest version
  - 📂 Source code cloned to `/workspace/deps/claude-flow` for exploration
  - 🔄 No updates needed - npx fetches latest automatically
- **ruv-FANN** - Neural network swarm framework for claude-flow
  - 📂 Full source cloned to `/workspace/deps/ruv-FANN` for development
  - 🚀 ruv-swarm MCP server available for manual configuration
  - 🔧 No installation required - accessible via npx

### 🛡️ Security Features
- **Three security presets** - Paranoid, Enterprise, and Development modes
- **Container-level firewall** - Network isolation without affecting your host
- **Domain allowlisting** - Controlled access to external services
- **Process isolation** - Safe execution environment

### 💡 Developer Benefits
- **📝 Contribute to open source** - Both claude-flow and ruv-FANN sources included for development
- **🔄 Stay updated** - Pull latest changes directly in the workspace
- **🧪 Test locally** - Modify and test changes before committing
- **🚀 Fast MCP connections** - Local servers reduce latency
- **📚 Full documentation** - CLAUDE.md, README.md, and SECURITY.md included
- **🎯 Pre-initialized** - Claude Flow initialized with verified MCP server

## Environment Variables

Available environment variables:

- `ANTHROPIC_API_KEY` - Your API key (only needed if using API key authentication)
- `SECURITY_PRESET` - Security level: `paranoid`, `enterprise`, or `development` (default)
- `DEVCONTAINER=true` - Automatically set in the container
- `NODE_ENV=development` - Automatically set in the container

## Workspace Structure

When you open your project in the container:
- `/workspace` - Your project root (mounted from your local machine)
- `/workspace/deps/` - Claude Flow and ruv-FANN source code (auto-created)

## Security Features

This devcontainer provides comprehensive protection:

### 🛡️ Two-Layer Security Model

1. **Local Machine Protection**
   - Container runs with restricted privileges
   - Filesystem access limited to workspace
   - No access to host system or personal files
   - Process isolation prevents malware installation

2. **Network Protection**
   - **Container-level firewall rules** (not affecting host)
   - Configurable security presets (never skipped)
   - Domain allowlisting/blocklisting
   - Prevents data exfiltration
   - Protects against supply chain attacks

### 🎚️ Security Presets

Security is **always applied** but with different levels of strictness:

- **Paranoid**: Maximum isolation - explicit allowlist only
- **Enterprise**: Balanced security - common dev services allowed  
- **Development**: Permissive - blocklist for known malicious sites (default)

The firewall runs at container startup with root privileges, ensuring rules cannot be bypassed.

See [SECURITY.md](SECURITY.md) for detailed configuration options.

## Troubleshooting

### Container Build Issues
If the container fails to build:
```bash
# Clean rebuild without cache
docker system prune -a
# Then reopen in VS Code
```

### "iptables: Permission denied" 
This is expected behavior - the container shows this message but continues without network isolation. The security rules are applied at container startup when running with proper privileges. This does not affect functionality.

### "chown: Operation not permitted" on node_modules
This is normal - node_modules is a Docker volume and ownership is managed by Docker. This warning can be ignored.

### Network connectivity issues
Check your security preset:
```bash
echo $SECURITY_PRESET
```
- **Paranoid/Enterprise**: Only allowed domains work. Add custom domains to `.env`:
  ```bash
  CUSTOM_ALLOWED_DOMAINS=api.mycompany.com,npm.mycompany.com
  ```
- **Development**: Most connections allowed, only known malicious sites blocked

### Claude Flow not working
Since we use npx, claude-flow should always work. If it doesn't:
```bash
# Check network connectivity
ping registry.npmjs.org

# Try with explicit version
npx claude-flow@2.0.0-alpha.53 --version

# Clear npx cache if needed
rm -rf ~/.npm/_npx
npx claude-flow@alpha --version
```

### Updating Claude Flow
Claude Flow always uses the latest version via npx:
```bash
# No update needed - npx fetches latest automatically!

# For development, pull latest source
cd /workspace/deps/claude-flow
git pull origin main

# Verify version
npx claude-flow@alpha --version
```

### VS Code doesn't show "Reopen in Container"
1. Ensure Remote-Containers extension is installed
2. Check Docker is running: `docker ps`
3. Try Command Palette (Cmd/Ctrl+Shift+P): "Remote-Containers: Reopen in Container"

### "No space left on device" during container build
If you encounter disk space errors during build:

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
   # On macOS/Linux
   df -h
   ```

4. **If using Docker Desktop**, increase the disk image size:
   - Open Docker Desktop
   - Go to Settings/Preferences → Resources
   - Increase the "Disk image size" slider
   - Apply & Restart

### Deno PATH prompt during setup
If you missed the prompt "Edit shell configs to add deno to the PATH? (Y/n)" during container creation:
- This prompt appears during claude-flow initialization
- Answer **Y** (yes) to ensure claude-flow works correctly
- If you accidentally selected 'n', you can manually add Deno to PATH later

### Node.js Out of Memory Errors
If you encounter "JavaScript heap out of memory" errors:

1. **Increase memory in .env**:
   ```bash
   CONTAINER_MEMORY=12g  # Increase from default 8g
   ```

2. **Check current memory usage**:
   ```bash
   # Inside container
   echo "Container Memory: $(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo 'unlimited')"
   echo "Node.js Heap: $NODE_OPTIONS"
   # Or run health check if available
   bash /devcontainer-config/scripts/health-check.sh 2>/dev/null || true
   ```

3. **Temporary fix for current session**:
   ```bash
   export NODE_OPTIONS="--max-old-space-size=8192"  # 8GB
   ```

4. **Rebuild container** after changing memory settings

### Container Disconnection Issues
If your container suddenly disconnects:

1. **Check Docker Desktop resources**:
   - Go to Docker Desktop → Settings → Resources
   - Ensure Docker has enough memory (16GB+ recommended)
   - Increase CPU limit if needed

2. **Add to .env for stability**:
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

4. **Common causes**:
   - Docker Desktop memory limits
   - System running out of resources
   - Network interruptions
   - Heavy swarm operations consuming resources

## Testing

Run automated tests to verify your setup:
```bash
# From your project root (after adding the devcontainer)
./.devcontainer/scripts/tests/test-devcontainer.sh

# Tests check for:
# - Valid JSON configuration
# - Successful container build
# - Proper tool installation
# - Container persistence
# - Security initialization
# - Common configuration errors
```

## ⚠️ Security Disclaimer

**USE AT YOUR OWN RISK**

This container runs AI agents with elevated permissions (`--dangerously-skip-permissions`) which poses inherent security risks:

### Potential Risks Include:
- **🔓 Code Exposure** - AI agents can read and potentially expose your source code
- **💉 Prompt Injection** - Malicious prompts could manipulate agent behavior
- **🚨 Security Bypass** - Agents may circumvent security measures if instructed
- **📤 Data Exfiltration** - Despite network controls, data could be leaked through allowed channels
- **🔥 Resource Exhaustion** - Runaway agents could consume system resources
- **🐛 Unintended Actions** - AI hallucinations could lead to destructive operations

### Recommended Precautions:
- ✅ Use **Paranoid** mode for untrusted code or sensitive projects
- ✅ Never store production credentials or secrets in the container
- ✅ Regularly review agent actions and generated code
- ✅ Run in isolated environments when possible
- ✅ Monitor container resource usage
- ✅ Keep backups of important work

**By using this container, you acknowledge these risks and accept full responsibility for any consequences. This software is provided "AS IS" without warranty of any kind.**


## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Flow GitHub](https://github.com/ruvnet/claude-flow)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)