#!/bin/bash

echo "🧪 Testing Claude Flow DevContainer..."
echo ""

# Build the container
echo "📦 Building container..."
docker build -t claude-flow-test -f .devcontainer/Dockerfile . || exit 1

echo ""
echo "✅ Build successful!"
echo ""

# Test basic functionality
echo "🔍 Testing installations..."
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  claude-flow-test \
  bash -c "
    echo 'Node.js: ' && node --version
    echo 'npm: ' && npm --version
    echo -n 'Claude Code: ' && claude --version 2>/dev/null || echo 'installed'
    echo -n 'Claude Flow: ' && claude-flow --version 2>/dev/null || echo 'alpha installed'
    echo -n 'Git: ' && git --version
    echo -n 'Zsh: ' && zsh --version
  "

echo ""
echo "🔐 Testing container security (requires running as root for iptables)..."
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --security-opt seccomp=unconfined \
  --user root \
  claude-flow-test \
  bash -c "
    # Initialize firewall
    bash .devcontainer/init-firewall.sh >/dev/null 2>&1
    
    # Test blocked site
    echo -n 'Testing blocked site (google.com): '
    if timeout 2 curl -s google.com >/dev/null 2>&1; then
      echo '❌ FAILED - Site should be blocked!'
    else
      echo '✅ Blocked (expected)'
    fi
    
    # Test allowed npm
    echo -n 'Testing allowed npm registry: '
    if timeout 2 curl -s https://registry.npmjs.org/ >/dev/null 2>&1; then
      echo '✅ Accessible'
    else
      echo '❌ FAILED - npm should be accessible!'
    fi
  "

echo ""
echo "🎉 Container test complete!"
echo ""
echo "To use with VS Code:"
echo "1. Open this folder in VS Code"
echo "2. Click 'Reopen in Container' when prompted"
echo "3. Set ANTHROPIC_API_KEY environment variable (or use /login command)"
echo "4. Run: claude --dangerously-skip-permissions"