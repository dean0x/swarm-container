#!/bin/bash
# Update Claude Code seamlessly without sudo
# This script works around the container permission restrictions

set -e

echo "🔄 Updating Claude Code..."

# Get current Claude Code location
CLAUDE_PATH=$(which claude 2>/dev/null || echo "")

if [ -z "$CLAUDE_PATH" ]; then
    echo "❌ Claude Code not found in PATH"
    exit 1
fi

# Find the actual npm global directory where claude is installed
CLAUDE_REAL_PATH=$(readlink -f "$CLAUDE_PATH")
NPM_GLOBAL_DIR=$(dirname $(dirname "$CLAUDE_REAL_PATH"))

echo "📍 Found Claude Code at: $NPM_GLOBAL_DIR"

# Check if we have write permissions
if [ ! -w "$NPM_GLOBAL_DIR/lib/node_modules/@anthropic-ai/claude-code" ]; then
    echo "❌ No write permissions to $NPM_GLOBAL_DIR"
    echo "   This update method requires rebuilding the container."
    exit 1
fi

# Create a temporary directory for the update
TEMP_DIR=$(mktemp -d)
echo "📦 Creating temporary installation at: $TEMP_DIR"

# Install latest Claude Code to temporary directory
echo "⬇️  Downloading latest Claude Code..."
npm install @anthropic-ai/claude-code@latest --prefix="$TEMP_DIR" --global-style

# Update the claude-code package
CLAUDE_CODE_DIR="$NPM_GLOBAL_DIR/lib/node_modules/@anthropic-ai/claude-code"
TEMP_CLAUDE_CODE_DIR="$TEMP_DIR/lib/node_modules/@anthropic-ai/claude-code"

if [ -d "$TEMP_CLAUDE_CODE_DIR" ] && [ -d "$CLAUDE_CODE_DIR" ]; then
    echo "🔄 Updating package files..."
    
    # Backup current version
    rm -rf "$CLAUDE_CODE_DIR.backup"
    cp -r "$CLAUDE_CODE_DIR" "$CLAUDE_CODE_DIR.backup"
    
    # Update the package
    rm -rf "$CLAUDE_CODE_DIR"
    cp -r "$TEMP_CLAUDE_CODE_DIR" "$CLAUDE_CODE_DIR"
    
    # Update the binary
    cp -f "$TEMP_DIR/bin/claude" "$NPM_GLOBAL_DIR/bin/claude"
    chmod +x "$NPM_GLOBAL_DIR/bin/claude"
    
    # Clean up backup
    rm -rf "$CLAUDE_CODE_DIR.backup"
    
    echo "✅ Update successful!"
else
    echo "❌ Could not locate package directories"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

# Verify the update
NEW_VERSION=$(claude --version 2>/dev/null || echo "unknown")
echo ""
echo "✅ Claude Code updated to version: $NEW_VERSION"
echo ""
echo "🚀 You can now use: claude --dangerously-skip-permissions"