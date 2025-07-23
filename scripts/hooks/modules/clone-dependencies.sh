#!/bin/bash
# Module: Clone Dependencies
# Purpose: Clone claude-flow and ruv-FANN repositories

echo "🔄 Cloning AI tool dependencies..."

cd /workspace/deps

# Function to test network connectivity
test_github_connectivity() {
    if ! curl -s --head https://github.com >/dev/null; then
        echo "⚠️  Cannot reach github.com - checking security preset..."
        echo "   Current preset: $SECURITY_PRESET"
        return 1
    fi
    return 0
}

# Clone claude-flow repository
echo "📥 Cloning claude-flow repository..."
if test_github_connectivity && git clone https://github.com/ruvnet/claude-flow.git; then
    echo "✅ claude-flow source code cloned successfully"
    echo "📂 Source available at: /workspace/deps/claude-flow"
else
    echo "⚠️  Failed to clone claude-flow source code"
    echo "   You can still use claude-flow via npx"
fi

# Setup ruv-FANN repository
echo "🔄 Setting up ruv-FANN in deps folder..."
RUV_FANN_DIR="/workspace/deps/ruv-FANN"

if [ ! -d "$RUV_FANN_DIR" ]; then
    echo "📥 Cloning ruv-FANN repository to $RUV_FANN_DIR..."
    if test_github_connectivity && git clone https://github.com/ruvnet/ruv-FANN.git "$RUV_FANN_DIR"; then
        echo "✅ ruv-FANN cloned successfully"
    else
        echo "❌ Failed to clone ruv-FANN!"
    fi
else
    echo "✓ ruv-FANN already cloned"
fi

# Verify ruv-FANN structure
echo "📂 Checking ruv-FANN directory structure..."
if [ -d "$RUV_FANN_DIR" ]; then
    ls -la "$RUV_FANN_DIR/" | head -10
    if [ -d "$RUV_FANN_DIR/ruv-swarm/npm" ]; then
        echo "✅ ruv-swarm directory found"
    else
        echo "❌ ruv-swarm directory not found in $RUV_FANN_DIR!"
        echo "Directory contents:"
        find "$RUV_FANN_DIR" -type d -name "ruv-swarm" 2>/dev/null | head -10
    fi
else
    echo "❌ $RUV_FANN_DIR directory does not exist!"
fi

echo "📂 ruv-FANN source available at: $RUV_FANN_DIR"
echo "💡 ruv-swarm will be accessed via npx when needed"