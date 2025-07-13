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

# For corporate environments
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
- **Claude Code** pre-installed from npm
- **Claude Flow** installed from source (GitHub repository)
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

### VS Code doesn't show "Reopen in Container"
1. Ensure Remote-Containers extension is installed
2. Check Docker is running: `docker ps`
3. Try Command Palette (Cmd/Ctrl+Shift+P): "Remote-Containers: Reopen in Container"

## Testing

Run automated tests before opening in VS Code:
```bash
# Run all tests
./test-devcontainer.sh

# Tests check for:
# - Valid JSON configuration
# - Successful container build
# - Proper tool installation
# - Container persistence
# - Security initialization
# - Common configuration errors
```

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Flow GitHub](https://github.com/ruvnet/claude-flow)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)