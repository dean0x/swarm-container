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