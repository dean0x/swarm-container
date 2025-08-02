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

# Add productivity tool aliases and initializations
echo "🚀 Configuring productivity tools..."

# Add productivity tool aliases to bashrc
if ! grep -q "# Productivity Tool Aliases" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Productivity Tool Aliases
alias ls='eza --icons --git'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias tree='eza --tree --icons'
alias cat='bat'
alias top='btm'
alias htop='btm'
alias du='dust'
alias ping='gping'
alias http='http --style=native'
alias help='tldr'
alias lg='lazygit'
alias lzd='lazydocker'

# Initialize zoxide (smarter cd)
eval "$(zoxide init bash)"

# Initialize mcfly (neural network powered shell history)
eval "$(mcfly init bash)"
EOF
fi

# Add productivity tool aliases to zshrc
if ! grep -q "# Productivity Tool Aliases" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# Productivity Tool Aliases
alias ls='eza --icons --git'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias tree='eza --tree --icons'
alias cat='bat'
alias top='btm'
alias htop='btm'
alias du='dust'
alias ping='gping'
alias http='http --style=native'
alias help='tldr'
alias lg='lazygit'
alias lzd='lazydocker'

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"

# Initialize mcfly (neural network powered shell history)
eval "$(mcfly init zsh)"
EOF
fi

# Create config directories
mkdir -p ~/.config/lazygit
mkdir -p ~/.config/bottom

# Create basic lazygit config
if [ ! -f ~/.config/lazygit/config.yml ]; then
    cat > ~/.config/lazygit/config.yml << 'EOF'
gui:
  # Use delta for diffs
  pager: delta
  sidePanelWidth: 0.3333
  theme:
    selectedLineBgColor:
      - reverse
git:
  paging:
    colorArg: always
    useConfig: true
os:
  editCommand: 'code'
  editCommandTemplate: '{{editor}} {{filename}}'
EOF
fi

# Update tldr cache
echo "📚 Updating tldr cache..."
tldr --update 2>/dev/null || true

echo "✅ Shell environment and productivity tools configured"