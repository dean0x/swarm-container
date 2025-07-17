#!/bin/bash
# Create GitHub Release for SwarmContainer v1.0.0

echo "Creating GitHub Release v1.0.0..."

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "Option 1: Install gh first:"
    echo "  brew install gh  # macOS"
    echo "  # or see: https://cli.github.com/manual/installation"
    echo ""
    echo "Option 2: Create release via web:"
    echo "  1. Go to: https://github.com/dean0x/swarm-container/releases/new"
    echo "  2. Choose tag: v1.0.0"
    echo "  3. Copy the release notes from: /tmp/release-notes.md"
    echo ""
    exit 1
fi

# Create the release
gh release create v1.0.0 \
  --title "v1.0.0 - Initial Release 🚀" \
  --notes-file /tmp/release-notes.md \
  --latest

if [ $? -eq 0 ]; then
    echo "✅ Release created successfully!"
    echo "🎉 View it at: https://github.com/dean0x/swarm-container/releases/tag/v1.0.0"
else
    echo "❌ Failed to create release"
fi