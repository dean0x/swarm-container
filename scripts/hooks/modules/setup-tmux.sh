#!/bin/bash
# Module: Tmux Setup
# Purpose: Configure tmux plugins and helper scripts

echo "🔧 Setting up tmux environment..."

# Install tmux plugins if not already installed
if [ -f ~/.tmux.conf ] && [ -d ~/.tmux/plugins/tpm ]; then
    echo "🔧 Installing tmux plugins..."
    ~/.tmux/plugins/tpm/bin/install_plugins || echo "TPM plugins installation completed"
    echo "✅ Tmux plugins installed"
else
    echo "⚠️  Tmux configuration not found, skipping plugin installation"
fi

# Copy tmux helper script to PATH
if [ -f /workspace/.devcontainer/scripts/tmux-6pane.sh ]; then
    # Try sudo first, fall back to user bin if it fails
    if sudo cp /workspace/.devcontainer/scripts/tmux-6pane.sh /usr/local/bin/tmux-6pane 2>/dev/null; then
        sudo chmod +x /usr/local/bin/tmux-6pane 2>/dev/null
        echo "✅ tmux-6pane helper script installed to /usr/local/bin"
    else
        # Fallback to user's bin directory
        mkdir -p ~/bin
        cp /workspace/.devcontainer/scripts/tmux-6pane.sh ~/bin/tmux-6pane
        chmod +x ~/bin/tmux-6pane
        
        # Add to PATH if not already there
        if ! echo "$PATH" | grep -q "$HOME/bin"; then
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
        fi
        
        echo "✅ tmux-6pane helper script installed to ~/bin"
        echo "   Note: You may need to run 'source ~/.zshrc' or start a new shell"
    fi
else
    echo "⚠️  tmux-6pane.sh not found at /workspace/.devcontainer/scripts/tmux-6pane.sh"
fi

echo "✅ Tmux environment configured"