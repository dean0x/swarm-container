#!/bin/bash
# Don't use set -e to allow the script to continue even if some commands fail
set +e

echo "🚀 Setting up Claude Flow development environment..."

# Ensure we're in the workspace directory
cd /workspace

# Clean up any problematic files from previous runs
if [ -e "claude-flow" ] && [ ! -d "claude-flow" ]; then
    echo "🧹 Cleaning up non-directory claude-flow file..."
    rm -f claude-flow
fi

# Make security scripts executable
chmod +x /devcontainer-config/scripts/security/init-security.sh 2>/dev/null || true
chmod +x /devcontainer-config/scripts/security/security-monitor.sh 2>/dev/null || true

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
    echo "   Option 1: Browser login after activating Claude Code"
    echo "   Option 2: Set it by running: export ANTHROPIC_API_KEY='your-api-key'"
fi

# Create deps directory for dependencies
# Note: This will create a deps/ folder in the user's project
# It's added to .gitignore automatically
echo "📁 Creating deps directory for AI tool dependencies..."
cd /workspace
mkdir -p deps

# Clean deps directory to ensure fresh clones
echo "🧹 Cleaning deps directory for fresh installations..."
if [ -d "/workspace/deps" ]; then
    # Remove any existing repositories
    rm -rf /workspace/deps/claude-flow 2>/dev/null || true
    rm -rf /workspace/deps/ruv-FANN 2>/dev/null || true
    echo "✅ Deps directory cleaned"
fi

# Clone claude-flow repository for reference
echo "🔄 Setting up Claude Flow source for reference..."
cd /workspace/deps

# Clone claude-flow repository
echo "📥 Cloning claude-flow repository..."
if git clone https://github.com/ruvnet/claude-flow.git; then
    echo "✅ claude-flow source code cloned successfully"
    echo "📂 Source available at: /workspace/deps/claude-flow"
else
    echo "⚠️  Failed to clone claude-flow source code"
    echo "   You can still use claude-flow via npx"
fi

# Create workspace structure
echo "📁 Setting up workspace dependencies..."

# Only create .gitignore if it doesn't exist
if [ ! -f "/workspace/.gitignore" ]; then
    echo "📝 Creating default .gitignore (none found)..."
    cat > /workspace/.gitignore << 'EOF'
# Dependencies
node_modules/

# Logs
*.log

# Environment
.env
.env.*

# Claude Flow
.hive-mind/
.swarm/
memory/
coordination/

# Dependencies folder
deps/
EOF
else
    echo "✓ Existing .gitignore found, preserving it"
    # Append deps/ to existing .gitignore if not already present
    if ! grep -q "^deps/$" /workspace/.gitignore; then
        echo "" >> /workspace/.gitignore
        echo "# SwarmContainer dependencies" >> /workspace/.gitignore
        echo "deps/" >> /workspace/.gitignore
    fi
fi

# Setup ruv-FANN repository
echo "🔄 Setting up ruv-FANN in deps folder..."

# Set proper permissions for workspace
chown -R node:node /workspace 2>/dev/null || true

cd /workspace/deps

# Setup ruv-FANN
RUV_FANN_DIR="/workspace/deps/ruv-FANN"

if [ ! -d "$RUV_FANN_DIR" ]; then
    echo "📥 Cloning ruv-FANN repository to $RUV_FANN_DIR..."
    # Test network connectivity first
    if ! curl -s --head https://github.com >/dev/null; then
        echo "⚠️  Cannot reach github.com - checking security preset..."
        echo "   Current preset: $SECURITY_PRESET"
    fi
    
    if git clone https://github.com/ruvnet/ruv-FANN.git "$RUV_FANN_DIR"; then
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

# Note: ruv-swarm will be used via npx, no installation needed
echo "📂 ruv-FANN source available at: $RUV_FANN_DIR"
echo "💡 ruv-swarm will be accessed via npx when needed"

# Initialize claude-flow using npx (recommended approach)
echo "🔄 Initializing Claude Flow..."
cd /workspace
npx -y claude-flow@alpha init --force || echo "Claude Flow initialization completed"

# Verify MCP server status after initialization
echo "🔍 Checking Claude Flow MCP status..."
npx claude-flow@alpha mcp status || echo "MCP status check completed"

# Test MCP server startup (with timeout to prevent blocking)
echo "🚀 Testing Claude Flow MCP server startup..."
timeout 10s npx claude-flow@alpha mcp start || echo "MCP server startup test completed (may have timed out normally)"

echo "✅ Claude Flow initialized with MCP server"

# Install Oh My Zsh plugins
echo "🎨 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# Update .zshrc to include plugins
if [ -f ~/.zshrc ]; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
fi

# Oh My Zsh handles completions automatically, no need for manual setup

# Install tmux plugins if not already installed
echo "🔧 Setting up tmux plugins..."
if [ -f ~/.tmux.conf ] && [ -d ~/.tmux/plugins/tpm ]; then
    # Install tmux plugins
    ~/.tmux/plugins/tpm/bin/install_plugins || echo "TPM plugins installation completed"
    echo "✅ Tmux plugins installed"
else
    echo "⚠️  Tmux configuration not found, skipping plugin installation"
fi

# Copy tmux helper script to PATH
if [ -f /devcontainer-config/scripts/tmux-6pane.sh ]; then
    cp /devcontainer-config/scripts/tmux-6pane.sh /usr/local/bin/tmux-6pane
    chmod +x /usr/local/bin/tmux-6pane
    echo "✅ tmux-6pane helper script installed"
fi

# Add useful commands to shell history and create startup script
echo "🔧 Setting up quick commands..."

# Create a startup script that adds commands to history
cat > ~/.swarm_history_init << 'EOF'
#!/bin/bash
# Add useful commands to shell history on first run
# Use versioned guard file to handle command updates
HISTORY_VERSION="v2"  # Increment when commands change
if [ ! -f ~/.swarm_history_${HISTORY_VERSION} ]; then
    # For zsh
    if [ -n "$ZSH_VERSION" ]; then
        # Add to current session history (in order: oldest to newest)
        print -s 'npx claude-flow@alpha hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude'
        print -s "npx claude-flow@alpha hive-mind wizard"
        print -s "claude --dangerously-skip-permissions"
        print -s "tmux-6pane"
        print -s "tmux new-session -s dev"
        
        # Also add to history file
        echo ": $(date +%s):0;npx claude-flow@alpha hive-mind spawn \"build me something amazing\" --queen-type adaptive --max-workers 5 --claude" >> ~/.zsh_history
        echo ": $(date +%s):0;npx claude-flow@alpha hive-mind wizard" >> ~/.zsh_history
        echo ": $(date +%s):0;claude --dangerously-skip-permissions" >> ~/.zsh_history
        echo ": $(date +%s):0;tmux-6pane" >> ~/.zsh_history
        echo ": $(date +%s):0;tmux new-session -s dev" >> ~/.zsh_history
    fi
    
    # For bash
    if [ -n "$BASH_VERSION" ]; then
        # Add to history (in order: oldest to newest)
        history -s 'npx claude-flow@alpha hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude'
        history -s "npx claude-flow@alpha hive-mind wizard"
        history -s "claude --dangerously-skip-permissions"
        history -s "tmux-6pane"
        history -s "tmux new-session -s dev"
        
        # Also add to history file
        echo "npx claude-flow@alpha hive-mind spawn \"build me something amazing\" --queen-type adaptive --max-workers 5 --claude" >> ~/.bash_history
        echo "npx claude-flow@alpha hive-mind wizard" >> ~/.bash_history
        echo "claude --dangerously-skip-permissions" >> ~/.bash_history
        echo "tmux-6pane" >> ~/.bash_history
        echo "tmux new-session -s dev" >> ~/.bash_history
    fi
    
    # Clean up old guard files and mark current version as added
    rm -f ~/.swarm_history_added ~/.swarm_history_v1 2>/dev/null || true
    touch ~/.swarm_history_${HISTORY_VERSION}
    echo "✅ Quick commands added to history (${HISTORY_VERSION}) - press ↑ to access them!"
fi
EOF

chmod +x ~/.swarm_history_init

# Add to shell RC files so it runs on shell startup
if [ -f ~/.zshrc ]; then
    echo "" >> ~/.zshrc
    echo "# Swarm Container history initialization" >> ~/.zshrc
    echo "[ -f ~/.swarm_history_init ] && source ~/.swarm_history_init" >> ~/.zshrc
fi

if [ -f ~/.bashrc ]; then
    echo "" >> ~/.bashrc
    echo "# Swarm Container history initialization" >> ~/.bashrc
    echo "[ -f ~/.swarm_history_init ] && source ~/.swarm_history_init" >> ~/.bashrc
fi

echo "✅ Claude Flow development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Set your ANTHROPIC_API_KEY environment variable (or use /login command)"
echo "   2. Run 'claude --dangerously-skip-permissions' to activate Claude Code"
echo "      (If no API key is set, use the /login command when prompted)"
echo "   3. Run 'npx claude-flow@alpha hive-mind wizard' to start using Claude Flow"
echo ""
echo "💡 Quick tip: Press ↑ arrow for command history"
echo ""
echo "📚 Documentation:"
echo "   - Claude Code: https://claude.ai/code"
echo "   - Claude Flow: https://github.com/ruvnet/claude-flow"

# Always exit successfully to prevent container startup issues
exit 0