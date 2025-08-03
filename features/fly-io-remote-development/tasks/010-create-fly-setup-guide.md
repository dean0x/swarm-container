# Task 010: Create Fly Setup Guide

## Objective
Create comprehensive user documentation for setting up and using SwarmContainer on Fly.io.

## Prerequisites
- [ ] Tasks 001-009 completed: All implementation and testing done

## Workflow

### 1. Prerequisites Check
- All technical implementation complete
- All test scripts working
- Helper scripts created

### 2. Implementation

#### Step 2.1: Create Main Setup Guide
Create `docs/fly-io-setup.md`:

```markdown
# SwarmContainer on Fly.io Setup Guide

Deploy your SwarmContainer development environment to the cloud with Fly.io for remote access from anywhere.

## Prerequisites

1. **Fly.io Account**: Sign up at [fly.io](https://fly.io)
2. **Fly CLI**: Install from [fly.io/docs/flyctl/installing](https://fly.io/docs/flyctl/installing/)
3. **SSH Key**: Generate if needed: `ssh-keygen -t ed25519`
4. **SwarmContainer**: Clone or add as submodule

## Quick Start

### 1. Initialize Fly.io App

```bash
cd your-swarmcontainer-directory

# Login to Fly.io
flyctl auth login

# Create app (generates unique name)
flyctl launch --generate-name --no-deploy --copy-config

# Or specify name
flyctl launch --name my-swarm-dev --no-deploy --copy-config
```

### 2. Create Persistent Volumes

```bash
# Run automated setup
./scripts/fly-volume-setup.sh

# Or manually create volumes
flyctl volumes create swarm_workspace --size 20 --region iad
flyctl volumes create swarm_home --size 10 --region iad
```

### 3. Configure SSH Access

```bash
# Set your SSH public key
./scripts/fly-ssh-setup.sh

# This will:
# - Detect your SSH key
# - Set it as a Fly.io secret
# - Enable SSH access
```

### 4. Deploy

```bash
flyctl deploy
```

### 5. Connect

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

## Next Steps

- Explore MCP servers: `claude mcp list`
- Set up your development workflow
- Configure your preferred security preset
- Join the SwarmContainer community for tips and support
```

#### Step 2.2: Create Quick Reference Card
Create `docs/fly-io-quick-reference.md`:

```markdown
# Fly.io Quick Reference

## Essential Commands

### Setup
```bash
flyctl launch --generate-name --no-deploy
./scripts/fly-volume-setup.sh
./scripts/fly-ssh-setup.sh
flyctl deploy
```

### Daily Use
```bash
# Connect
ssh node@app.fly.dev -p 10022

# Check status
flyctl status

# View logs
flyctl logs

# Restart
flyctl machine restart
```

### Management
```bash
# Scale up
flyctl scale vm shared-cpu-4x

# Stop
flyctl machine stop

# Destroy (careful!)
flyctl apps destroy app-name
```

## File Locations

| What | Where |
|------|-------|
| Your code | `/workspace` |
| User settings | `/home/node` |
| SwarmContainer | `/workspace/.devcontainer` |
| Logs | `flyctl logs` |

## Costs

| Size | CPU | RAM | $/month |
|------|-----|-----|---------|
| Micro | 1 | 256MB | ~$2 |
| Small | 1 | 512MB | ~$3 |
| Medium | 2 | 2GB | ~$5 |
| Large | 4 | 8GB | ~$20 |

Plus: $0.15/GB/month for storage

## Troubleshooting

```bash
# Not connecting?
flyctl machine list
flyctl machine restart <id>

# SSH key issues?
./scripts/fly-ssh-setup.sh

# Need more power?
flyctl scale vm performance-2x
```
```

#### Step 2.3: Create Migration Guide
Create `docs/fly-io-migration.md`:

```markdown
# Migrating from Local to Fly.io

## Why Migrate?

- Access your dev environment from any device
- Consistent environment across machines
- More powerful hardware available
- Team collaboration capabilities

## Migration Steps

### 1. Prepare Local Environment

```bash
# Commit all changes
git add -A
git commit -m "Prepare for cloud migration"
git push
```

### 2. Deploy to Fly.io

Follow the [setup guide](fly-io-setup.md) to create your cloud environment.

### 3. Clone Your Projects

```bash
# SSH into Fly.io container
ssh node@your-app.fly.dev -p 10022

# Clone your repositories
cd /workspace
git clone https://github.com/yourusername/yourproject.git
```

### 4. Transfer Local Settings

```bash
# Copy VS Code settings
scp -P 10022 ~/.config/Code/User/settings.json \
  node@your-app.fly.dev:~/.config/Code/User/

# Copy shell configuration
scp -P 10022 ~/.zshrc node@your-app.fly.dev:~/
```

### 5. Install Additional Tools

```bash
# SSH in and install any additional tools
ssh node@your-app.fly.dev -p 10022
npm install -g your-global-packages
```

## Working with Both Environments

### Sync Strategy

1. **Git-based** (Recommended)
   - Commit and push from local
   - Pull on remote
   - Use branches for WIP

2. **Direct sync**
   ```bash
   # Sync folder from local to remote
   rsync -avz -e "ssh -p 10022" \
     ./myproject/ \
     node@app.fly.dev:/workspace/myproject/
   ```

### Environment Detection

Add to your scripts:
```bash
if [ -f ~/.fly-environment ]; then
  echo "Running on Fly.io"
else
  echo "Running locally"
fi
```

## Differences to Note

| Feature | Local | Fly.io |
|---------|-------|---------|
| Performance | Depends on machine | Consistent |
| Storage | Local disk | Persistent volumes |
| Network | Local network | Fly.io network |
| Access | Local only | Anywhere |
| Cost | Hardware cost | ~$5-20/month |

## Tips

1. Use the same Git email/name on both
2. Set up SSH agent forwarding for Git
3. Use VS Code Settings Sync
4. Keep sensitive data in secrets
5. Regular backups of volumes
```

### 3. Testing

#### Test 3.1: Documentation Review
- Follow the guide step-by-step
- Verify all commands work
- Check for clarity and completeness

#### Test 3.2: New User Test
- Have someone unfamiliar follow the guide
- Note any confusion points
- Update based on feedback

### 4. Documentation

Update main README to reference Fly.io option:

```markdown
## Deployment Options

### Local Development (Default)
See [Quick Start](#quick-start) section.

### Cloud Development (Fly.io)
Deploy SwarmContainer to the cloud for remote development.
See [Fly.io Setup Guide](docs/fly-io-setup.md).
```

### 5. Completion Criteria
- [ ] Comprehensive setup guide created
- [ ] Quick reference for daily use
- [ ] Migration guide for existing users
- [ ] All commands tested and working
- [ ] Screenshots/diagrams added (if applicable)
- [ ] Main README updated

## Documentation Standards

### Structure
1. **Clear Headers**: Logical organization
2. **Code Blocks**: Properly formatted with language hints
3. **Tables**: For quick reference information
4. **Links**: To relevant external resources

### Style
- **Concise**: Get to the point quickly
- **Complete**: Don't assume prior knowledge
- **Practical**: Focus on real usage
- **Troubleshooting**: Address common issues

### Maintenance
- Version specific information clearly marked
- Update for Fly.io changes
- Keep commands current
- Regular testing of procedures