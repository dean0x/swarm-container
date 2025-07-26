#!/bin/bash
# Module: Workspace Setup
# Purpose: Create workspace structure and manage .gitignore

echo "📁 Setting up workspace structure..."

# Ensure we're in the workspace directory
cd /workspace


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

# IDE
.vscode/
.idea/
EOF
else
    echo "✓ Existing .gitignore found, preserving it"
fi

# Set proper permissions for workspace
chown -R node:node /workspace 2>/dev/null || true

echo "✅ Workspace structure configured"