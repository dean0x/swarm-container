#!/bin/bash
set -euo pipefail

echo "🚀 Initializing SwarmContainer on Fly.io..."

# Setup SSH authorized keys from environment
if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p /home/node/.ssh
    
    # Handle multiple keys (newline separated)
    echo "$SSH_AUTHORIZED_KEYS" | while IFS= read -r key; do
        if [ -n "$key" ]; then
            echo "$key" >> /home/node/.ssh/authorized_keys
        fi
    done
    
    # Remove duplicates and empty lines
    sort -u /home/node/.ssh/authorized_keys | grep -v "^$" > /home/node/.ssh/authorized_keys.tmp || true
    mv /home/node/.ssh/authorized_keys.tmp /home/node/.ssh/authorized_keys
    
    chmod 600 /home/node/.ssh/authorized_keys
    chmod 700 /home/node/.ssh
    chown -R node:node /home/node/.ssh
    
    # Count keys
    key_count=$(grep -c "^ssh-" /home/node/.ssh/authorized_keys || echo "0")
    echo "✅ SSH keys configured ($key_count keys)"
else
    echo "⚠️  Warning: No SSH_AUTHORIZED_KEYS provided"
    echo "   You won't be able to SSH into this container"
fi

# Enhanced workspace setup with single volume
echo "🗂️  Setting up persistent volume..."

# Create symlinks for persistent data
# /data is our single persistent volume
if [ -d /data ]; then
    # Create directory structure in persistent volume
    mkdir -p /data/workspace
    mkdir -p /data/home
    mkdir -p /data/ssh
    
    # Store SSH host keys persistently
    if [ -d /data/ssh ] && [ "$(ls -A /etc/ssh/ssh_host_* 2>/dev/null)" ]; then
        echo "💾 Backing up SSH host keys to persistent storage..."
        cp /etc/ssh/ssh_host_* /data/ssh/ 2>/dev/null || true
    elif [ -d /data/ssh ] && [ "$(ls -A /data/ssh/ssh_host_* 2>/dev/null)" ]; then
        echo "📂 Restoring SSH host keys from persistent storage..."
        cp /data/ssh/ssh_host_* /etc/ssh/
        chmod 600 /etc/ssh/ssh_host_*_key
        chmod 644 /etc/ssh/ssh_host_*_key.pub
    fi
    
    # Symlink workspace to persistent location
    if [ ! -L /workspace ] && [ ! -d /workspace ]; then
        ln -s /data/workspace /workspace
    elif [ -d /workspace ] && [ ! -L /workspace ]; then
        # Move existing workspace content to persistent volume
        mv /workspace/* /data/workspace/ 2>/dev/null || true
        rm -rf /workspace
        ln -s /data/workspace /workspace
    fi
    
    # Ensure workspace ownership
    chown -R node:node /data/workspace
    
    # Link home subdirectories to persistent storage
    for dir in .ssh .config .cache .local .npm .claude; do
        if [ ! -d /data/home/$dir ]; then
            mkdir -p /data/home/$dir
        fi
        if [ ! -L /home/node/$dir ]; then
            rm -rf /home/node/$dir 2>/dev/null || true
            ln -s /data/home/$dir /home/node/$dir
            chown -R node:node /data/home/$dir
        fi
    done
    
    echo "✅ Persistent volume configured"
else
    echo "⚠️  Warning: /data volume not mounted, using ephemeral storage"
    mkdir -p /workspace
    chown node:node /workspace
fi

# Check if this is first run (no .devcontainer in workspace)
if [ ! -d /workspace/.devcontainer ] && [ -d /.devcontainer ]; then
    echo "📋 First run detected - copying SwarmContainer files..."
    cp -r /.devcontainer /workspace/
    echo "✅ SwarmContainer files copied to persistent volume"
fi

# Initialize home directory structure
if [ ! -f /home/node/.bashrc ] && [ -f /etc/skel/.bashrc ]; then
    echo "Setting up user environment..."
    cp /etc/skel/.bashrc /home/node/
    cp /etc/skel/.profile /home/node/
    chown node:node /home/node/.bashrc /home/node/.profile
fi

# Create standard directories
mkdir -p /home/node/projects
chown node:node /home/node/projects

# Set volume permissions
echo "🔒 Setting volume permissions..."
chown -R node:node /workspace || true
chown -R node:node /home/node || true

echo "✅ Volumes initialized"

# Source Node.js memory settings if they exist
if [ -f /workspace/.devcontainer/scripts/hooks/set-node-memory.sh ]; then
    source /workspace/.devcontainer/scripts/hooks/set-node-memory.sh
    # Export for all processes
    echo "export NODE_OPTIONS='$NODE_OPTIONS'" >> /etc/environment
fi

# Set environment variables
echo "DEVCONTAINER=true" >> /etc/environment
echo "NODE_ENV=development" >> /etc/environment
echo "REMOTE_CONTAINERS=true" >> /etc/environment

# Create a marker file to indicate Fly.io environment
touch /home/node/.fly-environment
chown node:node /home/node/.fly-environment

# If API key is provided via secrets, export it
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "export ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY'" >> /etc/environment
    echo "✅ API key configured from secrets"
fi

echo "✅ SwarmContainer ready on Fly.io!"
echo ""
echo "📡 SSH Connection Info:"
echo "   Host: ${FLY_APP_NAME:-<your-app>}.fly.dev"
echo "   Port: 10022"
echo "   User: node"
echo ""