# Task 005: Implement SSH Key Handling

## Objective
Implement secure SSH key management for Fly.io deployment using Fly secrets and environment variables.

## Prerequisites
- [ ] Task 004 completed: fly.toml configuration exists

## Workflow

### 1. Prerequisites Check
- Verify fly-entrypoint.sh handles SSH_AUTHORIZED_KEYS environment variable
- Ensure fly.toml is properly configured

### 2. Implementation

#### Step 2.1: Create SSH Key Setup Script
Create `scripts/fly-ssh-setup.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🔐 SwarmContainer Fly.io SSH Key Setup"
echo "======================================"
echo ""

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: flyctl CLI not found"
    echo "   Install from: https://fly.io/docs/flyctl/installing/"
    exit 1
fi

# Function to read SSH key
read_ssh_key() {
    local key_path="${1:-$HOME/.ssh/id_rsa.pub}"
    
    if [ ! -f "$key_path" ]; then
        # Try alternative paths
        for alt_path in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub"; do
            if [ -f "$alt_path" ]; then
                key_path="$alt_path"
                break
            fi
        done
    fi
    
    if [ ! -f "$key_path" ]; then
        echo "❌ No SSH public key found"
        echo "   Please generate one with: ssh-keygen -t ed25519"
        return 1
    fi
    
    echo "📍 Using SSH key: $key_path"
    cat "$key_path"
}

# Function to set SSH key in Fly secrets
set_fly_secret() {
    local app_name="$1"
    local ssh_key="$2"
    
    echo ""
    echo "🚀 Setting SSH key for app: $app_name"
    
    # Set the secret
    echo "$ssh_key" | flyctl secrets set SSH_AUTHORIZED_KEYS=- --app "$app_name"
    
    if [ $? -eq 0 ]; then
        echo "✅ SSH key successfully set!"
        echo ""
        echo "📡 You can now connect with:"
        echo "   ssh node@${app_name}.fly.dev -p 10022"
    else
        echo "❌ Failed to set SSH key"
        return 1
    fi
}

# Main script
main() {
    # Get app name from fly.toml or command line
    local app_name="${1:-}"
    
    if [ -z "$app_name" ]; then
        # Try to read from fly.toml
        if [ -f "fly.toml" ]; then
            app_name=$(grep "^app = " fly.toml | cut -d'"' -f2)
        fi
    fi
    
    if [ -z "$app_name" ]; then
        echo "Usage: $0 [app-name]"
        echo ""
        echo "Or ensure fly.toml exists with app name"
        exit 1
    fi
    
    # Get SSH key
    echo "🔍 Looking for SSH public key..."
    ssh_key=$(read_ssh_key)
    
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Confirm before setting
    echo ""
    echo "📋 Summary:"
    echo "   App: $app_name"
    echo "   Key: $(echo "$ssh_key" | cut -d' ' -f3)"
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_fly_secret "$app_name" "$ssh_key"
    else
        echo "❌ Cancelled"
        exit 1
    fi
}

main "$@"
```

#### Step 2.2: Create SSH Connection Helper
Create `scripts/fly-ssh-connect.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Get app name from fly.toml or command line
app_name="${1:-}"

if [ -z "$app_name" ]; then
    if [ -f "fly.toml" ]; then
        app_name=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$app_name" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

echo "🔌 Connecting to SwarmContainer on Fly.io..."
echo "   App: $app_name"
echo ""

# SSH with common options
ssh -o "StrictHostKeyChecking=accept-new" \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -p 10022 \
    node@${app_name}.fly.dev
```

#### Step 2.3: Update fly-entrypoint.sh for Multiple Keys
Enhance the SSH key handling in `fly-entrypoint.sh`:

```bash
# Enhanced SSH key setup section
if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p ~/.ssh
    
    # Handle multiple keys (newline separated)
    echo "$SSH_AUTHORIZED_KEYS" | while IFS= read -r key; do
        if [ -n "$key" ]; then
            echo "$key" >> ~/.ssh/authorized_keys
        fi
    done
    
    # Remove duplicates and empty lines
    sort -u ~/.ssh/authorized_keys | grep -v "^$" > ~/.ssh/authorized_keys.tmp
    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
    
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    
    # Count keys
    key_count=$(grep -c "^ssh-" ~/.ssh/authorized_keys || true)
    echo "✅ SSH keys configured ($key_count keys)"
fi
```

### 3. Testing

#### Test 3.1: Script Validation
```bash
# Make executable
chmod +x scripts/fly-ssh-setup.sh scripts/fly-ssh-connect.sh

# Check syntax
bash -n scripts/fly-ssh-setup.sh
bash -n scripts/fly-ssh-connect.sh
```

#### Test 3.2: Key Reading Test
```bash
# Test key detection
./scripts/fly-ssh-setup.sh test-app
# Should detect and display your SSH key
```

### 4. Documentation

#### Step 4.1: Document Usage
Add to documentation:

```markdown
## Setting Up SSH Access

1. Set your SSH key:
   ```bash
   ./scripts/fly-ssh-setup.sh your-app-name
   ```

2. Connect via SSH:
   ```bash
   ./scripts/fly-ssh-connect.sh your-app-name
   # Or manually:
   ssh node@your-app-name.fly.dev -p 10022
   ```

3. Use with VS Code:
   - Install Remote-SSH extension
   - Add host: `node@your-app-name.fly.dev:10022`
```

### 5. Completion Criteria
- [ ] SSH key setup script created and tested
- [ ] SSH connection helper created
- [ ] fly-entrypoint.sh handles multiple keys
- [ ] Scripts are executable
- [ ] Documentation updated
- [ ] Security best practices followed

## Security Considerations

1. **Secrets Management**: 
   - Keys stored in Fly secrets (encrypted)
   - Never committed to repository
   - Transmitted securely to container

2. **Key Rotation**:
   - Easy to update via `fly secrets set`
   - Old keys immediately invalidated

3. **Access Control**:
   - Each deployment has unique keys
   - No shared credentials

## Troubleshooting

Common issues:
1. **No SSH key found**: Generate with `ssh-keygen -t ed25519`
2. **Permission denied**: Run setup script to update key
3. **Connection timeout**: Check app is running with `fly status`

## Notes
- Fly secrets are encrypted at rest
- Environment variables are injected at runtime
- Keys can be managed via Fly dashboard or CLI