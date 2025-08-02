#!/bin/bash
# Module: Workspace Setup
# Purpose: Ensure workspace has proper permissions

echo "📁 Setting up workspace..."

# Ensure we're in the workspace directory
cd /workspace

# Set proper permissions for workspace
# This handles edge cases where permissions might need adjustment
chown -R node:node /workspace 2>/dev/null || true

echo "✅ Workspace configured"