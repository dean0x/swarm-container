# Task 002: Create SSH Server Stage

## Objective
Add a new `remote` stage to the Dockerfile that includes SSH server configuration for Fly.io deployment.

## Prerequisites
- [ ] Task 001 completed: Multi-stage Dockerfile structure exists

## Workflow

### 1. Prerequisites Check
- Verify Dockerfile has `base` and `local` stages
- Ensure Docker builds work with current stages

### 2. Implementation

#### Step 2.1: Add Remote Stage
Add the following after the `local` stage:

```dockerfile
# Remote development stage for Fly.io
FROM base AS remote

# Install SSH server
RUN apt-get update && apt-get install -y \
    openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd

# Configure SSH for security
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers node" >> /etc/ssh/sshd_config

# Create .ssh directory for node user
RUN mkdir -p /home/node/.ssh && \
    chown -R node:node /home/node/.ssh && \
    chmod 700 /home/node/.ssh

# Will be overridden by fly-entrypoint.sh
COPY --chown=node:node fly-entrypoint.sh /fly-entrypoint.sh
RUN chmod +x /fly-entrypoint.sh

# Switch to node user
USER node
WORKDIR /workspace

# SSH runs on port 22
EXPOSE 22

ENTRYPOINT ["/fly-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
```

#### Step 2.2: Create Placeholder Entrypoint
Create a temporary `fly-entrypoint.sh` for testing:

```bash
#!/bin/bash
echo "Fly.io entrypoint - placeholder for testing"
exec "$@"
```

### 3. Testing

#### Test 3.1: Build Remote Stage
```bash
docker build --target remote -t swarmcontainer:remote .
```

#### Test 3.2: Verify SSH Installation
```bash
docker run --rm swarmcontainer:remote which sshd
# Should output: /usr/sbin/sshd
```

#### Test 3.3: Check SSH Config
```bash
docker run --rm swarmcontainer:remote grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
```

#### Test 3.4: Ensure Local Stage Unaffected
```bash
docker build --target local -t swarmcontainer:local .
# Open in VS Code and verify functionality
```

### 4. Documentation
- Add comments explaining SSH configuration choices
- Document security decisions (no root, no passwords)

### 5. Completion Criteria
- [ ] Remote stage builds successfully
- [ ] SSH server is installed and configured
- [ ] Security settings are applied (no root, no passwords)
- [ ] Local stage remains unchanged
- [ ] Placeholder entrypoint exists

## Security Considerations

1. **No Root Login**: Prevents root access even with valid keys
2. **No Password Auth**: Only SSH keys allowed
3. **Explicit User Allow**: Only 'node' user can SSH
4. **Minimal Package**: Only openssh-server installed

## Notes
- The actual fly-entrypoint.sh will be implemented in Task 003
- Using 'node' user aligns with devcontainer base image
- Port 22 is standard but Fly.io will map it to a custom port