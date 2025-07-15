# Swarm Container

[![CI](https://github.com/yourusername/swarmcontainer/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/swarmcontainer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/yourusername/swarmcontainer)](https://github.com/yourusername/swarmcontainer/releases)

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

## Quick Start

### 1. Choose Your Security Level

```bash
# For maximum security (untrusted code)
cp .env.paranoid .env

# For corporate environments
cp .env.enterprise .env

# For local development
cp .env.development .env
```

### 2. Configure Your Environment

Choose your authentication method:

**Option A: Claude Pro/Max** (use browser login)
```bash
# Leave .env as is - you'll be prompt to login after starting Claude Code
```

**Option B: API Key** (if you have one)
```bash
# Edit .env and add your API key
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### 3. Open in VS Code

```bash
code .
```

Then click "Reopen in Container" when prompted.

**Note:** During container setup, if prompted "Edit shell configs to add deno to the PATH? (Y/n)", enter **Y** (yes). This occurs during MCP server configuration and is required for proper functionality.

### 4. Start Using Claude Flow

Inside the container:
```bash
# Activate Claude Code with full permissions (Required for claude-flow at the moment)
claude --dangerously-skip-permissions

# Spawn a hive-mind swarm
claude-flow hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude

# Or use the wizard (Still a bit quirky)
claude-flow hive-mind wizard
```

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

### Deno PATH prompt during setup
If you missed the prompt "Edit shell configs to add deno to the PATH? (Y/n)" during container creation:
- This prompt appears during MCP server configuration
- Answer **Y** (yes) to ensure MCP servers work correctly
- If you accidentally selected 'n', you can manually add Deno to PATH later

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