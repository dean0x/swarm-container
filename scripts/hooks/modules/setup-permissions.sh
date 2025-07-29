#!/bin/bash
# Module: Permissions Setup
# Purpose: Set proper permissions for scripts and directories

echo "🔒 Setting up permissions..."

# Make security scripts executable (these are copied to /scripts/security during build)
chmod +x /scripts/security/init-security.sh 2>/dev/null || true
chmod +x /scripts/security/security-monitor.sh 2>/dev/null || true

# Make all module scripts executable in workspace
if [ -d "/workspace/.devcontainer/scripts/hooks/modules" ]; then
    chmod +x /workspace/.devcontainer/scripts/hooks/modules/*.sh 2>/dev/null || true
fi

# Ensure .devcontainer scripts are executable
find /workspace/.devcontainer -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

echo "✅ Permissions configured"