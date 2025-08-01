#!/bin/bash
# Module: Shell Setup
# Purpose: Configure Zsh plugins and shell history

echo "🎨 Setting up shell environment..."

# Install oh-my-zsh if not already installed
if [ ! -d ~/.oh-my-zsh ]; then
    echo "📦 Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
        echo "⚠️  Failed to install oh-my-zsh, continuing without it..."
    }
fi

# Install Oh My Zsh plugins (only if oh-my-zsh exists)
if [ -d ~/.oh-my-zsh ]; then
    echo "🎨 Installing Zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

    # Update .zshrc to include plugins
    if [ -f ~/.zshrc ]; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    fi
fi

# Create a startup script that adds commands to history
echo "🔧 Setting up quick commands..."
cat > ~/.swarm_history_init << 'EOF'
#!/bin/bash
# Add useful commands to shell history on first run
# Use versioned guard file to handle command updates
HISTORY_VERSION="v4"  # Increment when commands change
if [ ! -f ~/.swarm_history_${HISTORY_VERSION} ]; then
    # For zsh
    if [ -n "$ZSH_VERSION" ]; then
        # Add to current session history (in order: oldest to newest)
        print -s "claude --dangerously-skip-permissions"
        
        # Also add to history file
        echo ": $(date +%s):0;claude --dangerously-skip-permissions" >> ~/.zsh_history
    fi
    
    # For bash
    if [ -n "$BASH_VERSION" ]; then
        # Add to history (in order: oldest to newest)
        history -s "claude --dangerously-skip-permissions"
        
        # Also add to history file
        echo "claude --dangerously-skip-permissions" >> ~/.bash_history
    fi
    
    # Clean up old guard files and mark current version as added
    rm -f ~/.swarm_history_added ~/.swarm_history_v1 ~/.swarm_history_v2 ~/.swarm_history_v3 2>/dev/null || true
    touch ~/.swarm_history_${HISTORY_VERSION}
    echo "✅ Quick commands added to history (${HISTORY_VERSION}) - press ↑ to access them!"
fi
EOF

chmod +x ~/.swarm_history_init

# Ensure shell RC files exist
touch ~/.bashrc
touch ~/.zshrc

# Add to shell RC files so it runs on shell startup
# Check if already added to avoid duplicates
if ! grep -q "swarm_history_init" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# Swarm Container history initialization" >> ~/.zshrc
    echo "[ -f ~/.swarm_history_init ] && source ~/.swarm_history_init" >> ~/.zshrc
fi

if ! grep -q "swarm_history_init" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Swarm Container history initialization" >> ~/.bashrc
    echo "[ -f ~/.swarm_history_init ] && source ~/.swarm_history_init" >> ~/.bashrc
fi

# Add MCP watcher control aliases
echo "🔧 Adding MCP watcher commands..."

# Add to bashrc if not already there
if ! grep -q "mcp-watcher-start" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# MCP Config Watcher Commands
alias mcp-watcher-start='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh start'
alias mcp-watcher-stop='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh stop'
alias mcp-watcher-restart='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh restart'
alias mcp-watcher-status='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh status'
alias mcp-watcher-logs='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh logs'
alias mcp-update='bash /workspace/.devcontainer/scripts/hooks/modules/setup-mcp.sh'
EOF
fi

# Also add to zshrc if not already there
if ! grep -q "mcp-watcher-start" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# MCP Config Watcher Commands
alias mcp-watcher-start='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh start'
alias mcp-watcher-stop='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh stop'
alias mcp-watcher-restart='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh restart'
alias mcp-watcher-status='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh status'
alias mcp-watcher-logs='/workspace/.devcontainer/scripts/services/mcp-watcher-control.sh logs'
alias mcp-update='bash /workspace/.devcontainer/scripts/hooks/modules/setup-mcp.sh'
EOF
fi

echo "✅ Shell environment configured"