#!/bin/bash
set -euo pipefail

echo "🧹 SwarmContainer Fly.io Cleanup"
echo "================================"
echo ""

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name>"
    echo ""
    echo "This will completely remove:"
    echo "  - The Fly.io app"
    echo "  - All associated volumes"
    echo "  - All IP addresses"
    echo ""
    echo "To find your apps: flyctl apps list"
    exit 1
fi

echo "⚠️  WARNING: This will completely destroy:"
echo "   - App: $APP_NAME"
echo "   - All volumes and data"
echo "   - All configurations"
echo ""
read -p "Are you sure? Type 'yes' to continue: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "🔍 Checking if app exists..."
if ! flyctl apps list | grep -q "$APP_NAME"; then
    echo "❌ App '$APP_NAME' not found"
    echo ""
    echo "Your current apps:"
    flyctl apps list
    exit 1
fi

echo ""
echo "📊 Current app status:"
flyctl status --app "$APP_NAME" 2>/dev/null || true

echo ""
echo "💾 Current volumes:"
flyctl volumes list --app "$APP_NAME" 2>/dev/null || true

echo ""
echo "🗑️  Starting cleanup..."

# Stop all machines first
echo ""
echo "1️⃣ Stopping machines..."
# Use grep/awk instead of jq
flyctl machine list --app "$APP_NAME" 2>/dev/null | grep -E '^[a-f0-9]+' | awk '{print $1}' | while read -r machine_id; do
    if [ -n "$machine_id" ]; then
        echo "   Stopping machine: $machine_id"
        flyctl machine stop "$machine_id" --app "$APP_NAME" 2>/dev/null || true
    fi
done

# Destroy the app (this also removes volumes and IPs)
echo ""
echo "2️⃣ Destroying app and all resources..."
flyctl apps destroy "$APP_NAME" --yes

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "You can now redeploy with:"
echo "  ./scripts/fly-deploy-all.sh <new-app-name> <region>"
echo ""
echo "Or check remaining apps with:"
echo "  flyctl apps list"