#!/bin/bash
# Container health check script

# Check if critical processes are running
check_process() {
    if pgrep -f "$1" > /dev/null; then
        return 0
    else
        echo "WARNING: $1 is not running"
        return 1
    fi
}

# Check memory usage
check_memory() {
    local mem_percent=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$mem_percent" -gt 90 ]; then
        echo "WARNING: Memory usage is at ${mem_percent}%"
        return 1
    fi
    return 0
}

# Check Node.js memory
check_node_memory() {
    local node_pids=$(pgrep -f node)
    for pid in $node_pids; do
        if [ -n "$pid" ]; then
            local rss=$(ps -o rss= -p $pid 2>/dev/null | awk '{print int($1/1024)}')
            if [ $? -eq 0 ] && [ -n "$rss" ] && [ "$rss" -gt 3500 ]; then
                echo "WARNING: Node process $pid using ${rss}MB (limit is 4096MB)"
            fi
        fi
    done
}

# Main health check
echo "🏥 Container Health Check"
echo "========================"

# Check system resources
echo "📊 System Resources:"
free -h | grep -E "Mem:|Swap:"
echo ""

# Check processes
echo "🔄 Process Status:"
check_memory
check_node_memory

# Check disk space
echo ""
echo "💾 Disk Usage:"
df -h /workspace | tail -1

# Overall status
echo ""
echo "✅ Health check complete"
