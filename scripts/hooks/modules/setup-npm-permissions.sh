#!/bin/bash
# Setup npm permissions for global package updates

echo "🔧 Checking npm global package permissions..."

# Get the npm global directory
NPM_GLOBAL=$(npm config get prefix)
echo "   npm prefix: $NPM_GLOBAL"

# Check if we have write permissions to the global modules
if [ -w "$NPM_GLOBAL/lib/node_modules" ]; then
    echo "✅ npm global directory is writable"
    echo "   You can update packages using: npm update -g <package>"
else
    echo "⚠️  npm global directory is not writable"
    echo "   Package updates will require container rebuild"
fi