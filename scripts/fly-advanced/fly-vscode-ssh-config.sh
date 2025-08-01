#!/bin/bash
set -euo pipefail

echo "🔧 VS Code SSH Configuration Generator"
echo "====================================="
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

SSH_CONFIG_FILE="$HOME/.ssh/config"
HOST_ALIAS="fly-$APP_NAME"

echo "📝 Generating SSH config for: $APP_NAME"
echo ""

# Create SSH config entry
CONFIG_ENTRY="
# SwarmContainer on Fly.io - $APP_NAME
Host $HOST_ALIAS
    HostName ${APP_NAME}.fly.dev
    Port 10022
    User node
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
"

# Check if entry already exists
if grep -q "Host $HOST_ALIAS" "$SSH_CONFIG_FILE" 2>/dev/null; then
    echo "⚠️  Configuration already exists for: $HOST_ALIAS"
    echo "   Remove existing entry first if you want to regenerate"
else
    # Backup existing config
    if [ -f "$SSH_CONFIG_FILE" ]; then
        cp "$SSH_CONFIG_FILE" "${SSH_CONFIG_FILE}.backup"
        echo "📋 Backed up existing config to: ${SSH_CONFIG_FILE}.backup"
    fi
    
    # Add new entry
    echo "$CONFIG_ENTRY" >> "$SSH_CONFIG_FILE"
    echo "✅ Configuration added to: $SSH_CONFIG_FILE"
fi

echo ""
echo "📡 VS Code Remote-SSH Instructions:"
echo "1. Open VS Code"
echo "2. Press Cmd/Ctrl + Shift + P"
echo "3. Type: 'Remote-SSH: Connect to Host'"
echo "4. Select: '$HOST_ALIAS'"
echo ""
echo "🚀 Direct SSH command:"
echo "   ssh $HOST_ALIAS"