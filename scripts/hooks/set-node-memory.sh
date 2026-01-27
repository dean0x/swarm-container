#!/bin/bash
# Dynamic Node.js memory configuration based on container memory
# This script sets NODE_OPTIONS to use a percentage of available container memory

# Source logging library if available
LOGGING_LIB="/scripts/lib/logging.sh"
if [ -f "$LOGGING_LIB" ]; then
    # shellcheck source=/dev/null
    source "$LOGGING_LIB"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
fi

# Safe default memory in MB when detection fails
SAFE_DEFAULT_MEMORY_MB=4096

# Parse memory value from string like "4.5gb", "512mb", "8G"
# Returns value in bytes
parse_memory_string() {
    local input="$1"
    local result=0

    # Convert to lowercase for easier matching
    local lower_input
    lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # Extract numeric part (including decimals)
    local numeric_part
    numeric_part=$(echo "$lower_input" | grep -oE '[0-9]+\.?[0-9]*')

    # Extract unit part
    local unit_part
    unit_part=$(echo "$lower_input" | grep -oE '[a-z]+$')

    if [[ -z "$numeric_part" ]]; then
        echo "0"
        return 1
    fi

    # Use awk for floating point arithmetic (bc may not be available)
    case "$unit_part" in
        "gb"|"g")
            result=$(awk "BEGIN {printf \"%.0f\", $numeric_part * 1024 * 1024 * 1024}")
            ;;
        "mb"|"m")
            result=$(awk "BEGIN {printf \"%.0f\", $numeric_part * 1024 * 1024}")
            ;;
        "kb"|"k")
            result=$(awk "BEGIN {printf \"%.0f\", $numeric_part * 1024}")
            ;;
        "b"|"")
            result=$(awk "BEGIN {printf \"%.0f\", $numeric_part}")
            ;;
        *)
            log_warn "Unknown memory unit: $unit_part, treating as bytes"
            result=$(awk "BEGIN {printf \"%.0f\", $numeric_part}")
            ;;
    esac

    echo "$result"
}

# Get container memory limit in bytes
get_container_memory() {
    # Check if CONTAINER_MEMORY env var is set (e.g., "4.5gb", "2GB", "1024mb")
    if [ -n "$CONTAINER_MEMORY" ]; then
        local parsed_bytes
        parsed_bytes=$(parse_memory_string "$CONTAINER_MEMORY")
        if [ "$parsed_bytes" -gt 0 ] 2>/dev/null; then
            log_info "Using CONTAINER_MEMORY env var" "{\"value\":\"$CONTAINER_MEMORY\",\"bytes\":$parsed_bytes}"
            echo "$parsed_bytes"
            return 0
        else
            log_warn "Failed to parse CONTAINER_MEMORY: $CONTAINER_MEMORY"
        fi
    fi

    # Try to read from cgroup v2 first
    if [ -f /sys/fs/cgroup/memory.max ]; then
        local mem_limit
        mem_limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
        if [ "$mem_limit" != "max" ] && [ -n "$mem_limit" ] && [ "$mem_limit" -gt 0 ] 2>/dev/null; then
            log_info "Detected cgroup v2 memory limit" "{\"bytes\":$mem_limit}"
            echo "$mem_limit"
            return 0
        fi
    fi

    # Try cgroup v1
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        local mem_limit
        mem_limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
        # Check if it's not the default unlimited value (close to max int64)
        # 9223372036854771712 is a common "unlimited" value
        if [ -n "$mem_limit" ] && [ "$mem_limit" -lt 9000000000000000000 ] && [ "$mem_limit" -gt 0 ] 2>/dev/null; then
            log_info "Detected cgroup v1 memory limit" "{\"bytes\":$mem_limit}"
            echo "$mem_limit"
            return 0
        fi
    fi

    # IMPORTANT: Do NOT fall back to system memory - that's dangerous in a container context
    # If we can't detect container memory, use a safe conservative default
    log_warn "Could not detect container memory limit, using safe default (${SAFE_DEFAULT_MEMORY_MB}MB)"
    echo $((SAFE_DEFAULT_MEMORY_MB * 1024 * 1024))
    return 1
}

# Convert bytes to megabytes
bytes_to_mb() {
    local bytes="$1"
    awk "BEGIN {printf \"%.0f\", $bytes / 1024 / 1024}"
}

# Main logic
MEMORY_BYTES=$(get_container_memory)
MEMORY_MB=$(bytes_to_mb "$MEMORY_BYTES")

# Validate memory is reasonable (minimum 512MB, no arbitrary maximum)
if [ "$MEMORY_MB" -lt 512 ]; then
    log_warn "Detected memory ($MEMORY_MB MB) is below minimum, using 512MB"
    MEMORY_MB=512
fi

# Note: Removed arbitrary 64GB cap - containers can legitimately have very large memory
# If someone configures a 128GB container, we should respect that

# Check if running multiple Claude Code instances
INSTANCES=${CLAUDE_CODE_INSTANCES:-6}

# Calculate heap percentage based on number of instances
# Formula: 80 - instances, bounded between 40-75%
if [ "$INSTANCES" -gt 1 ]; then
    HEAP_PERCENTAGE=$((80 - INSTANCES))
    if [ "$HEAP_PERCENTAGE" -gt 75 ]; then
        HEAP_PERCENTAGE=75
    elif [ "$HEAP_PERCENTAGE" -lt 40 ]; then
        HEAP_PERCENTAGE=40
    fi
    echo "Configuring for $INSTANCES Claude Code instances"
else
    # Default 75% for single instance
    HEAP_PERCENTAGE=75
fi

# Calculate heap size based on percentage
HEAP_MB=$((MEMORY_MB * HEAP_PERCENTAGE / 100))

# Ensure minimum heap size of 512MB
if [ "$HEAP_MB" -lt 512 ]; then
    HEAP_MB=512
    log_warn "Calculated heap ($HEAP_MB MB) below minimum, using 512MB"
fi

# Export NODE_OPTIONS
export NODE_OPTIONS="--max-old-space-size=$HEAP_MB"

log_info "Memory configuration complete" "{\"container_mb\":$MEMORY_MB,\"heap_mb\":$HEAP_MB,\"heap_percent\":$HEAP_PERCENTAGE,\"instances\":$INSTANCES}"
echo "Container memory detected: ${MEMORY_MB}MB"
echo "Node.js heap size set to: ${HEAP_MB}MB (${HEAP_PERCENTAGE}% of container memory)"
echo "NODE_OPTIONS=$NODE_OPTIONS"
