# Fly.io Remote Development Guide

Deploy SwarmContainer to the cloud for remote development from anywhere.

## 🚀 Quick Start (5 minutes)

### 1. First-Time Setup

```bash
./scripts/fly-setup.sh
```

This interactive assistant will:
- ✓ Install flyctl CLI (if needed)
- ✓ Configure SSH keys
- ✓ Set up your Fly.io account
- ✓ Create initial configuration

### 2. Deploy

```bash
# Using configuration file (recommended)
./scripts/fly-deploy.sh deploy

# Or quick deployment with arguments
./scripts/fly-deploy.sh deploy my-app-name iad
```

### 3. Connect

```bash
# SSH directly
ssh node@my-app-name.fly.dev -p 10022

# Or use VS Code Remote-SSH (auto-configured)
```

## 📋 Configuration

### Basic Setup

```bash
cp .env.fly.example .env.fly
# Edit with your preferences
```

Key settings:
- `FLY_APP_NAME`: Unique app identifier
- `FLY_REGION`: Deployment region ([see regions](https://fly.io/docs/reference/regions/))
- `FLY_VM_SIZE`: Machine size (shared-cpu-1x to 8x)
- `FLY_VM_MEMORY`: RAM allocation (256mb to 8gb)
- `AUTO_STOP_MACHINES`: Auto-stop when idle (saves costs)

### Recommended Configurations

| Use Case | VM Size | Memory | Est. Cost/mo |
|----------|---------|--------|--------------|
| Light Dev | shared-cpu-1x | 512mb | $2-5 |
| Standard | shared-cpu-2x | 2gb | $5-10 |
| Heavy Dev | shared-cpu-4x | 4gb | $10-20 |
| Team/Power | shared-cpu-8x | 8gb | $20-40 |

## 🛠️ Management Commands

```bash
# Check status
./scripts/fly-deploy.sh status

# Stop (keeps data)
./scripts/fly-deploy.sh stop

# Start again
./scripts/fly-deploy.sh start

# Destroy (removes everything)
./scripts/fly-deploy.sh destroy

# Interactive management menu
./scripts/fly-manage.sh my-app-name
```

## 💰 Cost Management

### Auto-Stop Configuration
Machines automatically stop after 5 minutes of inactivity:
```toml
# fly.toml
[[services]]
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0
```

### Monitor Costs
```bash
# Check current configuration and estimates
./scripts/fly-cost-monitor.sh your-app-name

# Track actual usage
./scripts/fly-usage-tracker.sh your-app-name report

# Set budget alerts
./scripts/fly-budget-alert.sh your-app-name 15  # $15/month
```

### Typical Monthly Costs
- **Occasional use** (<50hr): $2-5
- **Regular use** (100hr): $5-10
- **Heavy use** (200hr): $10-20
- **Always-on**: $30-60

## 🔧 Advanced Features

#### 1. Initialize Fly.io App

```bash
cd your-swarmcontainer-directory

# Login to Fly.io
flyctl auth login

# Create app (generates unique name)
flyctl launch --generate-name --no-deploy --copy-config

# Or specify name
flyctl launch --name my-swarm-dev --no-deploy --copy-config
```

#### 2. Create Persistent Volumes

```bash
# Run automated setup
./scripts/fly-volume-setup.sh

# Or manually create volumes
flyctl volumes create swarm_workspace --size 20 --region iad
flyctl volumes create swarm_home --size 10 --region iad
```

#### 3. Configure SSH Access

```bash
# Set your SSH public key
./scripts/fly-ssh-setup.sh

# This will:
# - Detect your SSH key
# - Set it as a Fly.io secret
# - Enable SSH access
```

#### 4. Deploy

```bash
flyctl deploy
```

#### 5. Connect

```bash
# Direct SSH
ssh node@your-app-name.fly.dev -p 10022

# Or use helper script
./scripts/fly-ssh-connect.sh
```

## VS Code Remote Development

### Setup

1. Generate SSH config:
   ```bash
   ./scripts/fly-vscode-ssh-config.sh
   ```

2. In VS Code:
   - Install "Remote - SSH" extension
   - Press `Cmd/Ctrl + Shift + P`
   - Select "Remote-SSH: Connect to Host"
   - Choose `fly-your-app-name`

3. Open folder: `/workspace`

### Features
- Full IntelliSense and debugging
- Integrated terminal
- Git integration
- All VS Code extensions

## Configuration Options

### Machine Size

Edit `fly.toml` to adjust resources:

```toml
[[vm]]
  cpu_kind = "shared"     # or "performance"
  cpus = 2                # 1-8 for shared
  memory_mb = 2048        # 256-8192 for shared
```

### Regions

Choose the closest region for best performance:

```bash
# List available regions
flyctl regions list

# Update in fly.toml
primary_region = "lax"  # Los Angeles
# Other options: iad (Virginia), lhr (London), etc.
```

### Auto-Stop Behavior

Control when your container stops to save costs:

```toml
[[services]]
  auto_stop_machines = true      # Stop when idle
  auto_start_machines = true     # Start on connection
  min_machines_running = 0       # Allow full stop
```

## Cost Management

### Pricing (as of 2024)
- **Compute**: ~$0.0000008/s ($2-5/month for shared CPU)
- **Storage**: $0.15/GB/month
- **Stopped**: No compute charges

### Cost Optimization
1. Use auto-stop (default enabled)
2. Choose appropriate machine size
3. Monitor usage: `fly dashboard`

### Example Monthly Costs
- Minimal (1 CPU, 256MB): ~$2/month + storage
- Standard (2 CPU, 2GB): ~$5/month + storage
- Power (4 CPU, 8GB): ~$20/month + storage

## Cost Monitoring and Control

### Monitoring Tools

1. **Cost Monitor**
   ```bash
   ./scripts/fly-cost-monitor.sh your-app-name
   ```
   Shows current configuration and estimated monthly costs.

2. **Usage Tracker**
   ```bash
   # Start tracking
   ./scripts/fly-usage-tracker.sh your-app-name report
   
   # Export data
   ./scripts/fly-usage-tracker.sh your-app-name export
   ```
   Tracks actual runtime and generates cost reports.

3. **Budget Alerts**
   ```bash
   # Set $15/month budget
   ./scripts/fly-budget-alert.sh your-app-name 15
   ```
   Monitors spending and alerts when approaching budget.

### Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| Shared CPU | $2.07/vCPU/month | When running |
| Memory | $0.26/GB/month | When running |
| Storage | $0.15/GB/month | Always charged |
| Stopped | $0 | No compute charges |
| Network | First 100GB free | Then $0.02/GB |

### Optimization Strategies

1. **Auto-Stop Configuration**
   ```toml
   # fly.toml - Aggressive auto-stop
   [[services]]
     auto_stop_machines = true
     auto_start_machines = true  
     min_machines_running = 0
   ```

2. **Right-Size Resources**
   ```bash
   # Development: minimal resources
   flyctl scale vm shared-cpu-1x --memory 512
   
   # Active development: comfortable resources
   flyctl scale vm shared-cpu-2x --memory 2048
   ```

3. **Volume Management**
   ```bash
   # Check usage
   ssh -p 10022 node@app.fly.dev "df -h"
   
   # Clean up
   ssh -p 10022 node@app.fly.dev "npm cache clean --force"
   ```

### Typical Monthly Costs

| Usage Pattern | Est. Cost | Configuration |
|---------------|-----------|---------------|
| Occasional (<50hr) | $2-5 | 1 CPU, 512MB, auto-stop |
| Regular (100hr) | $5-10 | 2 CPU, 2GB, auto-stop |
| Heavy (200hr) | $10-20 | 4 CPU, 4GB, auto-stop |
| Always-on | $30-60 | Varies, no auto-stop |

### Free Tier and Credits

- New accounts often include free credits
- First 3 shared-cpu-1x VMs free (with limitations)
- Check current offers at fly.io/pricing

### Budget Management

1. **Set Spending Limits**
   - Configure in Fly.io dashboard
   - Prevents unexpected charges
   
2. **Regular Reviews**
   ```bash
   # Weekly cost check
   ./scripts/fly-cost-monitor.sh
   
   # Monthly usage report
   ./scripts/fly-usage-tracker.sh your-app report
   ```

3. **Clean Up Unused Apps**
   ```bash
   # List all apps
   flyctl apps list
   
   # Destroy unused
   flyctl apps destroy unused-app-name
   ```

## Advanced Features

### Multiple Environments

Create separate apps for different projects:

```bash
# Create staging environment
flyctl launch --name my-swarm-staging --copy-config

# Create production environment
flyctl launch --name my-swarm-prod --copy-config
```

### Team Collaboration

Share access with team members:

```bash
# Add team member
flyctl apps add-user email@example.com -a your-app-name

# They can then add their SSH key
./scripts/fly-ssh-setup.sh
```

### Backup and Restore

Backup your work:

```bash
# Backup volumes
./scripts/fly-volume-backup.sh your-app-name ./backups

# Restore (manual process)
scp -P 10022 backup.tar.gz node@your-app.fly.dev:/tmp/
ssh -p 10022 node@your-app.fly.dev 'cd / && tar xzf /tmp/backup.tar.gz'
```

## Troubleshooting

### Connection Issues

1. **Check app status**:
   ```bash
   flyctl status -a your-app-name
   ```

2. **View logs**:
   ```bash
   flyctl logs -a your-app-name
   ```

3. **Wake sleeping machine**:
   ```bash
   flyctl machine restart -a your-app-name
   ```

### SSH Key Problems

1. **Verify key is set**:
   ```bash
   flyctl secrets list -a your-app-name
   ```

2. **Re-set SSH key**:
   ```bash
   ./scripts/fly-ssh-setup.sh your-app-name
   ```

### Performance Issues

1. **Check resource usage**:
   ```bash
   flyctl scale show -a your-app-name
   ```

2. **Upgrade machine**:
   ```bash
   flyctl scale vm shared-cpu-2x -a your-app-name
   ```

## Best Practices

1. **Security**
   - Rotate SSH keys periodically
   - Use strong SSH key passphrases
   - Monitor access logs
   - See [Security Best Practices](fly-io-security.md) for detailed guidance

2. **Performance**
   - Choose region close to you
   - Start with minimal resources, scale up as needed
   - Use persistent volumes for important data

3. **Cost**
   - Enable auto-stop for development
   - Monitor usage regularly
   - Clean up unused apps

## FAQ

**Q: Is my code secure on Fly.io?**
A: Yes. Your code is stored on encrypted volumes, SSH access is key-based only, and containers are isolated.

**Q: Can I use custom domains?**
A: Yes, but not recommended for development. Use the provided .fly.dev domain.

**Q: How do I update SwarmContainer?**
A: Pull latest changes locally and run `flyctl deploy` to update the remote container.

**Q: Can multiple people connect simultaneously?**
A: Yes, multiple SSH sessions are supported. Be aware of potential conflicts when editing same files.

## Automation Scripts

### Easy Management
Interactive management menu for your deployed app:
```bash
./scripts/fly-manage.sh my-app-name
```

Options include:
- Start/stop/restart
- View logs and status
- Scale resources up/down
- Create backups
- Connect via SSH

### Quick Updates
Redeploy after pulling latest SwarmContainer changes:
```bash
./scripts/fly-update.sh
```

### Status Overview
Check all your SwarmContainer apps at once:
```bash
./scripts/fly-status.sh
```

## Having Issues?

See our comprehensive [Troubleshooting Guide](fly-io-troubleshooting.md) for solutions to common problems.

Quick diagnostics:
```bash
./scripts/fly-quick-fix.sh
```

## Next Steps

- Explore MCP servers: `claude mcp list`
- Set up your development workflow
- Configure your preferred security preset
- Join the SwarmContainer community for tips and support