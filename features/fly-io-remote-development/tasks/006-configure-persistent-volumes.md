# Task 006: Configure Persistent Volumes

## Objective
Set up and configure Fly.io persistent volumes for workspace and user data persistence.

## Prerequisites
- [ ] Task 004 completed: fly.toml has volume mount definitions

## Workflow

### 1. Prerequisites Check
- Verify fly.toml includes mount configurations
- Ensure fly-entrypoint.sh handles workspace directory

### 2. Implementation

#### Step 2.1: Create Volume Setup Script
Create `scripts/fly-volume-setup.sh`:

```bash
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
```

#### Step 2.2: Update fly-entrypoint.sh for Volume Initialization
Enhance volume handling in `fly-entrypoint.sh`:

```bash
# Enhanced workspace setup
echo "🗂️  Setting up persistent volumes..."

# Initialize workspace
if [ ! -d /workspace ]; then
    echo "Creating workspace directory..."
    sudo mkdir -p /workspace
    sudo chown node:node /workspace
fi

# Check if this is first run (no .devcontainer in workspace)
if [ ! -d /workspace/.devcontainer ] && [ -d /.devcontainer ]; then
    echo "📋 First run detected - copying SwarmContainer files..."
    cp -r /.devcontainer /workspace/
    echo "✅ SwarmContainer files copied to persistent volume"
fi

# Initialize home directory structure
if [ ! -f ~/.bashrc ]; then
    echo "Setting up user environment..."
    cp /etc/skel/.bashrc ~/
    cp /etc/skel/.profile ~/
fi

# Create standard directories
mkdir -p ~/projects
mkdir -p ~/.config
mkdir -p ~/.local/share

# Set volume permissions
echo "🔒 Setting volume permissions..."
sudo chown -R node:node /workspace || true
sudo chown -R node:node /home/node || true

echo "✅ Volumes initialized"
```

#### Step 2.3: Create Volume Backup Script
Create `scripts/fly-volume-backup.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "💾 SwarmContainer Volume Backup"
echo "=============================="

app_name="${1:-}"
backup_dir="${2:-./backups}"

if [ -z "$app_name" ]; then
    echo "Usage: $0 <app-name> [backup-dir]"
    exit 1
fi

# Create backup directory
mkdir -p "$backup_dir"
timestamp=$(date +%Y%m%d_%H%M%S)

echo "📦 Creating backup..."
echo "   App: $app_name"
echo "   Timestamp: $timestamp"

# SSH into container and create tarball
ssh -p 10022 node@${app_name}.fly.dev \
    "cd / && tar czf - workspace home/node" \
    > "$backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"

if [ $? -eq 0 ]; then
    echo "✅ Backup created: $backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"
    
    # Show backup size
    ls -lh "$backup_dir/swarmcontainer_${app_name}_${timestamp}.tar.gz"
else
    echo "❌ Backup failed"
    exit 1
fi
```

### 3. Testing

#### Test 3.1: Script Validation
```bash
chmod +x scripts/fly-volume-*.sh
bash -n scripts/fly-volume-setup.sh
bash -n scripts/fly-volume-backup.sh
```

#### Test 3.2: Volume Commands
Test flyctl volume commands:
```bash
# List volume commands
flyctl volumes --help

# Test volume creation (dry run)
flyctl volumes create test --region iad --size 1 --app test-app --dry-run
```

### 4. Documentation

Add volume management section:

```markdown
## Volume Management

### Initial Setup
Create persistent volumes:
```bash
./scripts/fly-volume-setup.sh your-app-name
```

### Volume Layout
- `/workspace` (20GB): Your code and projects
- `/home/node` (10GB): User settings, configs, SSH keys

### Backup Your Data
```bash
./scripts/fly-volume-backup.sh your-app-name ./backups
```

### Resize Volumes
```bash
# List volumes to get ID
fly volumes list -a your-app-name

# Extend volume
fly volumes extend <volume-id> --size 30
```
```

### 5. Completion Criteria
- [ ] Volume setup script created
- [ ] fly-entrypoint.sh handles first-run initialization
- [ ] Backup script available
- [ ] Documentation complete
- [ ] Scripts are executable
- [ ] Volume permissions handled correctly

## Volume Configuration

### Sizes
- **Workspace**: 20GB default (code, projects, dependencies)
- **Home**: 10GB default (configs, caches, tools)

### Persistence
- Data survives container restarts
- Data survives deployments
- Data survives app deletion (volumes persist separately)

### Performance
- NVMe SSD storage
- Low latency within same region
- Automatic snapshots

## Cost Implications
- Storage: $0.15/GB/month
- 30GB default = $4.50/month
- Only charged for allocated size

## Troubleshooting

### Permission Issues
```bash
# Fix in container
sudo chown -R node:node /workspace
sudo chown -R node:node /home/node
```

### Volume Full
```bash
# Check usage
ssh node@app.fly.dev -p 10022 "df -h"

# Clean up
ssh node@app.fly.dev -p 10022 "du -sh /workspace/* | sort -hr"
```

### Data Recovery
- Volumes have automatic snapshots
- Contact Fly.io support for recovery options

## Notes
- Volumes are region-specific
- Cannot move volumes between regions
- Consider backup strategy for important data