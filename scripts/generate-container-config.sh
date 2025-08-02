#!/bin/bash
# Generate container configuration based on Claude Code instances
# This script should be run before building the container

# Get instance count from environment or use default
INSTANCES=${CLAUDE_CODE_INSTANCES:-6}

# Source the calculation script to get recommendations
source "$(dirname "$0")/hooks/calculate-resources.sh" $INSTANCES >/dev/null 2>&1

# Export the calculated values
echo "# Auto-generated container configuration"
echo "# Generated for $INSTANCES Claude Code instances"
echo ""
echo "CONTAINER_MEMORY=$RECOMMENDED_MEMORY"
echo "CONTAINER_CPUS=$RECOMMENDED_CPUS"
echo "CLAUDE_CODE_INSTANCES=$INSTANCES"