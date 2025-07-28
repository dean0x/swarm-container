# Task 004: Create Fly.toml Configuration

## Objective
Create the `fly.toml` configuration file that defines how SwarmContainer deploys to Fly.io.

## Prerequisites
- [ ] Task 003 completed: fly-entrypoint.sh script exists and works

## Workflow

### 1. Prerequisites Check
- Verify Dockerfile remote stage builds successfully
- Ensure fly-entrypoint.sh is functional

### 2. Implementation

#### Step 2.1: Create fly.toml
Create `fly.toml` in the project root:

```toml
# Fly.io configuration for SwarmContainer Remote Development
app = "swarmcontainer-dev"  # Will be replaced by actual app name
primary_region = "iad"       # Default to US East, user can change

# Build configuration
[build]
  dockerfile = "Dockerfile"
  target = "remote"

# Environment variables
[env]
  # Public environment variables
  NODE_ENV = "development"
  DEVCONTAINER = "true"
  
  # Memory settings (matching local development)
  CONTAINER_MEMORY = "8g"
  CONTAINER_CPUS = "4"
  
  # Security preset for remote development
  SECURITY_PRESET = "development"

# Process groups
[processes]
  app = "/fly-entrypoint.sh /usr/sbin/sshd -D"

# Services configuration
[[services]]
  # SSH service configuration
  processes = ["app"]
  internal_port = 22
  protocol = "tcp"
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

  # Concurrency settings
  [services.concurrency]
    type = "connections"
    hard_limit = 25
    soft_limit = 20

  # Public port mapping
  [[services.ports]]
    port = 10022  # Non-standard SSH port for security

# Persistent storage
[[mounts]]
  # Mount for workspace persistence
  source = "swarm_workspace"
  destination = "/workspace"
  
[[mounts]]
  # Mount for home directory persistence
  source = "swarm_home"
  destination = "/home/node"

# Machine configuration
[experimental]
  # Use Fly Machines v2
  auto_rollback = true

# Health checks
[[services.tcp_checks]]
  interval = "15s"
  timeout = "2s"
  grace_period = "5s"

# Resource allocation
[[vm]]
  # Default to shared CPU for cost efficiency
  cpu_kind = "shared"
  cpus = 2
  memory_mb = 2048
```

#### Step 2.2: Create .dockerignore Update
Add Fly.io specific entries to `.dockerignore`:

```
# Fly.io
fly.toml
.fly/
```

#### Step 2.3: Create fly.toml.example
Create a template for users:

```toml
# Example Fly.io configuration for SwarmContainer
# Copy this to fly.toml and customize

app = "your-app-name"  # Change this to your unique app name
primary_region = "iad" # Change to your preferred region

# Customize machine size based on your needs:
# [[vm]]
#   cpu_kind = "shared"    # or "performance" 
#   cpus = 2               # 1-8 for shared, 1-64 for performance
#   memory_mb = 2048       # 256-8192 for shared, higher for performance

# Rest of configuration remains the same...
```

### 3. Testing

#### Test 3.1: Validate TOML Syntax
```bash
# Install toml-cli if needed
npm install -g @iarna/toml

# Validate syntax
toml < fly.toml > /dev/null && echo "✅ Valid TOML"
```

#### Test 3.2: Validate with Fly CLI
```bash
# Dry run to check configuration
flyctl launch --no-deploy --copy-config=false --config fly.toml
```

### 4. Documentation

#### Step 4.1: Add Comments to fly.toml
Include explanatory comments for each section

#### Step 4.2: Document in README
Add section explaining fly.toml configuration options

### 5. Completion Criteria
- [ ] fly.toml created with all necessary sections
- [ ] SSH service properly configured on port 10022
- [ ] Persistent volumes defined for workspace and home
- [ ] Health checks configured
- [ ] Resource allocation defined
- [ ] Example template provided
- [ ] TOML syntax is valid

## Configuration Decisions

### Port Selection
- Port 10022 chosen to avoid conflicts with standard SSH (22)
- Non-standard port adds minor security benefit

### Persistent Volumes
- `/workspace`: Project files and code
- `/home/node`: User settings, SSH keys, shell history

### Auto-scaling
- `min_machines_running = 0`: Allows complete shutdown when idle
- `auto_stop_machines = true`: Saves costs when not in use
- `auto_start_machines = true`: Wakes on SSH connection

### Resources
- Default: 2 shared CPUs, 2GB RAM (cost-effective)
- Users can customize based on needs

## Cost Implications
With default settings:
- Shared-cpu-2x: ~$5/month when running
- Auto-stop when idle: Pay only for storage
- Storage: $0.15/GB/month per volume

## Security Notes
- Non-standard SSH port (10022)
- No root access configured
- Development security preset (can be changed)