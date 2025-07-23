#!/bin/bash
# Module: Workspace Setup
# Purpose: Create workspace structure and manage .gitignore

echo "📁 Setting up workspace structure..."

# Ensure we're in the workspace directory
cd /workspace

# Clean up any problematic files from previous runs
if [ -e "claude-flow" ] && [ ! -d "claude-flow" ]; then
    echo "🧹 Cleaning up non-directory claude-flow file..."
    rm -f claude-flow
fi

# Create deps directory for dependencies
echo "📁 Creating deps directory for AI tool dependencies..."
mkdir -p deps

# Clean deps directory to ensure fresh clones
echo "🧹 Cleaning deps directory for fresh installations..."
if [ -d "/workspace/deps" ]; then
    rm -rf /workspace/deps/claude-flow 2>/dev/null || true
    rm -rf /workspace/deps/ruv-FANN 2>/dev/null || true
    echo "✅ Deps directory cleaned"
fi

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

# Set proper permissions for workspace
chown -R node:node /workspace 2>/dev/null || true

echo "✅ Workspace structure configured"