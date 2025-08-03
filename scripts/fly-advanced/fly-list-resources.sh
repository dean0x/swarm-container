#!/bin/bash
set -euo pipefail

echo "📋 Fly.io Resources Overview"
echo "==========================="
echo ""

# List all apps
echo "🚀 Your Fly.io Apps:"
echo "-------------------"
flyctl apps list

echo ""
echo "💾 Volumes by App:"
echo "-----------------"
# Get all app names and check their volumes
flyctl apps list --json | jq -r '.[].Name' | while read -r app_name; do
    if [ -n "$app_name" ]; then
        echo ""
        echo "App: $app_name"
        flyctl volumes list --app "$app_name" 2>/dev/null || echo "  No volumes or access denied"
    fi
done

echo ""
echo "🌐 IP Addresses:"
echo "---------------"
flyctl ips list 2>/dev/null || echo "No IP addresses allocated"

echo ""
echo "💡 To clean up an app completely:"
echo "  ./scripts/fly-cleanup.sh <app-name>"
echo ""
echo "To destroy all SwarmContainer test apps:"
echo "  flyctl apps list | grep swarmtest | awk '{print $1}' | xargs -I {} ./scripts/fly-cleanup.sh {}"