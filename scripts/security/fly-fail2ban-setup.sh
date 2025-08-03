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