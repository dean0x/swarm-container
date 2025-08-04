# Version Information

## Core Components

| Component | Version | Last Tested | Notes |
|-----------|---------|-------------|-------|
| **Claude Code** | v1.0.56 | January 2025 | Installed via npm |
| **Node.js** | 20.x | January 2025 | LTS version |
| **VS Code Dev Containers** | Latest | January 2025 | Extension required |

## Container Base

- **Base Image**: `mcr.microsoft.com/devcontainers/javascript-node:20-bullseye`
- **Operating System**: Debian 11 (Bullseye)
- **Architecture Support**: amd64, arm64

## Productivity Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| **lazygit** | Git UI | Binary download |
| **lazydocker** | Docker UI | Binary download |
| **eza** | Modern ls | Binary download |
| **bat** | Syntax highlighting | apt |
| **bottom** | System monitor | Binary download |
| **dust** | Disk usage | Binary download |
| **zoxide** | Smart cd | Cargo |
| **tokei** | Code statistics | Cargo |
| **jq** | JSON processor | apt |
| **httpie** | HTTP client | apt |
| **tldr** | Simplified man pages | npm |
| **mcfly** | Smart shell history | Cargo |
| **gh** | GitHub CLI | apt |

## Security Tools

- **iptables** - Container firewall
- **auditd** - Security auditing
- **apparmor** - Application security
- **ipset** - IP set management

## Updating Components

### Claude Code
```bash
# Inside container
update-claude  # Wrapper script with proper permissions
```

### Container Image
```bash
# Outside container
cd .devcontainer && git pull origin main
# Then rebuild container in VS Code
```

## Compatibility Requirements

- **Docker Desktop**: 4.0+ with 8GB+ memory allocated
- **VS Code**: 1.60+
- **Claude Code**: Requires Node.js 14.0.0+

## Version History

- **January 2025**: Initial release with Claude Code v1.0.56
- **January 2025**: Added productivity tools and Fly.io support
- **January 2025**: Dynamic resource allocation for multi-instance support