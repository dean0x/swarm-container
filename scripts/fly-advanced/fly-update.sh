#!/bin/bash
set -euo pipefail

echo "🔄 SwarmContainer Update & Redeploy"
echo "=================================="
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

echo "🎯 Updating: $APP_NAME"
echo ""

# Step 1: Check for local changes
echo "1. Checking for local changes..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Uncommitted changes detected:"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
    fi
fi

# Step 2: Pull latest changes
echo ""
echo "2. Pulling latest SwarmContainer updates..."
git pull || echo "⚠️  Git pull failed - continuing anyway"

# Step 3: Update fly.toml if needed
echo ""
echo "3. Checking fly.toml..."
if [ -f "fly.toml.example" ]; then
    if [ fly.toml.example -nt fly.toml ]; then
        echo "⚠️  fly.toml.example is newer than fly.toml"
        echo "   Consider updating your configuration"
    fi
fi

# Step 4: Deploy
echo ""
echo "4. Deploying updates..."
flyctl deploy --app "$APP_NAME" || {
    echo "❌ Deployment failed"
    exit 1
}

# Step 5: Post-update tasks
echo ""
echo "5. Running post-update tasks..."

# Check if MCP needs update
echo "   Updating MCP configuration..."
./scripts/fly-mcp-setup.sh "$APP_NAME" || echo "   ⚠️  MCP update failed"

echo ""
echo "=================================="
echo "✅ Update complete!"
echo ""
echo "Changes deployed to: $APP_NAME"
echo "Connect: ssh node@${APP_NAME}.fly.dev -p 10022"