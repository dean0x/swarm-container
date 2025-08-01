# Advanced Fly.io Scripts

These scripts provide granular control over Fly.io deployments for advanced users.

## 🚀 Main Scripts

For most users, use the main deployment scripts:
- `../fly-setup.sh` - Initial setup and dependency installation
- `../fly-deploy.sh` - Primary deployment and management tool

## 📚 Advanced Scripts

### Deployment & Management
- `fly-deploy-all.sh` - Original all-in-one deployment script
- `fly-manage.sh` - Advanced container management
- `fly-update.sh` - Update deployed containers

### Cost Management
- `fly-cost-monitor.sh` - Detailed cost analysis
- `fly-usage-tracker.sh` - Track usage over time
- `fly-budget-alert.sh` - Set up budget alerts

### SSH & Access
- `fly-ssh-setup.sh` - Manual SSH configuration
- `fly-ssh-connect.sh` - Direct SSH connection helper
- `fly-ssh-monitor.sh` - Monitor SSH access
- `fly-vscode-ssh-config.sh` - Generate VS Code SSH config

### Maintenance
- `fly-cleanup.sh` - Clean up specific resources
- `fly-list-resources.sh` - List all Fly.io resources
- `fly-volume-setup.sh` - Manual volume management
- `fly-volume-backup.sh` - Backup persistent volumes
- `fly-status.sh` - Detailed status information

### Security
- `fly-security-audit.sh` - Security audit of deployment
- `fly-quick-fix.sh` - Common issue fixes

### MCP
- `fly-mcp-setup.sh` - Manual MCP server configuration

## Usage

These scripts are for users who need fine-grained control. For example:

```bash
# Monitor costs in detail
./fly-cost-monitor.sh my-app

# Set up budget alerts
./fly-budget-alert.sh my-app 10

# Manual SSH setup
./fly-ssh-setup.sh my-app
```

Most users should start with the main `fly-deploy.sh` script, which handles all common tasks automatically.