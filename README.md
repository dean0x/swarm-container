# Swarm Container

[![CI](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml/badge.svg)](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/dean0x/swarm-container)](https://github.com/dean0x/swarm-container/releases)

A drop-in VS Code development container for running Claude Code in a secure, isolated environment.

🔒 **Features multiple security presets**: Paranoid, Enterprise, and Development modes to match your security requirements.

## ✨ Highlights

- **🛡️ Isolated Security** - Container-level firewall and network isolation keeps your host system safe while working with AI
- **🧠 Dynamic Memory Allocation** - Automatically sets Node.js heap to 75% of container memory, prevents OOM errors across all security presets
- **⚡ Zero-Latency MCP** - Local MCP servers for enhanced Claude Code capabilities
- **🔧 Auto-Updating MCP Config** - Live configuration updates with file watcher - modify `.mcp.config` and changes apply instantly
- **📦 Smart Fallbacks** - Multiple installation strategies ensure everything works on your machine (ARM, x86, Mac, Linux)
- **🧪 Battle-Tested** - Comprehensive test suite validates your setup before you even start coding
- **🌐 Cloud Ready** - Optional deployment to Fly.io for remote development from anywhere



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
| **Claude Code** | v1.0.56 | July 2025 |

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
- Configure MCP servers
- Set up your development environment

⏱️ **This takes 3-5 minutes on first run**

### 4. Start Using Claude Code

Once the container is ready:

```bash
# Activate Claude Code
claude --dangerously-skip-permissions

# If using Option A (Claude Pro/Max), you'll see:
# "Please visit: https://[...] to authenticate"
# Click the link and log in with your Claude account
```

### 💡 Container Tips

```bash
# Update Claude Code to latest version
update-claude

# Check memory allocation
echo $NODE_OPTIONS

# View MCP server status
claude mcp list

# Check security preset
echo $SECURITY_PRESET
```

## 🌐 Remote Development Option

Want to access your development environment from anywhere? SwarmContainer now supports deployment to [Fly.io](https://fly.io) for cloud-based development.

### Benefits
- 🌍 **Access from anywhere** - Work from any device with SSH
- 💪 **Scalable resources** - Need more power? Scale up instantly  
- 👥 **Team collaboration** - Share environments with your team
- 💰 **Cost effective** - Pay only for what you use (~$5-20/month)

### Quick Start
```bash
# Set up in under 5 minutes
flyctl auth login
./scripts/fly-volume-setup.sh
./scripts/fly-ssh-setup.sh  
flyctl deploy
```

**[Full Fly.io Setup Guide →](docs/fly-io-setup.md)**

> **Note**: Remote development is completely optional. All existing local features work exactly as before.

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
| 4GB | 3GB | Basic Claude Code operations |
| 6GB | 4.5GB | Paranoid mode with limited resources |
| 8GB | 6GB | Standard development (default) |
| 12GB | 9GB | Enterprise development workloads |
| 16GB+ | 12GB+ | Large-scale development operations |

**Minimum Requirements**:
- Single Claude Code instance: 4GB memory, 2 CPUs
- Multiple concurrent tasks: 8GB memory, 4 CPUs  
- Heavy development workloads: 12GB memory, 6 CPUs
- Large-scale operations: 16GB+ memory, 8+ CPUs

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
- **MCP Servers** - Configurable Model Context Protocol servers
  - Browser automation tools
  - Web search capabilities
  - Custom integrations via `.mcp.config`

### 🛡️ Security Features
- **Three security presets** - Paranoid, Enterprise, and Development modes
- **Container-level firewall** - Network isolation without affecting your host
- **Domain allowlisting** - Controlled access to external services
- **Process isolation** - Safe execution environment

### 💡 Developer Benefits
- **🔧 Customizable MCP servers** - Configure your own AI tools
- **🚀 Fast MCP connections** - Local servers reduce latency
- **📚 Full documentation** - CLAUDE.md, README.md, and SECURITY.md included
- **🎯 Pre-configured** - Ready to use with Claude Code

## Environment Variables

Available environment variables:

- `ANTHROPIC_API_KEY` - Your API key (only needed if using API key authentication)
- `SECURITY_PRESET` - Security level: `paranoid`, `enterprise`, or `development` (default)
- `DEVCONTAINER=true` - Automatically set in the container
- `NODE_ENV=development` - Automatically set in the container

## Workspace Structure

When you open your project in the container:
- `/workspace` - Your project root (mounted from your local machine)

**For cloud deployment**: The same structure is maintained with persistent volumes. See [Fly.io Setup Guide](docs/fly-io-setup.md) for details.

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
   # Current memory settings will be displayed
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
   - Heavy development operations consuming resources

## Remote Development (Cloud Deployment)

SwarmContainer supports deployment to cloud platforms for remote development. This enables:
- 🌍 Access your development environment from anywhere
- 💻 Consistent environment across devices
- 🚀 More powerful cloud resources
- 👥 Shared environments for teams

### Quick Start with Fly.io

#### 1. Initial Setup (One-time)
```bash
# Run the setup assistant
./scripts/fly-setup.sh

# This will:
# - Install flyctl CLI
# - Set up SSH keys
# - Configure your Fly.io account
# - Create initial configuration
```

#### 2. Deploy Your Environment
```bash
# Option A: Interactive deployment with configuration file
./scripts/fly-deploy.sh deploy

# Option B: Quick deployment with command-line args
./scripts/fly-deploy.sh deploy my-dev-env iad
```

#### 3. Connect to Your Environment
```bash
# SSH directly
ssh node@my-dev-env.fly.dev -p 10022

# Or use VS Code Remote-SSH
# The deploy script generates SSH config automatically
```

### Configuration

Create `.env.fly` from the example:
```bash
cp .env.fly.example .env.fly
# Edit with your preferences
```

Key settings:
- `FLY_APP_NAME`: Your unique app identifier
- `FLY_REGION`: Deployment region (iad, lhr, etc.)
- `FLY_VM_SIZE`: Machine size (shared-cpu-1x to 8x)
- `FLY_VM_MEMORY`: RAM allocation (256mb to 8gb)
- `AUTO_STOP_MACHINES`: Save costs by auto-stopping when idle

### Cost Management

- **Auto-stop enabled**: Machines stop after 5 minutes idle
- **Typical costs**: $2-5/month with auto-stop
- **Monitor usage**: `./scripts/fly-deploy.sh status`
- **Destroy when done**: `./scripts/fly-deploy.sh destroy`

### Learn More

- [Detailed Fly.io Setup Guide](docs/fly-io-setup.md)
- [Remote Development Alternatives](docs/remote-development-alternatives.md)
- [Orchestration Guide](docs/swarm-orchestration-implementation-plan.md)

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
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Fly.io Remote Development Guide](docs/fly-io-setup.md)
- [Development Team Agents Guide](docs/development-team-agents-guide.md)