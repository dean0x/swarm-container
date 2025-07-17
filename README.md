# Swarm Container

[![CI](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml/badge.svg)](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/dean0x/swarm-container)](https://github.com/dean0x/swarm-container/releases)

A secure, isolated development container for running agentic swarms, and CLIs with loose permissions, using Dev Containers in VS Code.

🔒 **Features multiple security presets**: Paranoid, Enterprise, and Development modes to match your security requirements.

## ✨ Highlights

- **🛡️ Isolated Security** - Container-level firewall and network isolation keeps your host system safe while experimenting with AI agents
- **🚀 Bleeding Edge Updates** - Claude Flow and ruv-swarm installed from source, giving you instant access to the latest features from main branch
- **💻 Local Development Ready** - Full source code for both claude-flow and ruv-FANN in your workspace - modify, test, and contribute back
- **⚡ Zero-Latency MCP** - Local MCP servers eliminate network roundtrips for lightning-fast agent coordination
- **🔧 Production + Development** - Global npm installs for reliability, plus source code for hacking and exploration
- **📦 Smart Fallbacks** - Multiple installation strategies ensure everything works on your machine (ARM, x86, Mac, Linux)
- **🧪 Battle-Tested** - Comprehensive test suite validates your setup before you even start coding

## Supported Swarm Orchestrators

| Orchestrator | Description | Status | |
|-------------|-------------|---------|---|
| [claude-flow](https://github.com/ruvnet/claude-flow) | Advanced swarm intelligence with SQLite memory system and GitHub integration | ✅ Available | Auto-initialized |
| [claude-swarm](https://github.com/parruda/claude-swarm) | Multi-agent orchestration with tree hierarchy and MCP communication | 🔜 Coming Soon | |

## Supported AI CLIs

| [Claude Code](https://claude.ai/code) | [OpenCode](https://github.com/opencode) | [Codex](https://openai.com/codex) | [Gemini](https://gemini.google.com) |
|:---:|:---:|:---:|:---:|
| ✅ **Available** | 🔜 Coming Soon | 🔜 Coming Soon | 🔜 Coming Soon |

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

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/yourusername/swarmcontainer.git
cd swarmcontainer

# Choose your security level (default is 'development')
cp .env.development .env    # For local development (recommended to start)
# OR
cp .env.enterprise .env     # For corporate environments with some restrictions
# OR
cp .env.paranoid .env       # For maximum security with untrusted code
```

### 2. Set Up Authentication

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

### 3. Open in VS Code

```bash
# Open VS Code in the current directory
code .
```

**Then:**
1. Wait for the notification "Folder contains a Dev Container configuration file"
2. Click **"Reopen in Container"**
3. Or use Command Palette (F1/Cmd+Shift+P): "Dev Containers: Reopen in Container"

**First-time setup will:**
- Download the base Docker image
- Install all dependencies
- Clone claude-flow and ruv-FANN sources
- Configure MCP servers
- Set up your development environment

⏱️ **This takes 3-5 minutes on first run**

### 4. Container Setup Prompts

During setup, you'll see:

1. **Deno PATH prompt**: 
   ```
   Edit shell configs to add deno to the PATH? (Y/n)
   ```
   **➜ Type `Y` and press Enter** (required for MCP servers)

2. **Progress messages** showing:
   - Security level initialization
   - Claude Flow installation
   - MCP server configuration

### 5. Start Using Claude Flow

Once the container is ready:

```bash
# Step 1: Activate Claude Code (required for claude-flow)
claude --dangerously-skip-permissions

# If using Option A (Claude Pro/Max), you'll see:
# "Please visit: https://[...] to authenticate"
# Click the link and log in with your Claude account

# Step 2: Verify installation
claude-flow --version

# Step 3: Start building!
# Quick swarm spawn
claude-flow hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude

# Or use the interactive wizard
claude-flow hive-mind wizard

# Or explore example commands (press ↑ arrow for history)
# We've pre-loaded useful commands in your shell history!
```

### 📋 Configuration Options

#### Security Presets Explained

| Preset | Network Access | Use Case | Firewall Rules |
|--------|---------------|----------|----------------|
| **development** | Most permissive | Local development, learning | Blocks only known malicious |
| **enterprise** | Balanced | Corporate environments | Allows dev tools, blocks risky |
| **paranoid** | Highly restricted | Untrusted code, sensitive data | Explicit allowlist only |

📄 **See [security-config.json](.devcontainer/scripts/security/security-config.json) for detailed preset definitions**

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

# Resources (optional)
CONTAINER_MEMORY=8g                    # Container memory limit
CONTAINER_CPUS=4                       # CPU core limit

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
Your work is saved in the `workspace/` directory:
- All files in `workspace/` persist between container restarts
- Dependencies in `workspace/deps/` are git-ignored
- Command history is preserved

#### Shell Customization
The container includes:
- Zsh with Oh My Zsh
- Auto-suggestions and syntax highlighting
- Pre-loaded command history
- Custom aliases and functions

📚 **For detailed security configuration, see [SECURITY.md](SECURITY.md)**

## What's Included

### 🧰 Development Environment
- **Node.js 20** with npm for modern JavaScript development
- **Zsh with Oh My Zsh** - Enhanced terminal with autosuggestions and syntax highlighting
- **Modern CLI tools** - ripgrep, fzf, bat, delta for better development experience
- **VS Code extensions** - ESLint, Prettier, GitLens, and more pre-configured

### 🤖 AI Development Tools
- **Claude Code** - Latest version installed globally from npm
- **Claude Flow** - v2.0.0-alpha with advanced swarm orchestration
  - ✅ Globally installed from npm for reliability
  - 📂 Source code in `/workspace/deps/claude-flow` for exploration and contributions
  - 🔄 Easy updates with `npm update -g claude-flow@alpha`
- **ruv-FANN** - Neural network swarm framework
  - 📂 Full source in `/workspace/deps/ruv-FANN` for development
  - 🚀 ruv-swarm MCP server auto-configured for local connections
  - 🔧 Production dependencies only (no build issues)

### 🛡️ Security Features
- **Three security presets** - Paranoid, Enterprise, and Development modes
- **Container-level firewall** - Network isolation without affecting your host
- **Domain allowlisting** - Controlled access to external services
- **Process isolation** - Safe execution environment

### 💡 Developer Benefits
- **📝 Contribute to open source** - Both claude-flow and ruv-FANN sources included
- **🔄 Stay updated** - Pull latest changes directly in the workspace
- **🧪 Test locally** - Modify and test changes before committing
- **🚀 Fast MCP connections** - Local servers reduce latency
- **📚 Full documentation** - CLAUDE.md, README.md, and SECURITY.md included
- **🎯 Pre-initialized** - Claude Flow ready to use immediately

## Environment Variables

Available environment variables:

- `ANTHROPIC_API_KEY` - Your API key (only needed if using API key authentication)
- `SECURITY_PRESET` - Security level: `paranoid`, `enterprise`, or `development` (default)
- `DEVCONTAINER=true` - Automatically set in the container
- `NODE_ENV=development` - Automatically set in the container

## Workspace Structure

The container creates these directories:
- `/workspace` - Your project files

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

### Claude Flow not found
The container installs Claude Flow from source. If it fails:
```bash
# Check installation
which claude-flow

# Reinstall from npm if needed
npm install -g claude-flow@alpha
```

### Updating Claude Flow
To update to the latest version:
```bash
# Update from npm (recommended)
npm update -g claude-flow@alpha

# Or pull latest source for development
cd /workspace/deps/claude-flow
git pull origin main

# Verify update
claude-flow --version
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
- This prompt appears during MCP server configuration
- Answer **Y** (yes) to ensure MCP servers work correctly
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
   bash /devcontainer-config/.devcontainer/scripts/health-check.sh
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

Run automated tests before opening in VS Code:
```bash
# Run all tests
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