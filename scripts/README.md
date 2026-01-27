# DevContainer Scripts

This directory contains all scripts used by the SwarmContainer development environment, organized by function.

## Directory Structure

```
scripts/
├── security/          # Security-related scripts
│   ├── init-security.sh       # Container firewall initialization (runs as root)
│   ├── security-monitor.sh    # Runtime security monitoring tool
│   └── security-config.json   # Security preset configurations
│
├── hooks/            # Container lifecycle hooks
│   ├── docker-entrypoint.sh   # Container entrypoint (handles security + user switching)
│   └── postCreate.sh         # Post-creation setup (Claude Code, shell, etc.)
│
└── tests/            # Test scripts
    ├── test-devcontainer.sh     # Main test suite
    ├── test-container.sh        # Container build tests
    ├── test-container-issues.sh # Known issues test
    └── test-vscode-integration.sh # VS Code integration tests
```

## Script Descriptions

### Security Scripts (`security/`)

- **init-security.sh**: Initializes container-level firewall rules based on the selected security preset. Runs as root during container startup.
- **security-monitor.sh**: Monitors security status, checks for violations, and audits container configuration.
- **security-config.json**: Defines allowed/blocked domains for each security preset (paranoid, enterprise, development).

### Hook Scripts (`hooks/`)

- **docker-entrypoint.sh**: Container entrypoint that runs security initialization and starts the container (runs as root).
- **postCreate.sh**: Sets up the development environment after container creation (Claude Code, shell environment, etc.).

### Test Scripts (`tests/`)

- **test-devcontainer.sh**: Main test runner that validates the entire devcontainer setup.
- **test-container.sh**: Tests container building and basic functionality.
- **test-container-issues.sh**: Tests for known issues and edge cases.
- **test-vscode-integration.sh**: Tests VS Code specific integrations.

## Usage

### Running Tests
```bash
# From repository root
./.devcontainer/scripts/tests/test-devcontainer.sh
```

### Monitoring Security
```bash
# Inside container
bash .devcontainer/scripts/security/security-monitor.sh
```

### Manual Security Initialization
```bash
# Usually automatic, but can be run manually
sudo bash .devcontainer/scripts/security/init-security.sh
```

## Notes

- All scripts are copied into the container during build
- Security scripts run with elevated privileges
- Test scripts should be run before opening in VS Code
- Hook scripts are automatically executed by VS Code/Docker