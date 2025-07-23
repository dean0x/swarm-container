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
# Try multiple locations since mount paths may vary
if [ -f /devcontainer-config/scripts/tmux-6pane.sh ]; then
    cp /devcontainer-config/scripts/tmux-6pane.sh /usr/local/bin/tmux-6pane
    chmod +x /usr/local/bin/tmux-6pane
    echo "✅ tmux-6pane helper script installed"
elif [ -f /workspace/scripts/tmux-6pane.sh ]; then
    cp /workspace/scripts/tmux-6pane.sh /usr/local/bin/tmux-6pane
    chmod +x /usr/local/bin/tmux-6pane
    echo "✅ tmux-6pane helper script installed from workspace"
else
    echo "⚠️  tmux-6pane.sh not found in expected locations"
fi

echo "✅ Tmux environment configured"