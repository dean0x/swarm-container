# Claude Flow DevContainer

A secure, isolated development container for running Claude Flow swarms with VS Code.

🔒 **Features multiple security presets**: Paranoid, Enterprise, and Development modes to match your security requirements.

## Prerequisites

- [VS Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code
- An [Anthropic API key](https://console.anthropic.com/account/keys) (optional - can use `/login` command instead)

## Quick Start

### 1. Choose Your Security Level

```bash
# For maximum security (untrusted code)
cp .env.paranoid .env

# For corporate environments (default)
cp .env.enterprise .env

# For local development
cp .env.development .env
```

### 2. Configure Your Environment

Edit `.env` to optionally add your API key:
```bash
# Option 1: Set API key as environment variable
ANTHROPIC_API_KEY=sk-ant-your-key-here

# Option 2: Leave empty and use /login command after starting Claude Code
# ANTHROPIC_API_KEY=
```

### 3. Open in VS Code

```bash
code .
```

Then click "Reopen in Container" when prompted.

### 4. Start Using Claude Flow

Inside the container:
```bash
# Activate Claude Code Skip Permissions For Claude Flow
claude --dangerously-skip-permissions

# Launch Claude Flow
claude-flow hive-mind wizard
```

📚 **For detailed security configuration, see [SECURITY.md](SECURITY.md)**

## What's Included

- **Node.js 20** development environment
- **Claude Code** and **Claude Flow** pre-installed
- **Security features**:
  - Network isolation with firewall rules
  - Default-deny outbound connections
  - Whitelisted access to npm, GitHub, and Anthropic APIs
- **Developer tools**:
  - Zsh with Oh My Zsh
  - Git with delta for better diffs
  - ripgrep, fzf, bat, and other modern CLI tools
  - VS Code extensions for JavaScript/TypeScript development

## Environment Variables

Set these in your container or in a `.env` file:

- `ANTHROPIC_API_KEY` - Optional for Claude Code functionality (can also use `/login` command)
- `DEVCONTAINER=true` - Automatically set in the container
- `NODE_ENV=development` - Automatically set in the container

## Workspace Structure

The container creates these directories:
- `/workspace/swarms` - For swarm configurations
- `/workspace/logs` - For execution logs
- `/workspace/data` - For data storage

## Security Features

This devcontainer provides comprehensive protection:

### 🛡️ Two-Layer Security Model

1. **Local Machine Protection**
   - Container runs with restricted privileges
   - Filesystem access limited to workspace
   - No access to host system or personal files
   - Process isolation prevents malware installation

2. **Network Protection**
   - Configurable firewall with domain allowlisting
   - Blocks unauthorized outbound connections
   - Prevents data exfiltration
   - Protects against supply chain attacks

### 🎚️ Security Presets

- **Paranoid**: Maximum isolation for untrusted code
- **Enterprise**: Balanced security with corporate service access  
- **Development**: Flexible settings for local development

See [SECURITY.md](SECURITY.md) for detailed configuration options.

## Troubleshooting

### "Permission denied" errors
The container runs as the `node` user. Ensure files are owned by the correct user:
```bash
sudo chown -R node:node /workspace
```

### Network connectivity issues
The firewall blocks most outbound connections. If you need to access additional services, modify `.devcontainer/init-firewall.sh` to add allowed IPs.

### Claude Flow not found
If claude-flow isn't available, install it manually:
```bash
npm install -g claude-flow@alpha
```

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Flow GitHub](https://github.com/ruvnet/claude-flow)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)