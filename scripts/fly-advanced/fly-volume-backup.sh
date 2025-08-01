#!/bin/bash
set -euo pipefail

echo "💾 SwarmContainer Volume Backup"
echo "=============================="

app_name="${1:-}"
backup_dir="${2:-./backups}"

if [ -z "$app_name" ]; then
    echo "Usage: $0 <app-name> [backup-dir]"
    exit 1
fi

# Create backup directory
mkdir -p "$backup_dir"
timestamp=$(date +%Y%m%d_%H%M%S)

echo "📦 Creating backup..."
echo "   App: $app_name"
echo "   Timestamp: $timestamp"

# SSH into container and create tarball
ssh -p 10022 node@${app_name}.fly.dev \
    "cd / && tar czf - workspace home/node" \
    > "$backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"

if [ $? -eq 0 ]; then
    echo "✅ Backup created: $backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"
    
    # Show backup size
    ls -lh "$backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"
else
    echo "❌ Backup failed"
    exit 1
fi