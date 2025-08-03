# Task 013: Implement Security Hardening

## Objective
Add additional security measures to the Fly.io deployment beyond basic SSH configuration.

## Prerequisites
- [ ] Task 008 completed: Basic SSH working
- [ ] Understanding of container security best practices

## Workflow

### 1. Prerequisites Check
- SSH access working
- Basic security already in place (no root, no passwords)
- Fly.io deployment successful

### 2. Implementation

#### Step 2.1: Enhanced SSH Configuration
Update SSH configuration in Dockerfile `remote` stage:

```dockerfile
# Enhanced SSH security configuration
RUN echo "# Security hardening" >> /etc/ssh/sshd_config \
    && echo "Protocol 2" >> /etc/ssh/sshd_config \
    && echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config \
    && echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config \
    && echo "MaxAuthTries 3" >> /etc/ssh/sshd_config \
    && echo "MaxSessions 10" >> /etc/ssh/sshd_config \
    && echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config \
    && echo "X11Forwarding no" >> /etc/ssh/sshd_config \
    && echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config \
    && echo "PermitTunnel no" >> /etc/ssh/sshd_config \
    && echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config

# Create login banner
RUN echo "****************************************************" > /etc/ssh/banner \
    && echo "* SwarmContainer Development Environment           *" >> /etc/ssh/banner \
    && echo "* Authorized access only. All actions logged.     *" >> /etc/ssh/banner \
    && echo "****************************************************" >> /etc/ssh/banner
```

#### Step 2.2: Implement Fail2ban
Create `scripts/security/fly-fail2ban-setup.sh`:

```bash
#!/bin/bash
# Optional fail2ban setup for production use

cat << 'EOF' > /tmp/fail2ban-setup.sh
#!/bin/bash
set -euo pipefail

echo "🛡️ Setting up fail2ban..."

# Install fail2ban
sudo apt-get update
sudo apt-get install -y fail2ban

# Create SSH jail configuration
sudo tee /etc/fail2ban/jail.local << 'JAIL'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
JAIL

# Start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo "✅ Fail2ban configured"
echo "   - 3 failed attempts = 1 hour ban"
echo "   - Check status: sudo fail2ban-client status sshd"
EOF

echo "📋 Fail2ban setup script created"
echo "To install on your Fly.io container:"
echo "1. scp -P 10022 /tmp/fail2ban-setup.sh node@app.fly.dev:/tmp/"
echo "2. ssh -p 10022 node@app.fly.dev 'bash /tmp/fail2ban-setup.sh'"
```

#### Step 2.3: Create Security Audit Script
Create `scripts/fly-security-audit.sh`:

```bash
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
```

#### Step 2.4: Update fly-entrypoint.sh for Logging
Add security logging to `fly-entrypoint.sh`:

```bash
# Add after SSH key setup
# Security logging
echo "🔒 Setting up security logging..."

# Log SSH connections
echo "#!/bin/bash" > /tmp/ssh-login-notify.sh
echo 'echo "[$(date)] SSH Login: $USER from $SSH_CLIENT" >> /workspace/.ssh-access.log' >> /tmp/ssh-login-notify.sh
chmod +x /tmp/ssh-login-notify.sh

# Add to profile (works for both interactive and non-interactive)
echo "/tmp/ssh-login-notify.sh" >> ~/.profile

# Create log file with proper permissions
touch /workspace/.ssh-access.log
chmod 660 /workspace/.ssh-access.log

echo "✅ Security logging configured"
```

#### Step 2.5: Create Security Best Practices
Add to `docs/fly-io-security.md`:

```markdown
# Fly.io Security Best Practices

## Overview
SwarmContainer on Fly.io implements multiple security layers to protect your development environment.

## Built-in Security Features

### SSH Security
- ✅ Key-only authentication (no passwords)
- ✅ No root SSH access
- ✅ Non-standard port (10022)
- ✅ Limited user access (node user only)
- ✅ Connection timeouts configured

### Container Security
- ✅ Runs as non-root user
- ✅ Minimal attack surface
- ✅ Regular security updates
- ✅ Isolated environment

### Data Security
- ✅ Encrypted volumes at rest
- ✅ Encrypted secrets (API keys)
- ✅ Isolated network namespace

## Additional Hardening Options

### 1. Enable Fail2ban (Recommended for Production)
```bash
# Run on your container
./scripts/security/fly-fail2ban-setup.sh
```

### 2. Restrict SSH Access by IP
```toml
# In fly.toml - restrict to specific IPs
[[services.ports]]
  handlers = ["tls"]
  port = 10022
  # Add IP filtering at Fly.io edge
```

### 3. Regular Security Audits
```bash
./scripts/fly-security-audit.sh your-app-name
```

### 4. SSH Key Rotation
Rotate your SSH keys monthly:
```bash
# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/fly_new_key

# Update in Fly.io
./scripts/fly-ssh-setup.sh
```

### 5. Monitor Access
Check access logs regularly:
```bash
# View SSH access log
ssh -p 10022 node@app.fly.dev "cat /workspace/.ssh-access.log"

# View Fly.io logs
fly logs -a your-app-name | grep SSH
```

## Security Checklist

### Initial Setup
- [ ] Strong SSH key passphrase
- [ ] Unique app name (avoid predictable names)
- [ ] Appropriate region selection
- [ ] Review fly.toml for sensitive data

### Ongoing Maintenance
- [ ] Weekly security audits
- [ ] Monthly key rotation
- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Review Fly.io billing for anomalies

### Incident Response
1. **Suspected Compromise**:
   ```bash
   # Immediately revoke access
   fly secrets unset SSH_AUTHORIZED_KEYS -a app-name
   
   # Stop the machine
   fly machine stop -a app-name
   ```

2. **Investigation**:
   - Check access logs
   - Review Fly.io audit logs
   - Look for unauthorized changes

3. **Recovery**:
   - Destroy and recreate if needed
   - Restore from backups
   - Update SSH keys
   - Review security practices

## Network Security

### Default Configuration
- Only SSH port exposed (10022)
- All other ports blocked
- Outbound connections follow security preset

### Custom Firewall Rules
For additional restrictions, modify security preset in fly.toml:
```toml
[env]
  SECURITY_PRESET = "paranoid"  # Maximum restrictions
```

## Compliance Considerations

### Data Residency
- Choose appropriate region for compliance
- Understand Fly.io's data policies
- Consider encryption for sensitive code

### Access Control
- Limit who has SSH keys
- Use separate apps for different projects
- Audit access regularly

### Audit Trail
- All SSH connections logged
- Fly.io provides infrastructure logs
- Consider additional logging solutions

## Security Tools Integration

### Secret Scanning
Before deployment:
```bash
# Check for secrets
git secrets --scan
# or
trufflehog filesystem .
```

### Vulnerability Scanning
Regular scans:
```bash
# In container
npm audit
# or
yarn audit
```

## Remember
- Security is a shared responsibility
- Keep your local machine secure too
- Report security issues responsibly
- Stay updated on security best practices
```

### 3. Testing

#### Test 3.1: Security Audit
```bash
chmod +x scripts/fly-security-audit.sh
./scripts/fly-security-audit.sh
```

#### Test 3.2: Verify Hardening
- Check SSH banner appears
- Verify connection limits work
- Test login logging

### 4. Documentation
- Add security section to main guide
- Link from troubleshooting
- Emphasize optional nature of hardening

### 5. Completion Criteria
- [ ] Enhanced SSH configuration implemented
- [ ] Security audit script working
- [ ] Fail2ban setup documented
- [ ] Access logging implemented
- [ ] Best practices documented
- [ ] All scripts tested

## Security Layers

### Default Security
1. Key-only SSH authentication
2. Non-root user
3. Non-standard port
4. No password authentication

### Enhanced Security (This Task)
1. Connection limits
2. Login banner
3. Access logging
4. Security audit capability
5. Fail2ban option

### User Responsibility
1. Strong SSH keys
2. Regular updates
3. Access monitoring
4. Key rotation

## Balance
- Don't overwhelm users
- Make security easy
- Provide options
- Document clearly