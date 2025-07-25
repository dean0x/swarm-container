#!/bin/bash
# MCP Watcher Control Script
# Provides start/stop/status commands for the MCP config watcher

WATCHER_SCRIPT="/workspace/.devcontainer/scripts/services/mcp-config-watcher.sh"
PID_FILE="/tmp/mcp-watcher.pid"
LOG_FILE="/tmp/mcp-watcher.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if watcher is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Start the watcher
start_watcher() {
    if is_running; then
        echo -e "${YELLOW}MCP config watcher is already running (PID: $(cat "$PID_FILE"))${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Starting MCP config watcher...${NC}"
    nohup bash "$WATCHER_SCRIPT" > "$LOG_FILE" 2>&1 &
    
    # Wait a moment for PID file to be created
    sleep 1
    
    if is_running; then
        echo -e "${GREEN}✅ MCP config watcher started (PID: $(cat "$PID_FILE"))${NC}"
        echo -e "   Log file: $LOG_FILE"
        return 0
    else
        echo -e "${RED}❌ Failed to start MCP config watcher${NC}"
        return 1
    fi
}

# Stop the watcher
stop_watcher() {
    if ! is_running; then
        echo -e "${YELLOW}MCP config watcher is not running${NC}"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    echo -e "${YELLOW}Stopping MCP config watcher (PID: $PID)...${NC}"
    
    kill "$PID" 2>/dev/null
    
    # Wait for process to stop
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 0.5
    done
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        kill -9 "$PID" 2>/dev/null
    fi
    
    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ MCP config watcher stopped${NC}"
    return 0
}

# Show status
show_status() {
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}● MCP config watcher is running${NC}"
        echo -e "   PID: $PID"
        echo -e "   Log: $LOG_FILE"
        
        # Show last few log entries
        if [ -f "$LOG_FILE" ]; then
            echo -e "\n📋 Recent activity:"
            tail -n 5 "$LOG_FILE" | sed 's/^/   /'
        fi
    else
        echo -e "${RED}○ MCP config watcher is not running${NC}"
        
        # Show last error if log exists
        if [ -f "$LOG_FILE" ] && grep -q "ERROR\|Failed" "$LOG_FILE"; then
            echo -e "\n❌ Last error:"
            grep -E "ERROR|Failed" "$LOG_FILE" | tail -n 1 | sed 's/^/   /'
        fi
    fi
}

# Show logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        less +F "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found${NC}"
    fi
}

# Main command handling
case "$1" in
    start)
        start_watcher
        ;;
    stop)
        stop_watcher
        ;;
    restart)
        stop_watcher
        sleep 1
        start_watcher
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the MCP config watcher"
        echo "  stop     - Stop the MCP config watcher"
        echo "  restart  - Restart the MCP config watcher"
        echo "  status   - Show watcher status and recent activity"
        echo "  logs     - Show full logs (press 'q' to exit)"
        exit 1
        ;;
esac