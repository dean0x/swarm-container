#!/bin/bash
set -euo pipefail

echo "💾 SwarmContainer Fly.io Volume Setup"
echo "====================================="
echo ""

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: flyctl CLI not found"
    echo "   Install from: https://fly.io/docs/flyctl/installing/"
    exit 1
fi

# Function to create a volume
create_volume() {
    local app_name="$1"
    local volume_name="$2"
    local size_gb="$3"
    local region="$4"
    
    echo "📦 Creating volume: $volume_name (${size_gb}GB)"
    
    # Check if volume already exists
    if flyctl volumes list --app "$app_name" | grep -q "$volume_name"; then
        echo "   ✅ Volume already exists"
        return 0
    fi
    
    # Create the volume
    flyctl volumes create "$volume_name" \
        --app "$app_name" \
        --region "$region" \
        --size "$size_gb" \
        --yes
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Volume created successfully"
    else
        echo "   ❌ Failed to create volume"
        return 1
    fi
}

# Function to list volumes
list_volumes() {
    local app_name="$1"
    
    echo ""
    echo "📋 Current volumes for $app_name:"
    flyctl volumes list --app "$app_name"
}

# Main script
main() {
    local app_name="${1:-}"
    local region="${2:-iad}"  # Default to US East
    
    if [ -z "$app_name" ]; then
        # Try to read from fly.toml
        if [ -f "fly.toml" ]; then
            app_name=$(grep "^app = " fly.toml | cut -d'"' -f2)
            # Try to get region too
            region=$(grep "^primary_region = " fly.toml | cut -d'"' -f2 || echo "iad")
        fi
    fi
    
    if [ -z "$app_name" ]; then
        echo "Usage: $0 <app-name> [region]"
        echo ""
        echo "Regions: iad (US East), lax (US West), lhr (London), etc."
        echo "See: https://fly.io/docs/reference/regions/"
        exit 1
    fi
    
    echo "🎯 Setting up volumes for: $app_name"
    echo "📍 Region: $region"
    echo ""
    
    # Create workspace volume (20GB default)
    create_volume "$app_name" "swarm_workspace" "20" "$region"
    
    # Create home volume (10GB default)
    create_volume "$app_name" "swarm_home" "10" "$region"
    
    # List all volumes
    list_volumes "$app_name"
    
    echo ""
    echo "✅ Volume setup complete!"
    echo ""
    echo "💡 Tips:"
    echo "   - Volumes persist across deployments"
    echo "   - Data is replicated within the region"
    echo "   - Resize with: fly volumes extend <volume-id> --size <new-size>"
}

main "$@"