#!/bin/bash
# Modular postCreate.sh - orchestrates setup modules
# Don't use set -e to allow the script to continue even if some commands fail
set +e

echo "🚀 Setting up Claude Flow development environment..."

# Define the modules directory
# Use absolute path from workspace
MODULES_DIR="/workspace/.devcontainer/scripts/hooks/modules"

# Function to run a module with error handling
run_module() {
    local module_name=$1
    local module_path="$MODULES_DIR/$module_name"
    
    if [ -f "$module_path" ]; then
        echo ""
        echo "▶️  Running module: $module_name"
        bash "$module_path"
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            echo "⚠️  Module $module_name exited with code $exit_code (continuing...)"
        fi
    else
        echo "❌ Module not found: $module_path"
    fi
}

# Run setup modules in order
run_module "setup-permissions.sh"    # Set permissions first
run_module "init-npm.sh"            # Configure NPM
run_module "init-claude-code.sh"    # Initialize Claude Code
run_module "setup-workspace.sh"     # Setup workspace structure
# run_module "clone-dependencies.sh"  # Clone repositories
# run_module "init-claude-flow.sh"    # Initialize Claude Flow
run_module "setup-shell.sh"         # Configure shell environment
run_module "setup-tmux.sh"          # Setup tmux

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Set your ANTHROPIC_API_KEY environment variable (or use /login command)"
echo "   2. Run 'claude --dangerously-skip-permissions' to activate Claude Code"
echo "      (If no API key is set, use the /login command when prompted)"
echo "   3. Run 'npx claude-flow@alpha hive-mind wizard' to start using Claude Flow"
echo ""
echo "💡 Quick tip: Press ↑ arrow for command history"
echo ""
echo "📚 Documentation:"
echo "   - Claude Code: https://claude.ai/code"
# echo "   - Claude Flow: https://github.com/ruvnet/claude-flow"

# Always exit successfully to prevent container startup issues
exit 0