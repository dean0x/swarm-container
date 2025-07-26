# Version Information

This document tracks the current working versions of the core components in the Swarm Container.

## Core Components

| Component | Version | Source | Notes |
|-----------|---------|--------|-------|
| **Claude Code** | v1.0.56 | npm: `@anthropic-ai/claude-code` | Installed globally via npm |

## Container Base

- **Base Image**: `mcr.microsoft.com/devcontainers/javascript-node:20-bullseye`
- **Node.js**: 20.x
- **npm**: Latest (comes with Node.js 20)

## Key Dependencies

### Security & System Tools
- iptables (for container-level firewall)
- auditd (security auditing)
- apparmor (application security)

### Development Tools
- ripgrep (fast searching)
- fzf (fuzzy finder)
- bat (better cat)
- git-delta (better diffs)
- zsh with Oh My Zsh
- set-node-memory.sh (dynamic memory allocation script)

## Updating Components

### Claude Code
```bash
npm update -g @anthropic-ai/claude-code
```


## Version Compatibility

- Claude Code requires Node.js 14.0.0 or higher

Last updated: July 2025