# Task 014: Add Deployment Scripts

## Objective
Create automation scripts to simplify the Fly.io deployment process and common operations.

## Prerequisites
- [ ] All core functionality implemented and tested
- [ ] Helper scripts working individually

## Workflow

### 1. Prerequisites Check
- Verify all individual scripts work
- Ensure Fly CLI is installed
- Test manual deployment process

### 2. Implementation

#### Step 2.1: Create One-Command Deploy Script
Create `scripts/fly-deploy-all.sh`:

```bash
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
```

#### Step 2.2: Create Update/Redeploy Script
Create `scripts/fly-update.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🔄 SwarmContainer Update & Redeploy"
echo "=================================="
echo ""

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

echo "🎯 Updating: $APP_NAME"
echo ""

# Step 1: Check for local changes
echo "1. Checking for local changes..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Uncommitted changes detected:"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
    fi
fi

# Step 2: Pull latest changes
echo ""
echo "2. Pulling latest SwarmContainer updates..."
git pull || echo "⚠️  Git pull failed - continuing anyway"

# Step 3: Update fly.toml if needed
echo ""
echo "3. Checking fly.toml..."
if [ -f "fly.toml.example" ]; then
    if [ fly.toml.example -nt fly.toml ]; then
        echo "⚠️  fly.toml.example is newer than fly.toml"
        echo "   Consider updating your configuration"
    fi
fi

# Step 4: Deploy
echo ""
echo "4. Deploying updates..."
flyctl deploy --app "$APP_NAME" || {
    echo "❌ Deployment failed"
    exit 1
}

# Step 5: Post-update tasks
echo ""
echo "5. Running post-update tasks..."

# Check if MCP needs update
echo "   Updating MCP configuration..."
./scripts/fly-mcp-setup.sh "$APP_NAME" || echo "   ⚠️  MCP update failed"

echo ""
echo "=================================="
echo "✅ Update complete!"
echo ""
echo "Changes deployed to: $APP_NAME"
echo "Connect: ssh node@${APP_NAME}.fly.dev -p 10022"
```

#### Step 2.3: Create Management Script
Create `scripts/fly-manage.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🎛️  SwarmContainer Fly.io Manager"
echo "================================"
echo ""

APP_NAME="${1:-}"
ACTION="${2:-menu}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [action]"
    echo ""
    echo "Actions:"
    echo "  status    - Show app status"
    echo "  start     - Start the app"
    echo "  stop      - Stop the app"
    echo "  restart   - Restart the app"
    echo "  logs      - Show recent logs"
    echo "  ssh       - Connect via SSH"
    echo "  scale     - Change machine size"
    echo "  backup    - Backup volumes"
    echo "  destroy   - Destroy app (careful!)"
    exit 1
fi

case "$ACTION" in
    menu)
        echo "Select action for: $APP_NAME"
        echo ""
        echo "1) Status"
        echo "2) Start"
        echo "3) Stop"
        echo "4) Restart"
        echo "5) Logs"
        echo "6) SSH"
        echo "7) Scale"
        echo "8) Backup"
        echo "9) Destroy (careful!)"
        echo "0) Exit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) ACTION="status" ;;
            2) ACTION="start" ;;
            3) ACTION="stop" ;;
            4) ACTION="restart" ;;
            5) ACTION="logs" ;;
            6) ACTION="ssh" ;;
            7) ACTION="scale" ;;
            8) ACTION="backup" ;;
            9) ACTION="destroy" ;;
            0) exit 0 ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
        ;;
esac

# Execute action
case "$ACTION" in
    status)
        echo "📊 App Status:"
        flyctl status -a "$APP_NAME"
        echo ""
        echo "💾 Volumes:"
        flyctl volumes list -a "$APP_NAME"
        ;;
        
    start)
        echo "▶️  Starting app..."
        flyctl machine start -a "$APP_NAME"
        ;;
        
    stop)
        echo "⏹️  Stopping app..."
        flyctl machine stop -a "$APP_NAME"
        ;;
        
    restart)
        echo "🔄 Restarting app..."
        flyctl machine restart -a "$APP_NAME"
        ;;
        
    logs)
        echo "📜 Recent logs:"
        flyctl logs -n 100 -a "$APP_NAME"
        ;;
        
    ssh)
        echo "🔌 Connecting via SSH..."
        ssh -p 10022 node@${APP_NAME}.fly.dev
        ;;
        
    scale)
        echo "📏 Current scale:"
        flyctl scale show -a "$APP_NAME"
        echo ""
        echo "Available options:"
        echo "1) shared-cpu-1x (256MB)"
        echo "2) shared-cpu-1x (512MB)"
        echo "3) shared-cpu-2x (2GB)"
        echo "4) shared-cpu-4x (4GB)"
        echo "5) shared-cpu-8x (8GB)"
        echo "6) performance-1x (2GB)"
        echo "7) performance-2x (4GB)"
        echo "8) performance-4x (8GB)"
        echo ""
        read -p "Choice (or 0 to cancel): " scale_choice
        
        case $scale_choice in
            1) flyctl scale vm shared-cpu-1x --memory 256 -a "$APP_NAME" ;;
            2) flyctl scale vm shared-cpu-1x --memory 512 -a "$APP_NAME" ;;
            3) flyctl scale vm shared-cpu-2x -a "$APP_NAME" ;;
            4) flyctl scale vm shared-cpu-4x -a "$APP_NAME" ;;
            5) flyctl scale vm shared-cpu-8x -a "$APP_NAME" ;;
            6) flyctl scale vm performance-1x -a "$APP_NAME" ;;
            7) flyctl scale vm performance-2x -a "$APP_NAME" ;;
            8) flyctl scale vm performance-4x -a "$APP_NAME" ;;
            0) echo "Cancelled" ;;
            *) echo "Invalid choice" ;;
        esac
        ;;
        
    backup)
        echo "💾 Creating backup..."
        ./scripts/fly-volume-backup.sh "$APP_NAME"
        ;;
        
    destroy)
        echo "⚠️  WARNING: This will destroy the app and all data!"
        echo "App to destroy: $APP_NAME"
        echo ""
        read -p "Type the app name to confirm: " confirm
        
        if [ "$confirm" = "$APP_NAME" ]; then
            echo "Destroying app..."
            flyctl apps destroy "$APP_NAME" --yes
            echo "✅ App destroyed"
        else
            echo "❌ Cancelled - names don't match"
        fi
        ;;
        
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
```

#### Step 2.4: Create Quick Status Script
Create `scripts/fly-status.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Quick status overview of all Fly.io SwarmContainer apps

echo "🚀 SwarmContainer Fly.io Status"
echo "=============================="
echo ""

# Get all apps with swarm in name or from fly.toml
if [ -f "fly.toml" ]; then
    DEFAULT_APP=$(grep "^app = " fly.toml | cut -d'"' -f2)
    echo "📱 Default App: $DEFAULT_APP"
    echo ""
fi

echo "📊 All SwarmContainer Apps:"
flyctl apps list | grep -E "(swarm|NAME)" || echo "No apps found"

echo ""
echo "💰 Current Usage:"
flyctl dashboard metrics

echo ""
echo "💡 Management Tips:"
echo "• Detailed status: ./scripts/fly-manage.sh <app-name> status"
echo "• Quick SSH: ./scripts/fly-ssh-connect.sh <app-name>"
echo "• View logs: flyctl logs -a <app-name>"
```

### 3. Testing

#### Test 3.1: Deploy Script
Test full deployment:
```bash
chmod +x scripts/fly-deploy-all.sh
./scripts/fly-deploy-all.sh test-swarm-deploy iad
```

#### Test 3.2: Management Script
```bash
chmod +x scripts/fly-manage.sh
./scripts/fly-manage.sh test-swarm-deploy status
```

#### Test 3.3: Update Script
```bash
chmod +x scripts/fly-update.sh
./scripts/fly-update.sh test-swarm-deploy
```

### 4. Documentation

Add automation section to docs:

```markdown
## Automation Scripts

### One-Command Deployment
Deploy everything with a single command:
```bash
./scripts/fly-deploy-all.sh my-app-name
```

### Easy Management
Interactive management menu:
```bash
./scripts/fly-manage.sh my-app-name
```

### Quick Updates
Redeploy after pulling latest changes:
```bash
./scripts/fly-update.sh
```

### Status Overview
Check all your SwarmContainer apps:
```bash
./scripts/fly-status.sh
```
```

### 5. Completion Criteria
- [ ] One-command deployment works
- [ ] Update script handles common cases
- [ ] Management script covers daily tasks
- [ ] Status script provides overview
- [ ] All scripts are user-friendly
- [ ] Error handling implemented

## Script Design Principles

### User Experience
1. Clear progress indicators
2. Helpful error messages
3. Confirmation for destructive actions
4. Sensible defaults

### Robustness
1. Check prerequisites
2. Handle failures gracefully
3. Provide rollback options
4. Log important actions

### Flexibility
1. Support environment variables
2. Allow skipping steps
3. Work with or without fly.toml
4. Interactive and non-interactive modes