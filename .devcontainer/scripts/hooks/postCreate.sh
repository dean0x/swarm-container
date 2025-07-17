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
chmod +x /devcontainer-config/.devcontainer/scripts/security/init-security.sh 2>/dev/null || true
chmod +x /devcontainer-config/.devcontainer/scripts/security/security-monitor.sh 2>/dev/null || true

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
echo "📁 Creating deps directory for dependencies..."
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

# Clone and setup claude-flow from source
echo "🔄 Setting up Claude Flow from source..."
cd /workspace/deps

# Clone claude-flow repository
echo "📥 Cloning claude-flow repository..."
if git clone https://github.com/ruvnet/claude-flow.git; then
    echo "✅ claude-flow cloned successfully"
else
    echo "❌ Failed to clone claude-flow!"
    echo "📥 Installing Claude Flow from npm as fallback..."
    if npm install -g claude-flow@alpha; then
        echo "✅ Claude Flow installed successfully from npm"
        # Verify installation
        if command -v claude-flow &> /dev/null; then
            echo "📍 Claude Flow location: $(which claude-flow)"
        fi
        else
            echo "❌ Failed to install Claude Flow from npm"
        fi
    # Skip the rest of source installation
    SKIP_SOURCE_INSTALL=true
fi

# Install claude-flow - prefer source over npm
echo "📦 Installing Claude Flow..."

# First, try to install from source
if [ -d "claude-flow" ] && [ -f "claude-flow/package.json" ]; then
    echo "🔄 Trying to install from source..."
    cd claude-flow
    
    # Skip Puppeteer download to avoid ARM issues
    export PUPPETEER_SKIP_DOWNLOAD=true
    
    # Install with --force and skip optional dependencies
    npm install --force --no-optional || echo "Some dependencies failed, continuing..."
    
    # Try global install with force
    npm install -g . --force || echo "Global install had issues, continuing..."
    
    cd ..

else
    # try to install from npm which handles dependencies better
    echo "📥 Installing Claude Flow from npm registry..."
    if npm install -g claude-flow@alpha; then
        echo "✅ Claude Flow installed successfully from npm"
        
        # Verify installation
        if command -v claude-flow &> /dev/null; then
            echo "📍 Claude Flow location: $(which claude-flow)"
        fi
    else
        echo "❌ Failed to install Claude Flow from npm"
    fi
fi

# Create workspace structure
echo "📁 Setting up clean workspace..."

# Create initial .gitignore
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

# Install ruv-swarm dependencies with detailed error handling
echo "📦 Installing ruv-swarm dependencies..."
if [ -d "$RUV_FANN_DIR/ruv-swarm/npm" ]; then
    cd "$RUV_FANN_DIR/ruv-swarm/npm"
    
    # Install dependencies excluding devDependencies (skip wasm-opt)
    echo "Installing dependencies without devDependencies (skipping wasm-opt)..."

    if ! npm install --omit=dev 2>&1 | tee /tmp/ruv-swarm-install.log; then
        echo "❌ ruv-swarm npm install failed!"
        echo "📋 Error details:"
        echo "----------------------------------------"
        tail -20 /tmp/ruv-swarm-install.log
        echo "----------------------------------------"
        echo "💡 Debug tips:"
        echo "   - Check the full log: cat /tmp/ruv-swarm-install.log"
        echo "   - Try manual install: cd $RUV_FANN_DIR/ruv-swarm/npm && npm install --omit=dev"
        echo "⚠️  Continuing setup - ruv-swarm may still be functional..."
    else
        echo "✅ ruv-swarm dependencies installed successfully (without devDependencies)"
        echo "   Note: wasm-opt devDependency was skipped"
    fi
else
    echo "❌ Cannot install ruv-swarm - directory $RUV_FANN_DIR/ruv-swarm/npm not found!"
    echo "   Check if clone was successful and directory structure is correct"
fi

# Initialize claude-flow (this will create .claude directory and config)
echo "🔄 Initializing Claude Flow..."
cd /workspace
if command -v claude-flow &> /dev/null; then
    claude-flow init --force || echo "Claude Flow initialization completed"
    echo "✅ Claude Flow initialized"
else
    echo "⚠️  Claude Flow command not found, skipping initialization"
fi

# Configure Claude MCP servers (this will override any MCP configs from init)
echo "🔄 Configuring Claude MCP servers..."
cd /workspace

# Configure claude-flow MCP to use local installation
echo "📦 Setting up local claude-flow MCP server..."
claude mcp remove claude-flow 2>/dev/null || true
if claude mcp add claude-flow claude-flow mcp start 2>&1; then
    echo "✅ Claude Flow MCP configured with local installation"
else
    echo "⚠️  Failed to add claude-flow MCP server"
fi

# Configure ruv-swarm MCP
echo "📦 Setting up local ruv-swarm MCP server..."
# Update paths for deps folder
RUV_SWARM_BIN=""
if [ -f "$RUV_FANN_DIR/ruv-swarm/npm/bin/ruv-swarm-secure.js" ]; then
    RUV_SWARM_BIN="$RUV_FANN_DIR/ruv-swarm/npm/bin/ruv-swarm-secure.js"
elif [ -f "$RUV_FANN_DIR/ruv-swarm/npm/index.js" ]; then
    RUV_SWARM_BIN="$RUV_FANN_DIR/ruv-swarm/npm/index.js"
elif [ -f "$RUV_FANN_DIR/ruv-swarm/npm/ruv-swarm.js" ]; then
    RUV_SWARM_BIN="$RUV_FANN_DIR/ruv-swarm/npm/ruv-swarm.js"
fi

if [ -n "$RUV_SWARM_BIN" ]; then
    echo "Found ruv-swarm at: $RUV_SWARM_BIN"
    
    # Remove existing ruv-swarm if it exists
    claude mcp remove ruv-swarm 2>/dev/null || true
    
    # Add local ruv-swarm
    if claude mcp add ruv-swarm "$RUV_SWARM_BIN" mcp start 2>&1; then
        echo "✅ ruv-swarm MCP configured with local installation"
    else
        echo "❌ Failed to add ruv-swarm to MCP"
        echo "   You can try manually: claude mcp add ruv-swarm $RUV_SWARM_BIN mcp start"
    fi
else
    echo "⚠️  ruv-swarm binary not found in expected locations"
    echo "   Checked:"
    echo "   - $RUV_FANN_DIR/ruv-swarm/npm/bin/ruv-swarm-secure.js"
    echo "   - $RUV_FANN_DIR/ruv-swarm/npm/index.js"
    echo "   - $RUV_FANN_DIR/ruv-swarm/npm/ruv-swarm.js"
    echo "   You may need to check the actual structure and configure manually"
fi

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
# Add useful commands to shell history on first run

# Check if we've already added these (to avoid duplicates)
if [ ! -f ~/.swarm_history_added ]; then
    # For zsh
    if [ -n "$ZSH_VERSION" ]; then
        # Add to current session history (in order: oldest to newest)
        print -s 'claude-flow hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude'
        print -s "claude-flow hive-mind wizard"
        print -s "claude --dangerously-skip-permissions"
        
        # Also add to history file
        echo ": $(date +%s):0;claude-flow hive-mind spawn \"build me something amazing\" --queen-type adaptive --max-workers 5 --claude" >> ~/.zsh_history
        echo ": $(date +%s):0;claude-flow hive-mind wizard" >> ~/.zsh_history
        echo ": $(date +%s):0;claude --dangerously-skip-permissions" >> ~/.zsh_history
    fi
    
    # For bash
    if [ -n "$BASH_VERSION" ]; then
        # Add to history (in order: oldest to newest)
        history -s 'claude-flow hive-mind spawn "build me something amazing" --queen-type adaptive --max-workers 5 --claude'
        history -s "claude-flow hive-mind wizard"
        history -s "claude --dangerously-skip-permissions"
        
        # Also add to history file
        echo "claude-flow hive-mind spawn \"build me something amazing\" --queen-type adaptive --max-workers 5 --claude" >> ~/.bash_history
        echo "claude-flow hive-mind wizard" >> ~/.bash_history
        echo "claude --dangerously-skip-permissions" >> ~/.bash_history
    fi
    
    # Mark as added
    touch ~/.swarm_history_added
    echo "✅ Quick commands added to history - press ↑ to access them!"
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
echo "   3. Run 'claude-flow hive-mind wizard' to start using Claude Flow"
echo ""
echo "📚 Documentation:"
echo "   - Claude Code: https://claude.ai/code"
echo "   - Claude Flow: https://github.com/ruvnet/claude-flow"

# Always exit successfully to prevent container startup issues
exit 0