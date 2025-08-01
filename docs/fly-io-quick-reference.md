# Fly.io Quick Reference

## New Deployment System

### Initial Setup (One-time)
```bash
./scripts/fly-setup.sh
```

### Configuration
```bash
# Create config from template
cp .env.fly.example .env.fly

# Edit configuration
./scripts/fly-deploy.sh config
```

### Deployment Commands
```bash
# Deploy using config file
./scripts/fly-deploy.sh deploy

# Quick deploy with args
./scripts/fly-deploy.sh deploy my-app iad

# Check status
./scripts/fly-deploy.sh status

# Destroy deployment
./scripts/fly-deploy.sh destroy
```

### Connection
```bash
# SSH
ssh node@app-name.fly.dev -p 10022

# Fly.io logs
flyctl logs --app app-name

# Fly.io console
flyctl ssh console --app app-name
```

## Configuration Options (.env.fly)

```bash
# Basic settings
FLY_APP_NAME=my-swarm-dev
FLY_REGION=iad
FLY_VM_SIZE=shared-cpu-1x
FLY_VM_MEMORY=1gb

# Cost controls
AUTO_STOP_MACHINES=true
MIN_MACHINES_RUNNING=0

# Features
ENABLE_MCP_SERVERS=true
GENERATE_VSCODE_CONFIG=true
```

## File Locations

| What | Where |
|------|-------|
| Your code | `/workspace` (symlink to `/data/workspace`) |
| User settings | `/home/node` (persistent dirs symlinked) |
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

## Regions

Popular regions:
- `iad` - Virginia, USA (default)
- `lax` - Los Angeles, USA
- `lhr` - London, UK
- `fra` - Frankfurt, Germany
- `nrt` - Tokyo, Japan
- `syd` - Sydney, Australia

Full list: https://fly.io/docs/reference/regions/

## Troubleshooting

```bash
# Check dependency installation
./scripts/fly-setup.sh --check

# View deployment logs
flyctl logs --app app-name

# SSH to debug
flyctl ssh console --app app-name

# Check machine status
flyctl machine list --app app-name

# Restart machine
flyctl machine restart <id> --app app-name
```

## Advanced Scripts

Located in `scripts/fly-advanced/`:
- `fly-cost-monitor.sh` - Detailed cost analysis
- `fly-usage-tracker.sh` - Track usage over time
- `fly-budget-alert.sh` - Set up budget alerts
- `fly-volume-backup.sh` - Backup persistent data
- `fly-security-audit.sh` - Security checks

See [fly-advanced/README.md](../scripts/fly-advanced/README.md) for details.