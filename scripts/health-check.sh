#!/bin/bash
# Docker health check script for SwarmContainer
# Returns 0 (healthy) if all critical services are functioning
# Returns 1 (unhealthy) if any critical check fails

# Health check result tracking
HEALTH_STATUS=0
HEALTH_DETAILS=()

# Check 1: Node.js is available
check_node() {
    if command -v node &>/dev/null; then
        local node_version
        node_version=$(node --version 2>/dev/null)
        if [[ -n "$node_version" ]]; then
            HEALTH_DETAILS+=("node: OK ($node_version)")
            return 0
        fi
    fi
    HEALTH_DETAILS+=("node: FAIL")
    return 1
}

# Check 2: Claude Code is installed
check_claude_code() {
    if command -v claude &>/dev/null; then
        HEALTH_DETAILS+=("claude-code: OK")
        return 0
    fi
    # Also check in npm global bin
    if [[ -f "$HOME/.npm-global/bin/claude" ]]; then
        HEALTH_DETAILS+=("claude-code: OK (npm-global)")
        return 0
    fi
    HEALTH_DETAILS+=("claude-code: FAIL (not found)")
    return 1
}

# Check 3: Security state is not degraded (for paranoid/enterprise modes)
check_security_state() {
    local security_preset="${SECURITY_PRESET:-development}"
    local state_file="/var/log/security-state.json"

    # Development mode doesn't require strict security
    if [[ "$security_preset" == "development" ]]; then
        HEALTH_DETAILS+=("security: OK (development mode)")
        return 0
    fi

    # Check if security state file exists and indicates healthy state
    if [[ -f "$state_file" ]]; then
        local degraded
        degraded=$(jq -r '.security_degraded // false' "$state_file" 2>/dev/null)
        if [[ "$degraded" == "true" ]]; then
            local reason
            reason=$(jq -r '.reason // "unknown"' "$state_file" 2>/dev/null)
            HEALTH_DETAILS+=("security: DEGRADED ($reason)")
            return 1
        else
            HEALTH_DETAILS+=("security: OK")
            return 0
        fi
    else
        # No state file could mean security wasn't initialized
        HEALTH_DETAILS+=("security: UNKNOWN (no state file)")
        return 1
    fi
}

# Check 4: Memory is properly configured
check_memory() {
    if [[ -n "$NODE_OPTIONS" ]]; then
        HEALTH_DETAILS+=("memory: OK ($NODE_OPTIONS)")
        return 0
    else
        HEALTH_DETAILS+=("memory: WARN (NODE_OPTIONS not set)")
        # Not critical, just a warning
        return 0
    fi
}

# Check 5: Workspace is accessible
check_workspace() {
    if [[ -d "/workspace" ]] && [[ -r "/workspace" ]]; then
        HEALTH_DETAILS+=("workspace: OK")
        return 0
    else
        HEALTH_DETAILS+=("workspace: FAIL (not accessible)")
        return 1
    fi
}

# Check 6: Memory usage is not critical
check_memory_usage() {
    local mem_percent
    mem_percent=$(free 2>/dev/null | grep Mem | awk '{print int($3/$2 * 100)}')

    if [[ -z "$mem_percent" ]]; then
        HEALTH_DETAILS+=("memory-usage: UNKNOWN")
        return 0
    fi

    if [[ "$mem_percent" -gt 95 ]]; then
        HEALTH_DETAILS+=("memory-usage: CRITICAL (${mem_percent}%)")
        return 1
    elif [[ "$mem_percent" -gt 85 ]]; then
        HEALTH_DETAILS+=("memory-usage: WARN (${mem_percent}%)")
        return 0
    else
        HEALTH_DETAILS+=("memory-usage: OK (${mem_percent}%)")
        return 0
    fi
}

# Run all health checks
run_health_checks() {
    check_node || HEALTH_STATUS=1
    check_claude_code || HEALTH_STATUS=1
    check_security_state || HEALTH_STATUS=1
    check_memory || true  # Non-critical
    check_workspace || HEALTH_STATUS=1
    check_memory_usage || HEALTH_STATUS=1
}

# Main
run_health_checks

# Output health details (useful for debugging)
# Docker health checks should be quiet by default
if [[ "${HEALTH_CHECK_VERBOSE:-false}" == "true" ]] || [[ "$1" == "-v" ]]; then
    echo "Health Check Results:"
    for detail in "${HEALTH_DETAILS[@]}"; do
        echo "  - $detail"
    done
    echo ""
    if [[ $HEALTH_STATUS -eq 0 ]]; then
        echo "Status: HEALTHY"
    else
        echo "Status: UNHEALTHY"
    fi
fi

# Exit with appropriate status
exit $HEALTH_STATUS
