#!/bin/bash
# Setup npm permissions for global package updates

echo "🔧 Setting up npm global package permissions..."

# Get the npm global directory
NPM_GLOBAL=$(npm config get prefix)

# Check if we have write permissions to the global modules
if [ -w "$NPM_GLOBAL/lib/node_modules/@anthropic-ai/claude-code" ]; then
    echo "✅ npm global directory is writable"
    echo "   You can update Claude Code using: update-claude"
else
    echo "⚠️  npm global directory is not writable"
    echo "   Claude Code updates will require container rebuild"
    echo "   Current npm prefix: $NPM_GLOBAL"
fi

# The update-claude command is available in /usr/local/bin/
if [ -x "/usr/local/bin/update-claude" ]; then
    echo "✅ update-claude command is available"
else
    echo "❌ update-claude command not found"
fi