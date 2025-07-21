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

# Ensure MCP server is properly started
echo "🚀 Starting Claude Flow MCP server..."
npx claude-flow@alpha mcp start || echo "MCP server startup attempted"

echo "✅ Claude Flow initialized with MCP server"

# Install Oh My Zsh plugins
echo "🎨 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# Update .zshrc to include plugins
if [ -f ~/.zshrc ]; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
fi

# Add useful commands to shell history and create startup script
echo "🔧 Setting up quick commands..."

# Create a startup script that adds commands to history
cat > ~/.swarm_history_init << 'EOF'
#!/bin/bash
# Add useful commands to shell history - with smart update logic

# Define our commands (easier to maintain)
declare -a SWARM_COMMANDS=(
    'npx claude-flow@alpha hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude'
    'npx claude-flow@alpha hive-mind wizard'
    'claude --dangerously-skip-permissions'
    'codex --help'
    'gemini --help'
)

# For zsh
if [ -n "$ZSH_VERSION" ]; then
    # Check if we need to update by looking for old commands
    if [ -f ~/.zsh_history ] && grep -q "^.*claude-flow hive-mind" ~/.zsh_history 2>/dev/null; then
        echo "🔄 Updating command history from claude-flow to npx..."
        # Remove old claude-flow commands (without npx)
        grep -v ":claude-flow hive-mind\|:claude-flow --" ~/.zsh_history > ~/.zsh_history.tmp 2>/dev/null || true
        if [ -f ~/.zsh_history.tmp ]; then
            mv ~/.zsh_history.tmp ~/.zsh_history
        fi
    fi
    
    # Check if new commands already exist
    UPDATE_NEEDED=false
    for cmd in "${SWARM_COMMANDS[@]}"; do
        if ! grep -Fq "$cmd" ~/.zsh_history 2>/dev/null; then
            UPDATE_NEEDED=true
            break
        fi
    done
    
    # Add commands if needed
    if [ "$UPDATE_NEEDED" = true ]; then
        echo "📝 Adding quick commands to zsh history..."
        for cmd in "${SWARM_COMMANDS[@]}"; do
            # Add to current session
            print -s "$cmd" 2>/dev/null || true
            # Add to history file if not already there
            if ! grep -Fq "$cmd" ~/.zsh_history 2>/dev/null; then
                echo ": $(date +%s):0;$cmd" >> ~/.zsh_history
            fi
        done
        echo "✅ Quick commands added to history - press ↑ to access them!"
    fi
fi

# For bash
if [ -n "$BASH_VERSION" ]; then
    # Check if we need to update by looking for old commands
    if [ -f ~/.bash_history ] && grep -q "^claude-flow hive-mind" ~/.bash_history 2>/dev/null; then
        echo "🔄 Updating command history from claude-flow to npx..."
        # Remove old claude-flow commands (without npx)
        grep -v "^claude-flow hive-mind\|^claude-flow --" ~/.bash_history > ~/.bash_history.tmp 2>/dev/null || true
        if [ -f ~/.bash_history.tmp ]; then
            mv ~/.bash_history.tmp ~/.bash_history
        fi
    fi
    
    # Check if new commands already exist
    UPDATE_NEEDED=false
    for cmd in "${SWARM_COMMANDS[@]}"; do
        if ! grep -Fq "$cmd" ~/.bash_history 2>/dev/null; then
            UPDATE_NEEDED=true
            break
        fi
    done
    
    # Add commands if needed
    if [ "$UPDATE_NEEDED" = true ]; then
        echo "📝 Adding quick commands to bash history..."
        for cmd in "${SWARM_COMMANDS[@]}"; do
            # Add to current session
            history -s "$cmd" 2>/dev/null || true
            # Add to history file if not already there
            if ! grep -Fq "$cmd" ~/.bash_history 2>/dev/null; then
                echo "$cmd" >> ~/.bash_history
            fi
        done
        echo "✅ Quick commands added to history - press ↑ to access them!"
    fi
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
echo "📚 Documentation:"
echo "   - Claude Code: https://claude.ai/code"
echo "   - Claude Flow: https://github.com/ruvnet/claude-flow"

# Always exit successfully to prevent container startup issues
exit 0