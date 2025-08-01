#!/bin/bash
set -euo pipefail

echo "🔒 SwarmContainer Security Audit"
echo "==============================="
echo ""

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

SSH_CMD="ssh -p 10022 node@${APP_NAME}.fly.dev"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🎯 Auditing: $APP_NAME"
echo ""

# Test 1: SSH Configuration
echo "1. SSH Security Configuration:"
SSHD_CONFIG=$($SSH_CMD "grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|Protocol)' /etc/ssh/sshd_config" 2>/dev/null || echo "Failed")
echo "$SSHD_CONFIG"

if echo "$SSHD_CONFIG" | grep -q "PermitRootLogin no" && \
   echo "$SSHD_CONFIG" | grep -q "PasswordAuthentication no"; then
    echo -e "${GREEN}✅ SSH properly secured${NC}"
else
    echo -e "${RED}❌ SSH configuration issues${NC}"
fi

# Test 2: User Permissions
echo ""
echo "2. User Security:"
USER_INFO=$($SSH_CMD "id; groups" 2>/dev/null)
echo "$USER_INFO"

if echo "$USER_INFO" | grep -q "uid=1000(node)"; then
    echo -e "${GREEN}✅ Running as non-root user${NC}"
else
    echo -e "${RED}❌ User permission issues${NC}"
fi

# Test 3: Sudo Configuration
echo ""
echo "3. Sudo Access:"
SUDO_CHECK=$($SSH_CMD "sudo -n echo 'Sudo works' 2>&1" || echo "No sudo")
if echo "$SUDO_CHECK" | grep -q "Sudo works"; then
    echo -e "${YELLOW}⚠️  Passwordless sudo enabled${NC}"
    echo "   This is needed for development but increases risk"
else
    echo -e "${GREEN}✅ No passwordless sudo${NC}"
fi

# Test 4: Open Ports
echo ""
echo "4. Network Security:"
PORTS=$($SSH_CMD "sudo ss -tlnp 2>/dev/null | grep LISTEN" || echo "Cannot check")
echo "$PORTS"

OPEN_PORTS=$(echo "$PORTS" | grep -v "127.0.0.1" | grep -v "::1" | wc -l)
if [ "$OPEN_PORTS" -le 2 ]; then
    echo -e "${GREEN}✅ Minimal ports exposed${NC}"
else
    echo -e "${YELLOW}⚠️  Multiple ports open${NC}"
fi

# Test 5: File Permissions
echo ""
echo "5. Sensitive File Permissions:"
SSH_DIR=$($SSH_CMD "ls -la ~/.ssh/" 2>/dev/null | grep -E "authorized_keys|id_" || echo "None")
echo "$SSH_DIR"

if echo "$SSH_DIR" | grep -q -- "-rw-------"; then
    echo -e "${GREEN}✅ SSH files properly protected${NC}"
else
    echo -e "${RED}❌ SSH file permission issues${NC}"
fi

# Test 6: Security Updates
echo ""
echo "6. Security Updates:"
UPDATES=$($SSH_CMD "sudo apt list --upgradable 2>/dev/null | grep -i security | wc -l" || echo "0")
if [ "$UPDATES" -eq 0 ]; then
    echo -e "${GREEN}✅ No security updates pending${NC}"
else
    echo -e "${YELLOW}⚠️  $UPDATES security updates available${NC}"
fi

# Test 7: Firewall Status
echo ""
echo "7. Container Firewall:"
FW_STATUS=$($SSH_CMD "sudo iptables -L -n 2>/dev/null | head -5" || echo "No firewall")
if echo "$FW_STATUS" | grep -q "Chain"; then
    echo -e "${GREEN}✅ Firewall rules present${NC}"
else
    echo -e "${YELLOW}⚠️  No firewall configured${NC}"
fi

echo ""
echo "=============================="
echo "Security Audit Complete"
echo ""
echo "Recommendations:"
echo "• Keep SSH keys secure and rotate regularly"
echo "• Monitor access logs: fly logs -a $APP_NAME"
echo "• Apply security updates regularly"
echo "• Consider fail2ban for production use"