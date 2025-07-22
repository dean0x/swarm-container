#!/bin/bash
# Dynamic Node.js memory configuration based on container memory
# This script sets NODE_OPTIONS to use 75% of available container memory

# Get container memory limit in bytes
get_container_memory() {
    # Try to read from cgroup v2 first
    if [ -f /sys/fs/cgroup/memory.max ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
        if [ "$MEM_LIMIT" != "max" ] && [ -n "$MEM_LIMIT" ]; then
            echo "$MEM_LIMIT"
            return
        fi
    fi
    
    # Try cgroup v1
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
        # Check if it's not the default unlimited value
        if [ "$MEM_LIMIT" -lt 9223372036854775807 ] && [ -n "$MEM_LIMIT" ]; then
            echo "$MEM_LIMIT"
            return
        fi
    fi
    
    # Fallback to total system memory
    echo $(free -b | awk '/^Mem:/{print $2}')
}

# Convert bytes to megabytes
bytes_to_mb() {
    echo $(($1 / 1024 / 1024))
}

# Main logic
MEMORY_BYTES=$(get_container_memory)
MEMORY_MB=$(bytes_to_mb $MEMORY_BYTES)

# Calculate 75% for heap (leaving 25% for system, buffers, etc.)
HEAP_MB=$((MEMORY_MB * 75 / 100))

# Ensure minimum heap size of 512MB
if [ $HEAP_MB -lt 512 ]; then
    HEAP_MB=512
fi

# Export NODE_OPTIONS
export NODE_OPTIONS="--max-old-space-size=$HEAP_MB"

echo "🧠 Container memory detected: ${MEMORY_MB}MB"
echo "📊 Node.js heap size set to: ${HEAP_MB}MB (75% of container memory)"
echo "🔧 NODE_OPTIONS=$NODE_OPTIONS"