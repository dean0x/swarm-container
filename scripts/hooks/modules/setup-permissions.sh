#!/bin/bash
# Module: Permissions Setup
# Purpose: Set proper permissions for scripts and directories

echo "🔒 Setting up permissions..."

# Make security scripts executable
chmod +x /devcontainer-config/scripts/security/init-security.sh 2>/dev/null || true
chmod +x /devcontainer-config/scripts/security/security-monitor.sh 2>/dev/null || true

# Make all module scripts executable
if [ -d "/devcontainer-config/scripts/hooks/modules" ]; then
    chmod +x /devcontainer-config/scripts/hooks/modules/*.sh 2>/dev/null || true
fi

# Ensure workspace permissions are correct
chown -R node:node /workspace 2>/dev/null || true

echo "✅ Permissions configured"