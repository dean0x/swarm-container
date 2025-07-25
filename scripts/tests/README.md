# SwarmContainer Test Suite

This directory contains comprehensive tests for the SwarmContainer devcontainer.

## Test Scripts

### Main Test Runner
- **test-all.sh** - Runs the complete test suite (use this as the main entry point)
- **test-devcontainer.sh** - Core devcontainer tests including:
  - JSON validation
  - Container build
  - Tool installations
  - Memory allocation
  - Shell script syntax
  - Integration with other test suites

### Specialized Tests
- **test-postcreate-modules.sh** - Tests the modular postCreate structure:
  - Module existence and permissions
  - Syntax validation
  - Module count verification (7 active modules)
  - Documentation checks
  
- **test-postcreate-runtime.sh** - Tests postCreate execution in a container:
  - Runtime execution with timeout
  - NPM configuration verification
  - Workspace structure validation
  - Shell setup verification

- **test-mcp-config.sh** - Tests MCP configuration functionality:
  - Default .mcp.config JSON syntax
  - Setup module validation
  - JSON merge logic
  - Environment variable substitution
  - Dependency checks (jq, envsubst)

- **test-mcp-watcher.sh** - Tests file watcher functionality:
  - Inotify-tools installation
  - Watcher script validation
  - Control script commands
  - PID file management
  - Shell aliases configuration

### Integration Tests
- **test-mcp-integration.sh** - End-to-end MCP tests:
  - Full setup workflow simulation
  - Configuration merging verification
  - Watcher control functionality
  - Shell integration
  - Race condition prevention
  
- **test-container-issues.sh** - Tests for known container issues
- **test-vscode-integration.sh** - VS Code specific integration tests

## Running Tests

### Run All Tests
```bash
./scripts/test-all.sh
```

### Run Extended Tests (including runtime)
```bash
./scripts/test-all.sh --full
```

### Run Individual Test Suites
```bash
./scripts/tests/test-devcontainer.sh
./scripts/tests/test-postcreate-modules.sh
```

## CI/CD Integration

Tests are automatically run via GitHub Actions on:
- Push to main or feat/* branches
- Pull requests to main

See `.github/workflows/test-container.yml` for CI configuration.

## Test Requirements

- Docker installed and running
- Python 3 (for JSON validation)
- Bash 4+ (for test scripts)
- ~5 minutes for full test suite

## Adding New Tests

1. Create test script in this directory
2. Follow naming convention: `test-*.sh`
3. Use consistent color codes and output format
4. Add to `test-devcontainer.sh` or `test-all.sh` as appropriate
5. Update this README

## Exit Codes

- 0: All tests passed
- 1: One or more tests failed
- Other: Script-specific error occurred