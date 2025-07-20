# Version Information

This document tracks the current working versions of the core components in the Swarm Container.

## Core Components

| Component | Version | Source | Notes |
|-----------|---------|--------|-------|
| **Claude Code** | v1.0.56 | npm: `@anthropic-ai/claude-code` | Installed globally via npm |
| **Claude Flow** | v2.0.0-alpha.63 | npm: `claude-flow@alpha` | Installed globally from npm, source in `/workspace/deps/claude-flow` |
| **ruv-FANN/ruv-swarm** | v1.0.18 | GitHub: `ruvnet/ruv-FANN` | Cloned to `/workspace/deps/ruv-FANN`, ruv-swarm installed with `--production` |
| **OpenAI Codex** | Latest | npm: `@openai/codex` | Installed globally via npm |
| **Google Gemini CLI** | Latest | npm: `@google/gemini-cli` | Installed globally via npm |

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

## Updating Components

### Claude Code
```bash
npm update -g @anthropic-ai/claude-code
```

### Claude Flow
```bash
cd /workspace/deps/claude-flow
git pull origin main
npm install
npm run build
npm install -g .
```

### ruv-FANN
```bash
cd /workspace/deps/ruv-FANN
git pull origin main
cd ruv-swarm/npm
npm install --production
```

### OpenAI Codex
```bash
npm update -g @openai/codex
```

### Google Gemini CLI
```bash
npm update -g @google/gemini-cli
```

## Version Compatibility

- Claude Code requires Node.js 14.0.0 or higher
- Claude Flow is compatible with the latest Claude Code
- ruv-FANN's ruv-swarm requires Node.js 14.0.0 or higher
- OpenAI Codex requires Node.js 16.0.0 or higher
- Google Gemini CLI requires Node.js 18.0.0 or higher

## Known Issues

- wasm-opt npm package has platform compatibility issues, resolved by using `npm install --production` for ruv-swarm

Last updated: July 2025