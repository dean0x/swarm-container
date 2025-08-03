#!/bin/bash
# Interactive script to configure container resources for multiple Claude Code instances

echo "🤖 Claude Code Multi-Instance Configuration"
echo "==========================================="
echo ""

# Check if we're in the right directory
if [ ! -f ".devcontainer/devcontainer.json" ]; then
    echo "❌ Error: This script must be run from your project root directory"
    echo "   (where .devcontainer folder exists)"
    exit 1
fi

# Get current configuration
CURRENT_INSTANCES=${CLAUDE_CODE_INSTANCES:-1}
CURRENT_MEMORY=${CONTAINER_MEMORY:-8g}
CURRENT_CPUS=${CONTAINER_CPUS:-4}

echo "📊 Current configuration:"
echo "   Instances: $CURRENT_INSTANCES"
echo "   Memory: $CURRENT_MEMORY"
echo "   CPUs: $CURRENT_CPUS"
echo ""

# Prompt for number of instances
read -p "How many Claude Code instances do you want to run? [1-100]: " INSTANCES

# Validate input
if ! [[ "$INSTANCES" =~ ^[0-9]+$ ]] || [ "$INSTANCES" -lt 1 ] || [ "$INSTANCES" -gt 100 ]; then
    echo "❌ Invalid input. Please enter a number between 1 and 100."
    exit 1
fi

# Calculate resources
echo ""
echo "🧮 Calculating optimal resources..."
echo ""

# Run the calculation script
source .devcontainer/scripts/hooks/calculate-resources.sh $INSTANCES

# Ask if user wants to update .env
echo ""
read -p "Would you like to update your .env file with these settings? [y/N]: " UPDATE_ENV

if [[ "$UPDATE_ENV" =~ ^[Yy]$ ]]; then
    # Check which .env file to update
    if [ -f ".env" ]; then
        ENV_FILE=".env"
    else
        echo ""
        echo "No .env file found. Which preset would you like to use?"
        echo "1) Development (default)"
        echo "2) Enterprise"
        echo "3) Paranoid"
        read -p "Select preset [1-3]: " PRESET_CHOICE
        
        case $PRESET_CHOICE in
            2)
                cp .devcontainer/.env.enterprise .env
                ENV_FILE=".env"
                ;;
            3)
                cp .devcontainer/.env.paranoid .env
                ENV_FILE=".env"
                ;;
            *)
                cp .devcontainer/.env.development .env
                ENV_FILE=".env"
                ;;
        esac
    fi
    
    # Update or add the configuration
    if grep -q "CLAUDE_CODE_INSTANCES=" "$ENV_FILE"; then
        # Update existing
        sed -i.bak "s/CLAUDE_CODE_INSTANCES=.*/CLAUDE_CODE_INSTANCES=$INSTANCES/" "$ENV_FILE"
    else
        # Add new
        echo "" >> "$ENV_FILE"
        echo "# Multi-instance configuration" >> "$ENV_FILE"
        echo "CLAUDE_CODE_INSTANCES=$INSTANCES" >> "$ENV_FILE"
    fi
    
    # Update memory and CPU settings
    if grep -q "CONTAINER_MEMORY=" "$ENV_FILE"; then
        sed -i.bak "s/CONTAINER_MEMORY=.*/CONTAINER_MEMORY=$RECOMMENDED_MEMORY/" "$ENV_FILE"
    else
        echo "CONTAINER_MEMORY=$RECOMMENDED_MEMORY" >> "$ENV_FILE"
    fi
    
    if grep -q "CONTAINER_CPUS=" "$ENV_FILE"; then
        sed -i.bak "s/CONTAINER_CPUS=.*/CONTAINER_CPUS=$RECOMMENDED_CPUS/" "$ENV_FILE"
    else
        echo "CONTAINER_CPUS=$RECOMMENDED_CPUS" >> "$ENV_FILE"
    fi
    
    # Clean up backup
    rm -f "${ENV_FILE}.bak"
    
    echo ""
    echo "✅ Configuration updated in $ENV_FILE"
    echo ""
    echo "🔄 Next steps:"
    echo "   1. Rebuild your container in VS Code"
    echo "   2. Use tmux/screen to manage multiple instances"
    echo "   3. Monitor resource usage with 'htop'"
else
    echo ""
    echo "ℹ️  To apply these settings manually, add to your .env file:"
    echo ""
    echo "CLAUDE_CODE_INSTANCES=$INSTANCES"
    echo "CONTAINER_MEMORY=$RECOMMENDED_MEMORY"
    echo "CONTAINER_CPUS=$RECOMMENDED_CPUS"
fi

echo ""
echo "✨ Configuration complete!"