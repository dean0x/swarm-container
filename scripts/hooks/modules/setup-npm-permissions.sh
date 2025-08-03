#!/bin/bash
# Setup npm permissions for global package updates

echo "🔧 Setting up npm global package permissions..."

# Create a wrapper script for npm global updates
sudo tee /usr/local/bin/npm-global-update > /dev/null << 'EOF'
#!/bin/bash
# Wrapper script to allow npm global updates with proper permissions

# Only allow specific safe npm commands
if [[ "$1" == "update" || "$1" == "install" || "$1" == "upgrade" ]] && [[ "$2" == "-g" || "$3" == "-g" ]]; then
    # Check if updating claude-code specifically
    if [[ "$*" == *"@anthropic-ai/claude-code"* ]] || [[ "$*" == *"-g"* && "$#" -eq 2 ]]; then
        echo "🔄 Running npm global update with elevated permissions..."
        sudo npm "$@"
    else
        echo "❌ This wrapper only allows updating @anthropic-ai/claude-code globally"
        echo "   For other packages, please update the Dockerfile"
        exit 1
    fi
else
    echo "❌ Invalid command. Use: npm-global-update update -g @anthropic-ai/claude-code"
    exit 1
fi
EOF

# Make the wrapper executable
sudo chmod +x /usr/local/bin/npm-global-update

# Add sudoers rule to allow node user to run npm for specific packages without password
# This is very restrictive - only allows npm update/install commands
echo "node ALL=(ALL) NOPASSWD: /usr/bin/npm update -g @anthropic-ai/claude-code*, /usr/bin/npm install -g @anthropic-ai/claude-code*" | sudo tee /etc/sudoers.d/npm-claude-updates > /dev/null

# Ensure proper permissions on sudoers file
sudo chmod 440 /etc/sudoers.d/npm-claude-updates

# Create an alias for convenience
echo "" >> ~/.bashrc
echo "# Alias for updating Claude Code" >> ~/.bashrc
echo "alias update-claude='npm-global-update update -g @anthropic-ai/claude-code'" >> ~/.bashrc

# Also add to zshrc if it exists
if [ -f ~/.zshrc ]; then
    echo "" >> ~/.zshrc
    echo "# Alias for updating Claude Code" >> ~/.zshrc
    echo "alias update-claude='npm-global-update update -g @anthropic-ai/claude-code'" >> ~/.zshrc
fi

echo "✅ npm permissions configured"
echo "   Use 'update-claude' or 'npm-global-update update -g @anthropic-ai/claude-code'"