# Task 003: Create Fly Entrypoint Script

## Objective
Create the `fly-entrypoint.sh` script that initializes SSH keys and starts the SSH daemon for Fly.io deployment.

## Prerequisites
- [ ] Task 002 completed: SSH server stage exists in Dockerfile

## Workflow

### 1. Prerequisites Check
- Verify remote stage exists in Dockerfile
- Ensure placeholder fly-entrypoint.sh exists

### 2. Implementation

#### Step 2.1: Create Full Entrypoint Script
Replace the placeholder `fly-entrypoint.sh` with:

```bash
#!/bin/bash
set -euo pipefail

echo "🚀 Initializing SwarmContainer on Fly.io..."

# Ensure SSH host keys exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    sudo ssh-keygen -A
fi

# Setup SSH authorized keys from environment
if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p ~/.ssh
    echo "$SSH_AUTHORIZED_KEYS" > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    echo "✅ SSH keys configured"
else
    echo "⚠️  Warning: No SSH_AUTHORIZED_KEYS provided"
    echo "   You won't be able to SSH into this container"
fi

# Create workspace directory if it doesn't exist
if [ ! -d /workspace ]; then
    echo "Creating workspace directory..."
    sudo mkdir -p /workspace
    sudo chown node:node /workspace
fi

# Initialize the environment (similar to postCreate but for runtime)
echo "Setting up development environment..."

# Source Node.js memory settings if they exist
if [ -f /workspace/.devcontainer/scripts/hooks/set-node-memory.sh ]; then
    source /workspace/.devcontainer/scripts/hooks/set-node-memory.sh
fi

# Set some useful environment variables
export DEVCONTAINER=true
export NODE_ENV=development
export REMOTE_CONTAINERS=true

# Create a marker file to indicate Fly.io environment
touch ~/.fly-environment

echo "✅ SwarmContainer ready on Fly.io!"
echo ""
echo "📡 SSH Connection Info:"
echo "   Host: ${FLY_APP_NAME}.fly.dev"
echo "   Port: 10022"
echo "   User: node"
echo ""

# Start SSH daemon
echo "Starting SSH daemon..."
exec "$@"
```

#### Step 2.2: Update Dockerfile COPY Command
Ensure the Dockerfile properly handles sudo requirements:

```dockerfile
# In the remote stage, modify:
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \  # Add sudo
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd

# Add passwordless sudo for node user
RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

### 3. Testing

#### Test 3.1: Script Syntax
```bash
bash -n fly-entrypoint.sh
# Should produce no output if syntax is correct
```

#### Test 3.2: Test in Docker
```bash
# Build the image
docker build --target remote -t swarmcontainer:remote .

# Test with SSH keys
docker run -it --rm \
  -e SSH_AUTHORIZED_KEYS="ssh-rsa AAAAB3... your-key" \
  -e FLY_APP_NAME="test-app" \
  swarmcontainer:remote \
  /fly-entrypoint.sh echo "Test successful"
```

#### Test 3.3: Verify SSH Key Setup
```bash
docker run -it --rm \
  -e SSH_AUTHORIZED_KEYS="test-key" \
  swarmcontainer:remote \
  /fly-entrypoint.sh bash -c "cat ~/.ssh/authorized_keys"
```

### 4. Documentation
- Add comments explaining each section
- Document environment variables used
- Note security implications

### 5. Completion Criteria
- [ ] Script handles SSH key setup from environment
- [ ] Script creates necessary directories
- [ ] Script provides helpful output
- [ ] Script starts SSH daemon correctly
- [ ] Error handling for missing keys
- [ ] Works with node user permissions

## Environment Variables

The script expects:
- `SSH_AUTHORIZED_KEYS`: Public SSH keys for access (required)
- `FLY_APP_NAME`: Fly.io app name (provided by Fly.io)

## Security Notes
- SSH keys are only stored in memory (via environment)
- Proper permissions set on .ssh directory
- Warning displayed if no keys provided
- Using sudo for system operations only

## Integration Points
- Reuses memory setting script from existing setup
- Sets same environment variables as local development
- Creates marker file for environment detection