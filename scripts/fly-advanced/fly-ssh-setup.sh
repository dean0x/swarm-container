#!/bin/bash
set -euo pipefail

echo "🔐 SwarmContainer Fly.io SSH Key Setup"
echo "======================================"
echo ""

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: flyctl CLI not found"
    echo "   Install from: https://fly.io/docs/flyctl/installing/"
    exit 1
fi

# Function to read SSH key
read_ssh_key() {
    local key_path="${1:-$HOME/.ssh/id_rsa.pub}"
    
    if [ ! -f "$key_path" ]; then
        # Try alternative paths
        for alt_path in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub"; do
            if [ -f "$alt_path" ]; then
                key_path="$alt_path"
                break
            fi
        done
    fi
    
    if [ ! -f "$key_path" ]; then
        echo "❌ No SSH public key found"
        echo "   Please generate one with: ssh-keygen -t ed25519"
        return 1
    fi
    
    echo "📍 Using SSH key: $key_path"
    cat "$key_path"
}

# Function to set SSH key in Fly secrets
set_fly_secret() {
    local app_name="$1"
    local ssh_key="$2"
    
    echo ""
    echo "🚀 Setting SSH key for app: $app_name"
    
    # Set the secret
    echo "$ssh_key" | flyctl secrets set SSH_AUTHORIZED_KEYS=- --app "$app_name"
    
    if [ $? -eq 0 ]; then
        echo "✅ SSH key successfully set!"
        echo ""
        echo "📡 You can now connect with:"
        echo "   ssh node@${app_name}.fly.dev -p 10022"
    else
        echo "❌ Failed to set SSH key"
        return 1
    fi
}

# Main script
main() {
    # Get app name from fly.toml or command line
    local app_name="${1:-}"
    
    if [ -z "$app_name" ]; then
        # Try to read from fly.toml
        if [ -f "fly.toml" ]; then
            app_name=$(grep "^app = " fly.toml | cut -d'"' -f2)
        fi
    fi
    
    if [ -z "$app_name" ]; then
        echo "Usage: $0 [app-name]"
        echo ""
        echo "Or ensure fly.toml exists with app name"
        exit 1
    fi
    
    # Get SSH key
    echo "🔍 Looking for SSH public key..."
    ssh_key=$(read_ssh_key)
    
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Confirm before setting
    echo ""
    echo "📋 Summary:"
    echo "   App: $app_name"
    echo "   Key: $(echo "$ssh_key" | cut -d' ' -f3)"
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_fly_secret "$app_name" "$ssh_key"
    else
        echo "❌ Cancelled"
        exit 1
    fi
}

main "$@"