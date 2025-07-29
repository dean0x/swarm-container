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

## Cost Monitoring

```bash
# Check current costs
./scripts/fly-cost-monitor.sh

# Track usage over time
./scripts/fly-usage-tracker.sh app-name report

# Set budget alert ($10/month)
./scripts/fly-budget-alert.sh app-name 10
```

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