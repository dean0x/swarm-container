# Changelog

All notable changes to SwarmContainer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-01-18

### Added
- Multi-AI CLI support: OpenAI Codex and Google Gemini CLIs
- Global installation of ruv-swarm from source
- Security allowlist entries for OpenAI and Google AI domains
- Shell history commands for new CLIs (codex --help, gemini --help)

### Improved
- npm install now uses --omit=dev flag instead of deprecated --production
- Better error handling and logging for ruv-swarm installation
- MCP configuration now uses globally installed ruv-swarm command
- Documentation updated to show multi-AI CLI support

### Fixed
- Platform compatibility issues with wasm-opt by skipping devDependencies

## [1.0.1] - 2025-01-17

### Fixed
- Node.js out of memory errors by setting NODE_OPTIONS to 4GB heap size
- Container disconnection issues with resource limits and restart policy
- Dockerfile syntax for git-delta installation on Debian 11

### Added
- Health check script for monitoring container resources
- Container memory management with configurable limits
- Shared memory configuration (2GB) for heavy operations
- Dynamic memory threshold in health monitoring
- Consistent "SwarmContainer" naming throughout project

### Improved
- Comprehensive troubleshooting documentation for memory and stability issues
- Resource allocation guidance for Docker Desktop
- Container stability with --restart=unless-stopped flag

## [1.0.0] - 2025-01-15

### Added
- Initial release of SwarmContainer
- Three security presets: Paranoid, Enterprise, and Development modes
- Automatic installation of Claude Flow from source with npm fallback
- Automatic installation of ruv-FANN with production-only dependencies
- Local MCP server configuration for claude-flow and ruv-swarm
- Comprehensive test suite for container validation
- Support for Windows (WSL2), macOS (Intel/ARM), and Linux
- Clean workspace organization with deps/ folder for dependencies
- Shell history pre-populated with useful commands
- Zsh with Oh My Zsh, autosuggestions, and syntax highlighting
- Docker entrypoint with proper security initialization
- Organized script structure under .devcontainer/scripts/

### Security
- Container-level firewall with iptables rules
- Domain-based allowlisting and blocklisting
- Process isolation and capability dropping
- Resource limits (memory and CPU)
- Security monitoring script for runtime checks

### Developer Experience
- Both claude-flow and ruv-FANN source code available for contributions
- Smart installation fallbacks for maximum compatibility
- VS Code integration with recommended extensions
- Persistent command history across container restarts
- Modern CLI tools: ripgrep, fzf, bat, delta

[1.0.1]: https://github.com/dean0x/swarm-container/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dean0x/swarm-container/releases/tag/v1.0.0