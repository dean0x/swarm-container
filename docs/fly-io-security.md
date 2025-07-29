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