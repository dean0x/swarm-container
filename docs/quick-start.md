# Quick Start Guide

Get up and running with SwarmContainer in 5 minutes!

## Prerequisites Checklist

- [ ] VS Code installed
- [ ] Docker Desktop running
- [ ] Dev Containers extension installed
- [ ] Either an Anthropic API key OR Claude Pro/Max subscription

## Step 1: Add SwarmContainer to Your Project

```bash
cd your-project
git submodule add https://github.com/dean0x/swarm-container.git .devcontainer
git commit -m "Add swarm-container"
```

## Step 2: Create Environment File

```bash
cp .devcontainer/.env.development .env
```

## Step 3: Open in Container

1. Open VS Code: `code .`
2. When prompted, click **"Reopen in Container"**
3. Wait 3-5 minutes for first-time setup

## Step 4: Start Claude Code

```bash
claude --dangerously-skip-permissions
```

If you don't have an API key set, use `/login` to authenticate via browser.

## That's It! 🎉

You now have Claude Code running in a secure container with:
- Network isolation
- Resource limits
- Modern CLI tools
- MCP server support

## What's Next?

- Try `lg` for visual git management
- Use `z <folder>` to quickly navigate
- Run `help <command>` for simplified docs
- Check `echo $SECURITY_PRESET` to see your security level

## Need Help?

- Run tests: `./.devcontainer/scripts/tests/test-devcontainer.sh`
- Check logs: `docker logs $(docker ps -q -f name=SwarmContainer)`
- See [Troubleshooting Guide](troubleshooting.md)

## Customization

### Change Security Level
```bash
# For sensitive work
cp .devcontainer/.env.paranoid .env

# For corporate environments
cp .devcontainer/.env.enterprise .env
```

### Configure for Multiple Instances
```bash
# Run before opening in VS Code
./.devcontainer/scripts/configure-for-instances.sh
```

### Add Custom Domains (Enterprise/Paranoid modes)
```bash
# Edit .env
CUSTOM_ALLOWED_DOMAINS=api.company.com,npm.company.com
```

## Pro Tips

1. **Update Claude Code**: Run `update-claude` inside the container
2. **Check memory**: `echo $NODE_OPTIONS`
3. **View MCP servers**: `claude mcp list`
4. **Quick commands**: Press ↑ for pre-loaded history