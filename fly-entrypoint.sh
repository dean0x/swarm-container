#!/bin/bash
set -euo pipefail

echo "🚀 Initializing SwarmContainer on Fly.io..."

# Ensure SSH host keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    sudo ssh-keygen -A
fi

# Setup SSH authorized keys from environment
if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p ~/.ssh
    
    # Handle multiple keys (newline separated)
    echo "$SSH_AUTHORIZED_KEYS" | while IFS= read -r key; do
        if [ -n "$key" ]; then
            echo "$key" >> ~/.ssh/authorized_keys
        fi
    done
    
    # Remove duplicates and empty lines
    sort -u ~/.ssh/authorized_keys | grep -v "^$" > ~/.ssh/authorized_keys.tmp
    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
    
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    
    # Count keys
    key_count=$(grep -c "^ssh-" ~/.ssh/authorized_keys || true)
    echo "✅ SSH keys configured ($key_count keys)"
else
    echo "⚠️  Warning: No SSH_AUTHORIZED_KEYS provided"
    echo "   You won't be able to SSH into this container"
fi

# Security logging
echo "🔒 Setting up security logging..."

# Log SSH connections
echo "#!/bin/bash" > /tmp/ssh-login-notify.sh
echo 'echo "[$(date)] SSH Login: $USER from $SSH_CLIENT" >> /workspace/.ssh-access.log' >> /tmp/ssh-login-notify.sh
chmod +x /tmp/ssh-login-notify.sh

# Add to profile (works for both interactive and non-interactive)
echo "/tmp/ssh-login-notify.sh" >> ~/.profile

# Create log file with proper permissions
touch /workspace/.ssh-access.log
chmod 660 /workspace/.ssh-access.log

echo "✅ Security logging configured"

# Enhanced workspace setup
echo "🗂️  Setting up persistent volumes..."

# Initialize workspace
if [ ! -d /workspace ]; then
    echo "Creating workspace directory..."
    sudo mkdir -p /workspace
    sudo chown node:node /workspace
fi

# Check if this is first run (no .devcontainer in workspace)
if [ ! -d /workspace/.devcontainer ] && [ -d /.devcontainer ]; then
    echo "📋 First run detected - copying SwarmContainer files..."
    cp -r /.devcontainer /workspace/
    echo "✅ SwarmContainer files copied to persistent volume"
fi

# Initialize home directory structure
if [ ! -f ~/.bashrc ]; then
    echo "Setting up user environment..."
    cp /etc/skel/.bashrc ~/
    cp /etc/skel/.profile ~/
fi

# Create standard directories
mkdir -p ~/projects
mkdir -p ~/.config
mkdir -p ~/.local/share

# Set volume permissions
echo "🔒 Setting volume permissions..."
sudo chown -R node:node /workspace || true
sudo chown -R node:node /home/node || true

echo "✅ Volumes initialized"

# Initialize the environment (similar to postCreate but for runtime)
echo "Setting up development environment..."

# Source Node.js memory settings if they exist
if [ -f /workspace/.devcontainer/scripts/hooks/set-node-memory.sh ]; then
    source /workspace/.devcontainer/scripts/hooks/set-node-memory.sh
fi

# Set some useful environment variables
export DEVCONTAINER=true
export NODE_ENV=development
export REMOTE_CONTAINERS=true

# Create a marker file to indicate Fly.io environment
touch ~/.fly-environment

# Initialize MCP if config exists
if [ -f /workspace/scripts/hooks/modules/setup-mcp.sh ]; then
    echo "🔌 Initializing MCP servers..."
    cd /workspace
    bash scripts/hooks/modules/setup-mcp.sh || echo "⚠️  MCP setup failed - can be run later"
fi

# Ensure Claude config directory exists
mkdir -p ~/.claude

# If API key is provided via secrets, export it
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    export ANTHROPIC_API_KEY
    echo "✅ API key configured from secrets"
fi

echo "✅ SwarmContainer ready on Fly.io!"
echo ""
echo "📡 SSH Connection Info:"
echo "   Host: ${FLY_APP_NAME:-<your-app>}.fly.dev"
echo "   Port: 10022"
echo "   User: node"
echo ""

# Start SSH daemon
echo "Starting SSH daemon..."
exec "$@"