# Container Services

This directory contains background services that can run in the container.

## MCP Config Watcher

Monitors changes to `.mcp.config` and automatically updates Claude's configuration.

### Files

- `mcp-config-watcher.sh` - The main watcher service
- `mcp-watcher-control.sh` - Control script for start/stop/status

### Features

- **Automatic Updates**: Detects changes to `.mcp.config` and applies them
- **Debouncing**: Waits 2 seconds to avoid rapid updates during editing
- **JSON Validation**: Checks syntax before applying changes
- **Logging**: All activity logged to `/tmp/mcp-watcher.log`
- **PID Management**: Proper process tracking via PID file

### Usage

Enable at container startup:
```bash
export ENABLE_MCP_WATCHER=true
```

Or control manually:
```bash
mcp-watcher-start    # Start the watcher
mcp-watcher-status   # Check if running
mcp-watcher-stop     # Stop the watcher
mcp-watcher-logs     # View logs
```

### Implementation Details

- Uses `inotifywait` from inotify-tools (Linux kernel feature)
- Monitors file events: modify, create, moved_to
- Validates JSON with `jq` before applying
- Runs with minimal overhead
- Graceful shutdown with signal handling

### Troubleshooting

If the watcher isn't working:

1. Check if it's running: `mcp-watcher-status`
2. View logs: `mcp-watcher-logs`
3. Verify inotify-tools is installed: `which inotifywait`
4. Check file permissions on `.mcp.config`
5. Validate JSON syntax: `jq . < /workspace/.devcontainer/config/.mcp.config`