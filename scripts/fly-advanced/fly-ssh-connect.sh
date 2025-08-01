#!/bin/bash
set -euo pipefail

# Get app name from fly.toml or command line
app_name="${1:-}"

if [ -z "$app_name" ]; then
    if [ -f "fly.toml" ]; then
        app_name=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$app_name" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

echo "🔌 Connecting to SwarmContainer on Fly.io..."
echo "   App: $app_name"
echo ""

# SSH with common options
ssh -o "StrictHostKeyChecking=accept-new" \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -p 10022 \
    node@${app_name}.fly.dev