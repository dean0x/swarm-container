#!/bin/bash
# Don't use set -e to allow the script to continue even if some commands fail
set +e

echo "🚀 Setting up Claude Flow development environment..."

# Make security scripts executable
chmod +x .devcontainer/init-security.sh 2>/dev/null || true
chmod +x .devcontainer/security-monitor.sh 2>/dev/null || true

# Configure npm
echo "📦 Configuring npm..."
npm config set registry https://registry.npmjs.org/

# Initialize claude-code (if API key is provided)
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "🤖 Initializing Claude Code..."
    claude --version
    echo "✅ Claude Code initialized"
else
    echo "⚠️  ANTHROPIC_API_KEY not set. You have two options:"
    echo "   Option 1: Set it by running: export ANTHROPIC_API_KEY='your-api-key'"
    echo "   Option 2: Use the /login command after activating Claude Code"
fi

# Verify claude-flow installation
echo "🔄 Verifying Claude Flow installation..."
if command -v claude-flow &> /dev/null; then
    claude-flow --version || echo "Claude Flow installed from source"
    echo "📍 Claude Flow location: $(which claude-flow)"
else
    echo "❌ Claude Flow not found. Source installation may have failed."
    echo "   Check /opt/claude-flow directory for installation details."
fi

# If source installation failed, offer npm fallback
if [ ! -d "/opt/claude-flow" ] && ! command -v claude-flow &> /dev/null; then
    echo "📥 Installing Claude Flow from npm as fallback..."
    npm install -g claude-flow@alpha
fi

# Create workspace structure
echo "📁 Setting up workspace structure..."
mkdir -p /workspace/swarms
mkdir -p /workspace/logs
mkdir -p /workspace/data

# Set proper permissions - skip node_modules which is a volume mount
for dir in swarms logs data; do
    if [ -d "/workspace/$dir" ]; then
        chown -R node:node "/workspace/$dir" 2>/dev/null || true
    fi
done

# Install Oh My Zsh plugins
echo "🎨 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# Update .zshrc to include plugins
if [ -f ~/.zshrc ]; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
fi

echo "✅ Claude Flow development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Set your ANTHROPIC_API_KEY environment variable (or use /login command)"
echo "   2. Run 'claude --dangerously-skip-permissions' to activate Claude Code"
echo "      (If no API key is set, use the /login command when prompted)"
echo "   3. Run 'claude-flow hive-mind wizard' to start using Claude Flow"
echo ""
echo "📚 Documentation:"
echo "   - Claude Code: https://claude.ai/code"
echo "   - Claude Flow: https://github.com/ruvnet/claude-flow"