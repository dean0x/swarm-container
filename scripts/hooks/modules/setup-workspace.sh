#!/bin/bash
# Module: Workspace Setup
# Purpose: Verify workspace is accessible

echo "📁 Checking workspace..."

# Ensure we're in the workspace directory
cd /workspace

# Just verify we can access the workspace
if [ -w . ]; then
    echo "✅ Workspace is accessible and writable"
else
    echo "⚠️  Workspace may have permission issues"
fi