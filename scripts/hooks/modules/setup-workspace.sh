#!/bin/bash
# Module: Workspace Setup
# Purpose: Ensure workspace has proper permissions

echo "📁 Setting up workspace..."

# Ensure we're in the workspace directory
cd /workspace

# Only fix permissions for specific directories that need it
# Avoid recursive chown on entire workspace as it can be slow with many files
if [ -d ".devcontainer" ]; then
    chown -R node:node .devcontainer 2>/dev/null || true
fi

# Create common directories if they don't exist
for dir in .vscode .config; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chown node:node "$dir"
    fi
done

echo "✅ Workspace configured"