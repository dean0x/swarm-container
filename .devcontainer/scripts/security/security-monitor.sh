#!/bin/bash

# Security monitoring script for Claude Flow container
# This script monitors for suspicious activities and can be run periodically

LOGFILE="/workspace/.devcontainer/security.log"
SECURITY_PRESET="${SECURITY_PRESET:-enterprise}"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Initialize log
echo "[$(date)] Security monitor started - Preset: $SECURITY_PRESET" >> "$LOGFILE"

# Function to check for suspicious processes
check_processes() {
    echo -e "${YELLOW}Checking for suspicious processes...${NC}"
    
    # Check for unexpected network listeners
    LISTENERS=$(netstat -tlpn 2>/dev/null | grep LISTEN | grep -v '127.0.0.1' | grep -v '::1')
    if [[ -n "$LISTENERS" ]]; then
        echo -e "${RED}⚠️  Warning: Unexpected network listeners detected:${NC}"
        echo "$LISTENERS"
        echo "[$(date)] WARNING: Unexpected listeners: $LISTENERS" >> "$LOGFILE"
    fi
    
    # Check for processes running as root (except expected ones)
    ROOT_PROCS=$(ps aux | grep -v '^root.*\(kernel\|systemd\|init\)' | grep '^root' | grep -v 'ps aux')
    if [[ -n "$ROOT_PROCS" ]]; then
        echo -e "${RED}⚠️  Warning: Unexpected root processes:${NC}"
        echo "$ROOT_PROCS"
        echo "[$(date)] WARNING: Root processes: $ROOT_PROCS" >> "$LOGFILE"
    fi
}

# Function to check file system changes
check_filesystem() {
    echo -e "${YELLOW}Checking filesystem integrity...${NC}"
    
    # Check for modifications to system files
    if [[ -f /usr/bin/node.backup ]]; then
        if ! diff -q /usr/bin/node /usr/bin/node.backup >/dev/null 2>&1; then
            echo -e "${RED}⚠️  Critical: Node binary has been modified!${NC}"
            echo "[$(date)] CRITICAL: Node binary modified" >> "$LOGFILE"
        fi
    fi
    
    # Check for unexpected SUID files
    SUID_FILES=$(find /workspace -perm -4000 -type f 2>/dev/null)
    if [[ -n "$SUID_FILES" ]]; then
        echo -e "${RED}⚠️  Warning: SUID files found in workspace:${NC}"
        echo "$SUID_FILES"
        echo "[$(date)] WARNING: SUID files: $SUID_FILES" >> "$LOGFILE"
    fi
}

# Function to check network connections
check_network() {
    echo -e "${YELLOW}Checking network connections...${NC}"
    
    # Check for connections to unexpected IPs
    CONNECTIONS=$(ss -tupn 2>/dev/null | grep ESTAB | grep -v '127.0.0.1' | grep -v '::1')
    
    if [[ "$SECURITY_PRESET" == "paranoid" ]]; then
        # In paranoid mode, log all external connections
        if [[ -n "$CONNECTIONS" ]]; then
            echo -e "${YELLOW}Active external connections:${NC}"
            echo "$CONNECTIONS"
            echo "[$(date)] INFO: Active connections: $CONNECTIONS" >> "$LOGFILE"
        fi
    fi
    
    # Check iptables dropped packets (if logging is enabled)
    DROPPED=$(dmesg | grep "BLOCKED-OUT:" | tail -10)
    if [[ -n "$DROPPED" ]]; then
        echo -e "${YELLOW}Recent blocked connection attempts:${NC}"
        echo "$DROPPED"
    fi
}

# Function to check Claude Code integrity
check_claude_integrity() {
    echo -e "${YELLOW}Checking Claude Code integrity...${NC}"
    
    # Verify Claude Code is from official source
    CLAUDE_VERSION=$(claude --version 2>/dev/null)
    if [[ -z "$CLAUDE_VERSION" ]]; then
        echo -e "${RED}⚠️  Warning: Claude Code not found or not working${NC}"
        echo "[$(date)] WARNING: Claude Code not functional" >> "$LOGFILE"
    else
        echo -e "${GREEN}✓ Claude Code: $CLAUDE_VERSION${NC}"
    fi
    
    # Check for modifications to claude-flow
    NPM_LIST=$(npm list -g claude-flow 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}⚠️  Warning: Claude Flow package may be corrupted${NC}"
        echo "[$(date)] WARNING: Claude Flow integrity check failed" >> "$LOGFILE"
    fi
}

# Main monitoring routine
echo -e "${GREEN}🔍 Starting security monitor...${NC}"
echo "Security Preset: $SECURITY_PRESET"
echo ""

check_processes
echo ""
check_filesystem
echo ""
check_network
echo ""
check_claude_integrity

echo ""
echo -e "${GREEN}✅ Security check complete${NC}"
echo "Log file: $LOGFILE"

# If in paranoid mode, return non-zero on any warnings
if [[ "$SECURITY_PRESET" == "paranoid" ]] && grep -q "WARNING\|CRITICAL" "$LOGFILE"; then
    echo -e "${RED}⚠️  Security issues detected in paranoid mode!${NC}"
    exit 1
fi