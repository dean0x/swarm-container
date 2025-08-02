#!/bin/bash
# Calculate optimal container resources based on number of Claude Code instances

# Default to 6 instances if not specified
INSTANCES=${1:-${CLAUDE_CODE_INSTANCES:-6}}

# Resource calculation constants
PER_INSTANCE_MB=600      # Average memory per Claude Code instance
SYSTEM_OVERHEAD_MB=2048  # Base system overhead (2GB)
MB_PER_GB=1024

# Calculate memory
TOTAL_MEMORY_MB=$((INSTANCES * PER_INSTANCE_MB + SYSTEM_OVERHEAD_MB))
TOTAL_MEMORY_GB=$((TOTAL_MEMORY_MB / MB_PER_GB))

# Ensure minimum memory
if [ $TOTAL_MEMORY_GB -lt 3 ]; then
    TOTAL_MEMORY_GB=3
fi

# Calculate CPUs (1 CPU per 3 instances, minimum 2)
RECOMMENDED_CPUS=$((INSTANCES / 3))
if [ $RECOMMENDED_CPUS -lt 2 ]; then
    RECOMMENDED_CPUS=2
fi
# Cap at reasonable maximum
if [ $RECOMMENDED_CPUS -gt 32 ]; then
    RECOMMENDED_CPUS=32
fi

# Calculate heap percentage (decreases as instances increase)
# Formula: 80 - instances, bounded between 40-75%
HEAP_PERCENTAGE=$((80 - INSTANCES))
if [ $HEAP_PERCENTAGE -gt 75 ]; then
    HEAP_PERCENTAGE=75
elif [ $HEAP_PERCENTAGE -lt 40 ]; then
    HEAP_PERCENTAGE=40
fi

# Output recommendations
echo "🧮 Resource Recommendations for $INSTANCES Claude Code instance(s):"
echo ""
echo "📊 Memory: ${TOTAL_MEMORY_GB}g (${TOTAL_MEMORY_MB}MB)"
echo "🖥️  CPUs: $RECOMMENDED_CPUS"
echo "🧠 Heap: ${HEAP_PERCENTAGE}% of container memory"
echo ""

# Show configuration
echo "📝 Recommended .env configuration:"
echo "CLAUDE_CODE_INSTANCES=$INSTANCES"
echo "CONTAINER_MEMORY=${TOTAL_MEMORY_GB}g"
echo "CONTAINER_CPUS=$RECOMMENDED_CPUS"
echo ""

# Warnings for extreme configurations
if [ $INSTANCES -gt 50 ]; then
    echo "⚠️  WARNING: Running $INSTANCES instances requires significant resources!"
    echo "   Consider using a process manager like PM2 for better control."
elif [ $INSTANCES -gt 20 ]; then
    echo "💡 TIP: For $INSTANCES instances, consider using tmux or screen"
    echo "   to organize your sessions effectively."
fi

# Export for use in other scripts
export RECOMMENDED_MEMORY="${TOTAL_MEMORY_GB}g"
export RECOMMENDED_CPUS="$RECOMMENDED_CPUS"
export RECOMMENDED_HEAP_PERCENTAGE="$HEAP_PERCENTAGE"