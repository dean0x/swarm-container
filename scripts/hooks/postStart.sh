#!/bin/bash
# Runs every time the container starts (via postStartCommand)
# This ensures initialization happens even when VS Code bypasses the entrypoint

set -e

# Source logging library if available
LOGGING_LIB="/scripts/lib/logging.sh"
if [ -f "$LOGGING_LIB" ]; then
    # shellcheck source=/dev/null
    source "$LOGGING_LIB"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
    log_security() { echo "[SECURITY] $1"; }
    write_security_state() { :; }
    print_security_warning_banner() { echo "WARNING: DEGRADED SECURITY MODE - $1"; }
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Running container start initialization (postStartCommand)...${NC}"

# Check if we're running as root
if [ "$(id -u)" != "0" ]; then
    log_error "postStart.sh must run as root"
    echo -e "${RED}Error: postStart.sh must run as root${NC}"
    exit 1
fi

# Source environment variables
SECURITY_PRESET="${SECURITY_PRESET:-development}"
echo -e "${BLUE}Security Level: ${SECURITY_PRESET}${NC}"

# Determine fail-secure default based on security preset
case "$SECURITY_PRESET" in
    paranoid|enterprise)
        SECURITY_FAIL_SECURE="${SECURITY_FAIL_SECURE:-true}"
        ;;
    *)
        SECURITY_FAIL_SECURE="${SECURITY_FAIL_SECURE:-false}"
        ;;
esac

log_info "Security configuration" "{\"preset\":\"$SECURITY_PRESET\",\"fail_secure\":\"$SECURITY_FAIL_SECURE\"}"

# Track security initialization state
SECURITY_INIT_SUCCESS=false
SECURITY_FAILURE_REASON=""

# 1. Run security initialization
if [ -f "/scripts/security/init-security.sh" ]; then
    echo -e "${BLUE}Applying security rules...${NC}"

    export SECURITY_PRESET="${SECURITY_PRESET}"
    export CUSTOM_ALLOWED_DOMAINS="${CUSTOM_ALLOWED_DOMAINS:-}"

    SECURITY_OUTPUT=$(bash /scripts/security/init-security.sh 2>&1)
    SECURITY_STATUS=$?

    echo "$SECURITY_OUTPUT"

    if [ $SECURITY_STATUS -eq 0 ]; then
        echo -e "${GREEN}Security rules applied successfully${NC}"
        log_security "Security initialization completed successfully" "{\"preset\":\"$SECURITY_PRESET\"}"
        SECURITY_INIT_SUCCESS=true
        write_security_state false "none"
    else
        SECURITY_FAILURE_REASON="Security script exited with code $SECURITY_STATUS"
        log_error "Security initialization failed" "{\"exit_code\":$SECURITY_STATUS,\"preset\":\"$SECURITY_PRESET\"}"

        if [ "$SECURITY_FAIL_SECURE" = "true" ]; then
            echo -e "${RED}FATAL: Security initialization failed (SECURITY_FAIL_SECURE=true)${NC}"
            log_security "Container startup blocked due to security failure" "{\"exit_code\":$SECURITY_STATUS,\"fail_secure\":true}"
            write_security_state true "init_failed_blocked" "{\"exit_code\":$SECURITY_STATUS}"
            exit 1
        else
            echo -e "${YELLOW}WARNING: Security initialization failed with code $SECURITY_STATUS${NC}"
            print_security_warning_banner "$SECURITY_FAILURE_REASON"
            write_security_state true "init_failed" "{\"exit_code\":$SECURITY_STATUS}"
        fi
    fi
else
    SECURITY_FAILURE_REASON="Security script not found at /scripts/security/init-security.sh"
    log_error "Security script not found" "{\"expected_path\":\"/scripts/security/init-security.sh\"}"

    if [ "$SECURITY_FAIL_SECURE" = "true" ]; then
        echo -e "${RED}FATAL: Security script not found (SECURITY_FAIL_SECURE=true)${NC}"
        log_security "Container startup blocked: security script missing" "{\"fail_secure\":true}"
        write_security_state true "script_missing_blocked"
        exit 1
    else
        echo -e "${RED}Security script not found!${NC}"
        echo -e "    Expected at: /scripts/security/init-security.sh"
        print_security_warning_banner "$SECURITY_FAILURE_REASON"
        write_security_state true "script_missing"
    fi
fi

# Create security log marker
{
    echo "$(date): Security initialized with preset: $SECURITY_PRESET"
    echo "Success: $SECURITY_INIT_SUCCESS"
    echo "Fail-secure: $SECURITY_FAIL_SECURE"
    echo "Source: postStartCommand"
    if [ -n "$SECURITY_FAILURE_REASON" ]; then
        echo "Failure reason: $SECURITY_FAILURE_REASON"
    fi
} > /var/log/container-security.log

# 2. Set up DNS refresh cron job for paranoid/enterprise modes
if [ "$SECURITY_PRESET" != "development" ] && [ "$SECURITY_INIT_SUCCESS" = "true" ]; then
    if [ -f "/scripts/security/refresh-dns-rules.sh" ]; then
        if command -v crontab &>/dev/null; then
            (crontab -l 2>/dev/null | grep -v "refresh-dns-rules.sh"; \
             echo "0 */4 * * * /scripts/security/refresh-dns-rules.sh >> /var/log/dns-refresh.log 2>&1") | crontab -
            log_info "DNS refresh cron job installed (every 4 hours)"
        else
            log_warn "crontab not available - DNS rules will not auto-refresh"
            echo -e "${YELLOW}Warning: crontab not available - DNS-based firewall rules will not auto-refresh${NC}"
        fi
    else
        log_warn "DNS refresh script not found"
    fi
fi

# 3. Set dynamic Node.js memory options based on container memory
if [ -f "/scripts/hooks/set-node-memory.sh" ]; then
    echo -e "${BLUE}Configuring Node.js memory settings...${NC}"
    # shellcheck source=/dev/null
    source /scripts/hooks/set-node-memory.sh
    MEMORY_STATUS=$?
    if [ $MEMORY_STATUS -ne 0 ]; then
        log_warn "Memory configuration returned non-zero status" "{\"exit_code\":$MEMORY_STATUS}"
    fi

    # Persist NODE_OPTIONS to shell profiles so new terminals inherit it
    # Use a marker to avoid duplicates on container restarts
    NODE_OPTIONS_LINE="export NODE_OPTIONS=\"$NODE_OPTIONS\""
    MARKER="# NODE_OPTIONS set by postStart.sh"

    for profile in /root/.bashrc /root/.zshrc; do
        if [ -f "$profile" ]; then
            # Remove old entries (if any) and add fresh one
            grep -v "NODE_OPTIONS set by postStart.sh" "$profile" | grep -v "^export NODE_OPTIONS=" > "${profile}.tmp" || true
            mv "${profile}.tmp" "$profile"
            echo "$MARKER" >> "$profile"
            echo "$NODE_OPTIONS_LINE" >> "$profile"
        fi
    done

    log_info "NODE_OPTIONS persisted to shell profiles"
else
    log_warn "Memory configuration script not found, using defaults"
    echo -e "${YELLOW}Memory configuration script not found, using defaults${NC}"
fi

echo -e "${GREEN}Container start initialization complete.${NC}"
