#!/bin/bash
set -euo pipefail

# Quick status overview of all Fly.io SwarmContainer apps

echo "🚀 SwarmContainer Fly.io Status"
echo "=============================="
echo ""

# Get all apps with swarm in name or from fly.toml
if [ -f "fly.toml" ]; then
    DEFAULT_APP=$(grep "^app = " fly.toml | cut -d'"' -f2)
    echo "📱 Default App: $DEFAULT_APP"
    echo ""
fi

echo "📊 All SwarmContainer Apps:"
flyctl apps list | grep -E "(swarm|NAME)" || echo "No apps found"

echo ""
echo "💰 Current Usage:"
flyctl dashboard metrics

echo ""
echo "💡 Management Tips:"
echo "• Detailed status: ./scripts/fly-manage.sh <app-name> status"
echo "• Quick SSH: ./scripts/fly-ssh-connect.sh <app-name>"
echo "• View logs: flyctl logs -a <app-name>"