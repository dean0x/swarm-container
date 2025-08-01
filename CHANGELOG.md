# Changelog

All notable changes to SwarmContainer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-07-27

### 🎉 Major Release: Drop-in DevContainer with Dynamic Resource Allocation

This release completely transforms SwarmContainer into a true drop-in devcontainer with intelligent resource management.

### ✨ Added
- **🧠 Dynamic Memory Allocation**: Automatically detects container memory and sets Node.js heap to 75%
  - Supports both cgroup v1 and v2 for broad compatibility
  - Eliminates out-of-memory errors across all security presets
  - Smart fallbacks ensure minimum 512MB heap
- **📦 MCP Server Support**: Pre-configured Model Context Protocol servers
  - Browser automation, web search, and custom integrations
  - Optional file watcher for live configuration updates
- **🔄 Drop-in Integration**: Three easy integration methods (git submodule, subtree, clone)
- **🧪 Enhanced Testing**: NODE_OPTIONS verification and 8 comprehensive test categories
- **📜 New Scripts**:
  - `scripts/hooks/set-node-memory.sh` - Dynamic memory allocation logic
  - Enhanced `docker-entrypoint.sh` with memory initialization
  - Improved `postCreate.sh` with versioned command history
- **🔧 Modular PostCreate**: Split into 6 focused modules for better maintainability
- **🤖 GitHub Actions CI**: Automated testing on every push

### 🔧 Changed
- **🛡️ Updated Security Presets**:
  - Paranoid: 6GB memory, 2 CPUs (increased from 4GB - was insufficient)
  - Enterprise: 12GB memory, 6 CPUs (reduced from 16GB/8 CPUs - more reasonable)
  - Development: 8GB memory, 4 CPUs (unchanged)
- **📁 Repository Structure**: Moved all files from `.devcontainer/` to root for drop-in functionality
- **🔧 MCP Configuration**: Automatic setup with environment variable support
- **📝 Command History**: Implemented versioned guard file system (v2) for seamless updates

### 🐛 Fixed
- **⏱️ MCP Server Blocking**: Added timeout to prevent container setup from hanging
- **💾 Memory Exhaustion**: Dynamic allocation prevents OOM errors in all presets  
- **🔄 History Updates**: Versioned system allows command updates without conflicts
- **🧹 Script Organization**: All scripts properly organized under `scripts/` subdirectories
- **🐚 Shell Environment**: Fixed oh-my-zsh installation and plugin setup
- **📝 Documentation**: Cleaned up for new users, removed outdated references

### 🗑️ Removed
- **❌ Claude Flow**: Removed all Claude Flow integration to focus on Claude Code
- **❌ Multi-AI CLIs**: Removed Codex and Gemini CLIs - focused on Claude Code only
- **❌ Command Aliases**: Removed cf, cfh, cfw aliases as requested
- **❌ Hardcoded NODE_OPTIONS**: Now calculated dynamically based on container memory
- **❌ Manual Completion Setup**: Let Oh My Zsh handle completions naturally

### 🏗️ Breaking Changes
- Repository structure reorganized - all files moved from `.devcontainer/` to root
- Integration now requires one of three drop-in methods (submodule/subtree/clone)
- Previous workspace structure no longer compatible

### 📊 Technical Improvements
- **Memory Detection**: Supports cgroup v1 (`/sys/fs/cgroup/memory/`) and v2 (`/sys/fs/cgroup/memory.max`)
- **Error Handling**: Comprehensive fallbacks for memory detection and tool installation
- **Test Coverage**: All 8 test categories pass including new NODE_OPTIONS verification
- **Documentation**: Complete resource requirements guide with scaling recommendations

### 🎯 Benefits
- **Zero Friction**: Add devcontainer with single command
- **Smart Resources**: No more manual memory configuration
- **Always Current**: MCP servers via npx for latest versions
- **Production Ready**: 23 commits of improvements with comprehensive testing
- **CI/CD**: Automated testing ensures quality on every change

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
- Claude Code installation and configuration
- MCP server support with pre-configured servers
- Comprehensive test suite for container validation
- Support for Windows (WSL2), macOS (Intel/ARM), and Linux
- Clean workspace organization
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
- Smart installation fallbacks for maximum compatibility
- VS Code integration with recommended extensions
- Persistent command history across container restarts
- Modern CLI tools: ripgrep, fzf, bat, delta

[1.1.0]: https://github.com/dean0x/swarm-container/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/dean0x/swarm-container/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/dean0x/swarm-container/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dean0x/swarm-container/releases/tag/v1.0.0