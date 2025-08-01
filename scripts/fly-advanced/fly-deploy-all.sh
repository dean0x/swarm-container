#!/bin/bash
set -euo pipefail

echo "🚀 SwarmContainer Complete Fly.io Deployment"
echo "==========================================="
echo ""

# Configuration
APP_NAME="${1:-}"
REGION="${2:-iad}"
SKIP_VOLUMES="${SKIP_VOLUMES:-false}"
SKIP_SSH="${SKIP_SSH:-false}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Help text
if [ "$APP_NAME" = "--help" ] || [ "$APP_NAME" = "-h" ]; then
    cat << EOF
Usage: $0 <app-name> [region]

Options:
  app-name    Unique name for your Fly.io app
  region      Deployment region (default: iad)

Environment variables:
  SKIP_VOLUMES=true   Skip volume creation
  SKIP_SSH=true       Skip SSH key setup

Regions: iad (US East), lax (US West), lhr (London), etc.
See: https://fly.io/docs/reference/regions/
EOF
    exit 0
fi

if [ -z "$APP_NAME" ]; then
    echo "Error: App name required"
    echo "Usage: $0 <app-name> [region]"
    exit 1
fi

echo "📋 Deployment Configuration:"
echo "   App Name: $APP_NAME"
echo "   Region: $REGION"
echo "   Skip Volumes: $SKIP_VOLUMES"
echo "   Skip SSH: $SKIP_SSH"
echo ""

# Step 1: Check prerequisites
echo "1️⃣ Checking prerequisites..."
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl not found. Install from: https://fly.io/docs/flyctl/installing/"
    exit 1
fi

if ! flyctl auth whoami &> /dev/null; then
    echo "🔐 Not logged in to Fly.io"
    flyctl auth login
fi

echo -e "${GREEN}✅ Prerequisites satisfied${NC}"

# Step 2: Create or update fly.toml
echo ""
echo "2️⃣ Configuring fly.toml..."
if [ -f "fly.toml" ]; then
    # Update existing
    sed -i.bak "s/^app = .*/app = \"$APP_NAME\"/" fly.toml
    sed -i.bak "s/^primary_region = .*/primary_region = \"$REGION\"/" fly.toml
    echo -e "${GREEN}✅ Updated existing fly.toml${NC}"
else
    echo "❌ fly.toml not found. Creating from template..."
    if [ -f "fly.toml.example" ]; then
        cp fly.toml.example fly.toml
        sed -i.bak "s/your-app-name/$APP_NAME/" fly.toml
        sed -i.bak "s/primary_region = \"iad\"/primary_region = \"$REGION\"/" fly.toml
    else
        echo "❌ No fly.toml or fly.toml.example found"
        exit 1
    fi
fi

# Step 3: Create app
echo ""
echo "3️⃣ Creating Fly.io app..."
if flyctl apps list | grep -q "^$APP_NAME"; then
    echo -e "${YELLOW}⚠️  App already exists${NC}"
else
    flyctl apps create "$APP_NAME" --org personal || {
        echo "❌ Failed to create app"
        exit 1
    }
    echo -e "${GREEN}✅ App created${NC}"
fi

# Step 4: Create volumes
if [ "$SKIP_VOLUMES" != "true" ]; then
    echo ""
    echo "4️⃣ Creating persistent volumes..."
    ./scripts/fly-volume-setup.sh "$APP_NAME" "$REGION" || {
        echo "❌ Volume creation failed"
        exit 1
    }
else
    echo ""
    echo "4️⃣ Skipping volume creation (SKIP_VOLUMES=true)"
fi

# Step 5: Deploy
echo ""
echo "5️⃣ Deploying application..."
flyctl deploy --app "$APP_NAME" || {
    echo "❌ Deployment failed"
    exit 1
}
echo -e "${GREEN}✅ Deployment successful${NC}"

# Step 6: Setup SSH
if [ "$SKIP_SSH" != "true" ]; then
    echo ""
    echo "6️⃣ Setting up SSH access..."
    ./scripts/fly-ssh-setup.sh "$APP_NAME" || {
        echo "❌ SSH setup failed"
        exit 1
    }
else
    echo ""
    echo "6️⃣ Skipping SSH setup (SKIP_SSH=true)"
fi

# Step 7: Post-deployment tasks
echo ""
echo "7️⃣ Running post-deployment tasks..."

# Setup MCP
echo "   Setting up MCP servers..."
./scripts/fly-mcp-setup.sh "$APP_NAME" || echo "   ⚠️  MCP setup failed - can be done later"

# Generate VS Code config
echo "   Generating VS Code SSH config..."
./scripts/fly-vscode-ssh-config.sh "$APP_NAME" || echo "   ⚠️  VS Code config failed"

# Final summary
echo ""
echo "========================================="
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "📡 Connection Information:"
echo "   SSH: ssh node@${APP_NAME}.fly.dev -p 10022"
echo "   VS Code: Use Remote-SSH with 'fly-${APP_NAME}'"
echo ""
echo "📊 Management Commands:"
echo "   Status: flyctl status -a $APP_NAME"
echo "   Logs: flyctl logs -a $APP_NAME"
echo "   Stop: flyctl machine stop -a $APP_NAME"
echo ""
echo "💡 Next Steps:"
echo "1. Connect via SSH or VS Code"
echo "2. Clone your projects in /workspace"
echo "3. Start developing!"
echo ""
echo "Need help? See: docs/fly-io-setup.md"