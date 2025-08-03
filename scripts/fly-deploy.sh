#!/bin/bash
# SwarmContainer Fly.io Deployment Tool
# A formal deployment interface for SwarmContainer on Fly.io

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default configuration file
CONFIG_FILE="${PROJECT_ROOT}/.env.fly"
EXAMPLE_CONFIG="${PROJECT_ROOT}/.env.fly.example"

# Functions
print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}║          SwarmContainer Fly.io Deployment Tool              ║${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_dependencies() {
    local missing_deps=()
    
    # Check for flyctl
    if ! command -v flyctl &> /dev/null; then
        # Try common installation paths
        if [ -f "$HOME/.fly/bin/flyctl" ]; then
            export PATH="$HOME/.fly/bin:$PATH"
        elif [ -f "/usr/local/bin/flyctl" ]; then
            export PATH="/usr/local/bin:$PATH"
        else
            missing_deps+=("flyctl")
        fi
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo
        echo "Installation instructions:"
        echo "  flyctl: https://fly.io/docs/flyctl/installing/"
        echo "  git: https://git-scm.com/downloads"
        echo "  docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Configuration file not found at $CONFIG_FILE"
        echo
        echo "Would you like to:"
        echo "  1) Create from example configuration"
        echo "  2) Use command-line arguments"
        echo "  3) Exit"
        echo
        read -p "Select option (1-3): " option
        
        case $option in
            1)
                cp "$EXAMPLE_CONFIG" "$CONFIG_FILE"
                print_info "Created $CONFIG_FILE from example"
                print_info "Please edit the configuration and run again"
                exit 0
                ;;
            2)
                return 1
                ;;
            3)
                exit 0
                ;;
            *)
                print_error "Invalid option"
                exit 1
                ;;
        esac
    fi
    
    # Load configuration
    set -a
    source "$CONFIG_FILE"
    set +a
    
    return 0
}

validate_config() {
    local errors=()
    
    # Required fields
    [ -z "${FLY_APP_NAME:-}" ] && errors+=("FLY_APP_NAME is required")
    [ -z "${FLY_REGION:-}" ] && errors+=("FLY_REGION is required")
    
    # Validate app name (lowercase, alphanumeric, hyphens only)
    if [[ ! "${FLY_APP_NAME:-}" =~ ^[a-z0-9-]+$ ]]; then
        errors+=("FLY_APP_NAME must be lowercase alphanumeric with hyphens only")
    fi
    
    # Validate region
    local valid_regions="ams atl bog bom bos cdg den dfw ewr fra gru hkg iad jnb lax lhr mad mia nrt ord otp phx qro scl sea sin sjc syd waw yul yyz"
    if [[ ! " $valid_regions " =~ " ${FLY_REGION:-} " ]]; then
        errors+=("FLY_REGION must be a valid Fly.io region")
    fi
    
    if [ ${#errors[@]} -ne 0 ]; then
        for error in "${errors[@]}"; do
            print_error "$error"
        done
        exit 1
    fi
}

setup_ssh_key() {
    if [ "${SKIP_SSH_SETUP:-false}" == "true" ]; then
        return 0
    fi
    
    local ssh_key="${SSH_PUBLIC_KEY:-}"
    
    # If no key provided, try to find one
    if [ -z "$ssh_key" ]; then
        local key_files=("$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub")
        
        for key_file in "${key_files[@]}"; do
            if [ -f "$key_file" ]; then
                ssh_key=$(cat "$key_file")
                print_info "Using SSH key from $key_file"
                break
            fi
        done
    fi
    
    if [ -z "$ssh_key" ]; then
        print_warning "No SSH key found. You won't be able to SSH into the container."
        echo "Generate one with: ssh-keygen -t rsa -b 4096"
        return 0
    fi
    
    # Set the secret in Fly.io
    echo "$ssh_key" | flyctl secrets set SSH_AUTHORIZED_KEYS=- --app "$FLY_APP_NAME" --stage
}

create_fly_toml() {
    cat > "$PROJECT_ROOT/fly.toml" << EOF
# Auto-generated Fly.io configuration for SwarmContainer
app = "$FLY_APP_NAME"
primary_region = "${PRIMARY_REGION:-$FLY_REGION}"

[build]
  dockerfile = "Dockerfile"
  target = "remote"

[env]
  NODE_ENV = "${NODE_ENV:-development}"
  DEVCONTAINER = "true"
  CONTAINER_MEMORY = "${FLY_VM_MEMORY:-1gb}"
  CONTAINER_CPUS = "${FLY_VM_SIZE##*-}"
  SECURITY_PRESET = "${SECURITY_PRESET:-development}"

[processes]
  app = ""

[[services]]
  processes = ["app"]
  internal_port = 22
  protocol = "tcp"
  auto_stop_machines = ${AUTO_STOP_MACHINES:-true}
  auto_start_machines = ${AUTO_START_MACHINES:-true}
  min_machines_running = ${MIN_MACHINES_RUNNING:-0}

  [services.concurrency]
    type = "connections"
    hard_limit = 25
    soft_limit = 20

  [[services.ports]]
    port = 10022

[[mounts]]
  source = "swarm_data"
  destination = "/data"

[experimental]
  auto_rollback = true

[[services.tcp_checks]]
  interval = "${HEALTH_CHECK_INTERVAL:-15s}"
  timeout = "${HEALTH_CHECK_TIMEOUT:-2s}"
  grace_period = "5s"

[[vm]]
  size = "${FLY_VM_SIZE:-shared-cpu-1x}"
  memory = "${FLY_VM_MEMORY:-1gb}"
EOF
}

deploy() {
    print_header
    
    # Calculate resources if not manually set
    if [ -z "${FLY_VM_MEMORY:-}" ] || [ -z "${FLY_VM_SIZE:-}" ]; then
        # Source the resource calculator
        INSTANCES=${CLAUDE_CODE_INSTANCES:-6}
        source "${SCRIPT_DIR}/hooks/calculate-resources.sh" $INSTANCES >/dev/null 2>&1
        
        # Set defaults if not manually specified
        FLY_VM_MEMORY=${FLY_VM_MEMORY:-$RECOMMENDED_MEMORY}
        
        # Map CPU count to Fly.io VM size
        case ${RECOMMENDED_CPUS} in
            1|2) FLY_VM_SIZE=${FLY_VM_SIZE:-"shared-cpu-2x"} ;;
            3|4) FLY_VM_SIZE=${FLY_VM_SIZE:-"shared-cpu-4x"} ;;
            5|6|7|8) FLY_VM_SIZE=${FLY_VM_SIZE:-"shared-cpu-8x"} ;;
            *) FLY_VM_SIZE=${FLY_VM_SIZE:-"shared-cpu-8x"} ;;
        esac
    fi
    
    # Show configuration
    echo "📋 Deployment Configuration:"
    echo "   App Name: $FLY_APP_NAME"
    echo "   Region: $FLY_REGION"
    echo "   Claude Instances: ${CLAUDE_CODE_INSTANCES:-6}"
    echo "   VM Size: ${FLY_VM_SIZE}"
    echo "   Memory: ${FLY_VM_MEMORY}"
    echo "   Volume: ${FLY_VOLUME_SIZE:-30}GB"
    echo "   Security: ${SECURITY_PRESET:-development}"
    echo
    
    # Confirmation
    if [ "${SKIP_CONFIRMATION:-false}" != "true" ]; then
        read -p "Continue with deployment? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Check if app exists
    if flyctl apps list | grep -q "^$FLY_APP_NAME"; then
        print_warning "App $FLY_APP_NAME already exists"
        echo "Would you like to:"
        echo "  1) Update existing app"
        echo "  2) Destroy and recreate"
        echo "  3) Cancel"
        read -p "Select option (1-3): " option
        
        case $option in
            1)
                ;;
            2)
                print_info "Destroying existing app..."
                flyctl apps destroy "$FLY_APP_NAME" --yes
                sleep 5
                ;;
            3)
                exit 0
                ;;
        esac
    else
        # Create new app
        print_info "Creating Fly.io app..."
        flyctl apps create "$FLY_APP_NAME" --org personal
    fi
    
    # Generate fly.toml
    print_info "Generating fly.toml configuration..."
    create_fly_toml
    
    # Create volumes if not skipping
    if [ "${SKIP_VOLUMES:-false}" != "true" ]; then
        print_info "Setting up persistent volume..."
        
        # Check if volume exists
        if ! flyctl volumes list --app "$FLY_APP_NAME" | grep -q "swarm_data"; then
            flyctl volumes create swarm_data \
                --app "$FLY_APP_NAME" \
                --region "$FLY_REGION" \
                --size "${FLY_VOLUME_SIZE:-30}" \
                --yes
        else
            print_info "Volume already exists"
        fi
    fi
    
    # Setup SSH
    print_info "Configuring SSH access..."
    setup_ssh_key
    
    # Deploy
    print_info "Deploying application..."
    flyctl deploy --app "$FLY_APP_NAME" --ha=false
    
    # Post-deployment
    print_success "Deployment complete!"
    echo
    echo "📊 Application Status:"
    flyctl status --app "$FLY_APP_NAME"
    
    echo
    echo "🔗 Connection Information:"
    echo "   SSH: ssh node@$FLY_APP_NAME.fly.dev -p 10022"
    echo "   Logs: flyctl logs --app $FLY_APP_NAME"
    echo "   Console: flyctl ssh console --app $FLY_APP_NAME"
    echo
    
    # Generate VS Code config if requested
    if [ "${GENERATE_VSCODE_CONFIG:-true}" == "true" ]; then
        generate_vscode_config
    fi
}

generate_vscode_config() {
    local ssh_config="$HOME/.ssh/config.d/fly-$FLY_APP_NAME"
    mkdir -p "$HOME/.ssh/config.d"
    
    cat > "$ssh_config" << EOF
# SwarmContainer on Fly.io
Host $FLY_APP_NAME
    HostName $FLY_APP_NAME.fly.dev
    Port 10022
    User node
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
    
    print_success "VS Code SSH config generated at $ssh_config"
    print_info "Add to ~/.ssh/config: Include ~/.ssh/config.d/*"
}

# Command handling
case "${1:-deploy}" in
    deploy)
        check_dependencies
        if load_config; then
            validate_config
        else
            # Use command line args
            FLY_APP_NAME="${2:-}"
            FLY_REGION="${3:-iad}"
            
            if [ -z "$FLY_APP_NAME" ]; then
                print_error "Usage: $0 deploy <app-name> [region]"
                exit 1
            fi
        fi
        deploy
        ;;
    
    destroy)
        check_dependencies
        FLY_APP_NAME="${2:-}"
        
        if [ -z "$FLY_APP_NAME" ]; then
            if load_config; then
                true
            else
                print_error "Usage: $0 destroy <app-name>"
                exit 1
            fi
        fi
        
        print_warning "This will destroy app: $FLY_APP_NAME"
        read -p "Are you sure? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            flyctl apps destroy "$FLY_APP_NAME" --yes
            print_success "App destroyed"
        fi
        ;;
    
    status)
        check_dependencies
        FLY_APP_NAME="${2:-}"
        
        if [ -z "$FLY_APP_NAME" ]; then
            load_config || true
        fi
        
        if [ -n "$FLY_APP_NAME" ]; then
            flyctl status --app "$FLY_APP_NAME"
        else
            flyctl apps list
        fi
        ;;
    
    config)
        if [ ! -f "$CONFIG_FILE" ]; then
            cp "$EXAMPLE_CONFIG" "$CONFIG_FILE"
            print_success "Created configuration file at $CONFIG_FILE"
        fi
        
        ${EDITOR:-nano} "$CONFIG_FILE"
        ;;
    
    help|--help|-h)
        print_header
        echo "Usage: $0 [command] [options]"
        echo
        echo "Commands:"
        echo "  deploy [app-name] [region]  - Deploy SwarmContainer to Fly.io"
        echo "  destroy [app-name]          - Destroy a deployment"
        echo "  status [app-name]           - Show deployment status"
        echo "  config                      - Edit configuration file"
        echo "  help                        - Show this help message"
        echo
        echo "Configuration:"
        echo "  Create .env.fly from .env.fly.example for persistent configuration"
        echo "  Or use command-line arguments for one-off deployments"
        echo
        echo "Examples:"
        echo "  $0 deploy my-dev-env iad   # Quick deployment"
        echo "  $0 config                  # Setup configuration"
        echo "  $0 deploy                  # Deploy using config file"
        ;;
    
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac