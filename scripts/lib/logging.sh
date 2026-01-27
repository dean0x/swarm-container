#!/bin/bash
# Structured logging library for SwarmContainer
# Provides JSON-formatted logging with consistent structure

# Ensure log directories exist
mkdir -p /var/log 2>/dev/null || true

# Log JSON-formatted message
# Usage: log_json "LEVEL" "message" '{"key": "value"}'
log_json() {
    local level="$1"
    local message="$2"
    local context="${3:-{}}"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S%z")

    # Escape message for JSON (handle quotes and newlines)
    local escaped_message
    escaped_message=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')

    printf '{"timestamp":"%s","level":"%s","message":"%s","context":%s}\n' \
        "$timestamp" "$level" "$escaped_message" "$context"
}

# Convenience functions
log_info() {
    local message="$1"
    local context="${2:-{}}"
    log_json "INFO" "$message" "$context"
}

log_warn() {
    local message="$1"
    local context="${2:-{}}"
    log_json "WARN" "$message" "$context"
}

log_error() {
    local message="$1"
    local context="${2:-{}}"
    log_json "ERROR" "$message" "$context" >&2
}

log_debug() {
    local message="$1"
    local context="${2:-{}}"
    if [ "${DEBUG:-false}" = "true" ]; then
        log_json "DEBUG" "$message" "$context"
    fi
}

# Security-specific logging (writes to both stdout and security log file)
log_security() {
    local message="$1"
    local context="${2:-{}}"
    local log_entry
    log_entry=$(log_json "SECURITY" "$message" "$context")

    echo "$log_entry"

    # Also append to security log file if writable
    local security_log="/var/log/security.json"
    if [ -w "$(dirname "$security_log")" ] || [ -w "$security_log" ]; then
        echo "$log_entry" >> "$security_log"
    fi
}

# Write security state to JSON file for consumption by other tools
# Usage: write_security_state true "reason" '{"extra": "data"}'
write_security_state() {
    local degraded="$1"
    local reason="${2:-unknown}"
    local extra="${3:-{}}"
    local state_file="/var/log/security-state.json"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S%z")

    # Merge extra context with base state
    local state
    if command -v jq &>/dev/null; then
        state=$(jq -n \
            --argjson degraded "$degraded" \
            --arg reason "$reason" \
            --arg timestamp "$timestamp" \
            --argjson extra "$extra" \
            '{security_degraded: $degraded, reason: $reason, timestamp: $timestamp} + $extra')
    else
        state="{\"security_degraded\":$degraded,\"reason\":\"$reason\",\"timestamp\":\"$timestamp\"}"
    fi

    echo "$state" > "$state_file" 2>/dev/null || {
        log_warn "Could not write security state file" '{"path":"'"$state_file"'"}'
    }
}

# Print a warning banner for degraded security mode
print_security_warning_banner() {
    local reason="${1:-Unknown}"
    echo ""
    echo "=============================================="
    echo "  WARNING: DEGRADED SECURITY MODE"
    echo "=============================================="
    echo "  Reason: $reason"
    echo ""
    echo "  Security controls may not be fully active."
    echo "  Check /var/log/security-state.json for details."
    echo "=============================================="
    echo ""
}
