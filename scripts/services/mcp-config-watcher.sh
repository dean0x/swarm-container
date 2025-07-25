#!/bin/bash
# MCP Configuration File Watcher
# Watches for changes to .mcp.config and automatically updates Claude's configuration

set -e

# Configuration
CONFIG_FILE="/workspace/.devcontainer/config/.mcp.config"
UPDATE_SCRIPT="/workspace/.devcontainer/scripts/hooks/modules/setup-mcp.sh"
LOG_FILE="/tmp/mcp-watcher.log"
PID_FILE="/tmp/mcp-watcher.pid"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Debounce settings to avoid rapid updates
LAST_UPDATE=0
DEBOUNCE_SECONDS=2

# Write PID for service management
echo $$ > "$PID_FILE"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Cleanup on exit
cleanup() {
    log "MCP config watcher stopping..."
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

# Initial check
if [ ! -f "$CONFIG_FILE" ]; then
    log "WARNING: Config file not found: $CONFIG_FILE"
    log "Waiting for file to be created..."
fi

log "MCP config watcher started (PID: $$)"
log "Watching: $CONFIG_FILE"
log "Update script: $UPDATE_SCRIPT"

# Main watch loop
while true; do
    # Wait for file changes (create, modify, move)
    # Use -q for quiet mode, -e for events
    inotifywait -q -e modify,create,moved_to "$(dirname "$CONFIG_FILE")" 2>/dev/null | while read -r directory event filename; do
        # Check if the changed file is our config file
        if [ "$filename" = "$(basename "$CONFIG_FILE")" ]; then
            CURRENT_TIME=$(date +%s)
            TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))
            
            # Debounce rapid changes
            if [ $TIME_DIFF -ge $DEBOUNCE_SECONDS ]; then
                log "Config file changed (event: $event)"
                
                # Small delay to ensure file write is complete
                sleep 0.5
                
                # Validate JSON before updating
                if jq empty "$CONFIG_FILE" 2>/dev/null; then
                    log "Running MCP update script..."
                    
                    # Run the update script and capture output
                    if bash "$UPDATE_SCRIPT" >> "$LOG_FILE" 2>&1; then
                        log "✅ MCP configuration updated successfully"
                    else
                        log "❌ Failed to update MCP configuration (check log for details)"
                    fi
                else
                    log "❌ Invalid JSON in config file, skipping update"
                fi
                
                LAST_UPDATE=$CURRENT_TIME
            else
                log "Debounced rapid change (waiting $((DEBOUNCE_SECONDS - TIME_DIFF))s)"
            fi
        fi
    done
    
    # If inotifywait exits (shouldn't happen), wait and restart
    log "WARNING: inotifywait exited, restarting in 5 seconds..."
    sleep 5
done