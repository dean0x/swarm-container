# Swarm Container

[![CI](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml/badge.svg)](https://github.com/dean0x/swarm-container/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/dean0x/swarm-container)](https://github.com/dean0x/swarm-container/releases)

A drop-in VS Code development container for running Claude Code in a secure, isolated environment with customizable security presets.

> ⚠️ **Security Note**: This container runs AI agents with elevated permissions. See [Security Disclaimer](#-security-disclaimer) for important safety information.

> 📊 **Resource Configuration**: By default, the container is configured for 6 Claude Code instances (5GB RAM, 2 CPUs). You can adjust this based on your needs - from 1 instance (3GB RAM) to 50+ instances (32GB+ RAM). See [Multi-Instance Configuration](CLAUDE.md#multi-instance-configuration) for details.

## ✨ Features

- **🛡️ Isolated Security** - Container-level firewall and network isolation
- **🤖 Multi-Instance Support** - Run 1-100+ Claude Code instances with automatic resource scaling
- **🚀 Modern CLI Tools** - Pre-installed: lazygit, lazydocker, eza, zoxide, bottom, and more
- **⚡ Zero-Latency MCP** - Local MCP servers for enhanced Claude Code capabilities
- **🔧 Auto-Configuration** - Smart resource allocation and live config updates
- **🌐 Cloud Ready** - Optional Fly.io deployment for remote development

## Prerequisites

- [VS Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - **Windows**: Requires WSL2 backend
  - **macOS**: Intel or Apple Silicon
  - **Linux**: Native Docker
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code
- Either an [Anthropic API key](https://console.anthropic.com/account/keys) OR a [Claude Pro/Max subscription](https://claude.ai/subscription)

## 🚀 Quick Start (5 minutes)

### 1. Add to Your Project

```bash
cd your-project
git submodule add https://github.com/dean0x/swarm-container.git .devcontainer
git commit -m "Add swarm-container devcontainer"
```

### 2. Configure Environment

```bash
# Use the default development preset
cp .devcontainer/.env.development .env
```

### 3. Open in VS Code

```bash
code .
# When prompted: Click "Reopen in Container"
# Or press F1 → "Dev Containers: Reopen in Container"
```

Once the container is ready (3-5 minutes first time), activate Claude Code:

```bash
claude --dangerously-skip-permissions
# If no API key is set, use /login to authenticate via browser
```

That's it! You're ready to use Claude Code in a secure environment. 🎉

## 📖 Detailed Setup Guide

### Integration Methods

<details>
<summary><strong>Git Submodule (Recommended)</strong> - Easy updates</summary>

```bash
cd your-project
git submodule add https://github.com/dean0x/swarm-container.git .devcontainer
git commit -m "Add swarm-container devcontainer"

# To update later:
cd .devcontainer && git pull origin main
cd .. && git add .devcontainer && git commit -m "Update devcontainer"
```
</details>

<details>
<summary><strong>Git Subtree</strong> - Cleaner history</summary>

```bash
cd your-project
git subtree add --prefix=.devcontainer https://github.com/dean0x/swarm-container.git main --squash

# To update later:
git subtree pull --prefix=.devcontainer https://github.com/dean0x/swarm-container.git main --squash
```
</details>

<details>
<summary><strong>Simple Clone</strong> - No update tracking</summary>

```bash
cd your-project
git clone https://github.com/dean0x/swarm-container.git .devcontainer
rm -rf .devcontainer/.git
git add .devcontainer && git commit -m "Add devcontainer"
```
</details>

### Authentication Options

#### Option A: Claude Pro/Max Subscription (Recommended)
No configuration needed! You'll log in via browser when you start Claude Code.

#### Option B: Anthropic API Key
Add to your `.env` file:
```bash
echo "ANTHROPIC_API_KEY=sk-ant-your-key-here" >> .env
```

### Advanced Configuration

#### Security Presets
Choose your security level by copying the appropriate template:
```bash
cp .devcontainer/.env.development .env    # Default - for local development
cp .devcontainer/.env.enterprise .env     # Balanced - for corporate use
cp .devcontainer/.env.paranoid .env       # Maximum - for sensitive work
```

#### Multiple Claude Code Instances
Configure resources for concurrent Claude Code instances:
```bash
# Interactive configuration (run BEFORE opening VS Code)
./.devcontainer/scripts/configure-for-instances.sh

# Or manually set in .env:
CLAUDE_CODE_INSTANCES=10  # Adjust based on your needs
```

Resource scaling examples:
- **1 instance**: 3GB RAM, 2 CPUs (single user)
- **6 instances**: 5GB RAM, 2 CPUs (default)
- **10 instances**: 8GB RAM, 4 CPUs (team)
- **25 instances**: 17GB RAM, 8 CPUs (power user)

## 💡 Using the Container

### Essential Commands

```bash
# Claude Code
claude --dangerously-skip-permissions  # Start Claude Code
npm update -g @anthropic-ai/claude-code # Update to latest version

# Container Info
echo $SECURITY_PRESET                  # Check security level
echo $NODE_OPTIONS                     # View memory allocation
claude mcp list                        # List MCP servers
```

### Productivity Tools

| Command | Description | Tool |
|---------|-------------|------|
| `lg` | Visual git interface | lazygit |
| `lzd` | Docker container manager | lazydocker |
| `lsf`/`llf`/`laf` | Enhanced file listings | eza |
| `catf` | Syntax-highlighted viewer | bat |
| `btm` | System monitor | bottom |
| `duf` | Disk usage analyzer | dust |
| `z <dir>` | Smart directory jumping | zoxide |
| `gh` | GitHub CLI | gh |
| `help <cmd>` | Simplified man pages | tldr |

💡 **Pro tip**: Add these tools to your project's CLAUDE.md file. See [docs/CLAUDE_MD_TEMPLATE.md](.devcontainer/docs/CLAUDE_MD_TEMPLATE.md) for a template.

## 🛡️ Security & Configuration

### Security Presets

| Preset | Use Case | Network | Resources |
|--------|----------|---------|-----------|
| **development** | Local development (default) | Permissive - blocklist | 8GB RAM, 4 CPUs |
| **enterprise** | Corporate environments | Allowlist + common services | 12GB RAM, 6 CPUs |
| **paranoid** | Untrusted code | Strict allowlist only | 6GB RAM, 2 CPUs |

See [SECURITY.md](SECURITY.md) for detailed configuration.

### Environment Variables

Key settings in `.env`:

```bash
# Authentication
ANTHROPIC_API_KEY=sk-ant-...          # Optional - or use /login

# Security
SECURITY_PRESET=development            # Choose preset
CUSTOM_ALLOWED_DOMAINS=api.company.com # Add allowed domains

# Resources (auto-calculated based on instances)
CLAUDE_CODE_INSTANCES=6                # Number of Claude instances
```

## 🌐 Remote Development (Optional)

Deploy to Fly.io for cloud-based development:

```bash
# Quick setup (5 minutes)
./scripts/fly-setup.sh         # One-time setup
./scripts/fly-deploy.sh deploy # Deploy your environment

# Connect
ssh node@your-app.fly.dev -p 10022
```

**Benefits**: Access from anywhere, scalable resources, team collaboration, ~$5-20/month

📚 [Full Fly.io Setup Guide →](docs/fly-io-setup.md)

## 📦 What's Included

- **Claude Code** v1.0.56 with MCP server support
- **Node.js 20** with dynamic memory management
- **Security presets** for different trust levels
- **Modern CLI tools** for enhanced productivity
- **Zsh** with autosuggestions and syntax highlighting
- **Auto-updating** MCP configuration
- **Comprehensive test suite** for validation

See [VERSIONS.md](VERSIONS.md) for component details.

## 🛠️ Troubleshooting

Having issues? Check our comprehensive [Troubleshooting Guide](docs/troubleshooting.md) which covers:
- Container build and startup issues
- Claude Code authentication problems
- Memory and performance optimization
- Network connectivity troubleshooting
- Common warnings and their meanings

## 🧪 Testing

Run automated tests to verify your setup:
```bash
# From your project root
./.devcontainer/scripts/tests/test-devcontainer.sh
```

Tests validate: JSON configs, container build, tool installation, persistence, and security.

## ⚠️ Security Disclaimer

This container runs AI agents with elevated permissions (`--dangerously-skip-permissions`). 

**Risks include**: Code exposure, prompt injection, security bypass, data exfiltration, resource exhaustion, unintended actions.

**Mitigations**: Use appropriate security presets, never store production credentials, review generated code, run in isolated environments, maintain backups.

By using this container, you acknowledge these risks and accept full responsibility. This software is provided "AS IS" without warranty.

## 📚 Additional Resources

### Documentation
- [Quick Start Guide](docs/quick-start.md) - Get started in 5 minutes
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Security Configuration](SECURITY.md) - Detailed security presets
- [Version Information](VERSIONS.md) - Component versions and updates
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

### External Links
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Fly.io Regions](https://fly.io/docs/reference/regions/) - For remote deployment

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.