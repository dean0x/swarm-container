#!/bin/bash
# Dynamic Node.js memory configuration based on container memory
# This script sets NODE_OPTIONS to use 75% of available container memory

# Get container memory limit in bytes
get_container_memory() {
    # Check if CONTAINER_MEMORY env var is set (e.g., "4gb", "2GB", "1024mb")
    if [ -n "$CONTAINER_MEMORY" ]; then
        # Convert to bytes
        local mem_value=$(echo "$CONTAINER_MEMORY" | sed 's/[^0-9]*//g')
        local mem_unit=$(echo "$CONTAINER_MEMORY" | sed 's/[0-9]*//g' | tr '[:lower:]' '[:upper:]')
        
        case "$mem_unit" in
            "GB"|"G")
                echo $((mem_value * 1024 * 1024 * 1024))
                return
                ;;
            "MB"|"M")
                echo $((mem_value * 1024 * 1024))
                return
                ;;
            "KB"|"K")
                echo $((mem_value * 1024))
                return
                ;;
        esac
    fi
    
    # Try to read from cgroup v2 first
    if [ -f /sys/fs/cgroup/memory.max ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
        if [ "$MEM_LIMIT" != "max" ] && [ -n "$MEM_LIMIT" ] && [ "$MEM_LIMIT" -gt 0 ]; then
            echo "$MEM_LIMIT"
            return
        fi
    fi
    
    # Try cgroup v1
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        MEM_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
        # Check if it's not the default unlimited value
        if [ "$MEM_LIMIT" -lt 9223372036854775807 ] && [ "$MEM_LIMIT" -gt 0 ] && [ -n "$MEM_LIMIT" ]; then
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

# Sanity check - if memory seems unreasonably high, default to 4GB
if [ $MEMORY_MB -gt 65536 ]; then  # More than 64GB seems wrong
    echo "⚠️  Detected unrealistic memory value (${MEMORY_MB}MB), defaulting to 4GB"
    MEMORY_MB=4096
fi

# Check if running multiple Claude Code instances
INSTANCES=${CLAUDE_CODE_INSTANCES:-6}

# Calculate heap percentage based on number of instances
if [ $INSTANCES -gt 1 ]; then
    # Dynamic heap percentage: 80 - instances, bounded between 40-75%
    HEAP_PERCENTAGE=$((80 - INSTANCES))
    if [ $HEAP_PERCENTAGE -gt 75 ]; then
        HEAP_PERCENTAGE=75
    elif [ $HEAP_PERCENTAGE -lt 40 ]; then
        HEAP_PERCENTAGE=40
    fi
    echo "🔢 Configuring for $INSTANCES Claude Code instances"
else
    # Default 75% for single instance
    HEAP_PERCENTAGE=75
fi

# Calculate heap size based on percentage
HEAP_MB=$((MEMORY_MB * HEAP_PERCENTAGE / 100))

# Ensure minimum heap size of 512MB
if [ $HEAP_MB -lt 512 ]; then
    HEAP_MB=512
fi

# Export NODE_OPTIONS
export NODE_OPTIONS="--max-old-space-size=$HEAP_MB"

echo "🧠 Container memory detected: ${MEMORY_MB}MB"
echo "📊 Node.js heap size set to: ${HEAP_MB}MB (${HEAP_PERCENTAGE}% of container memory)"
echo "🔧 NODE_OPTIONS=$NODE_OPTIONS"