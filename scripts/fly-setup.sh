#!/bin/bash
# SwarmContainer Fly.io Initial Setup Script
# Handles dependency installation and initial configuration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# OS Detection
OS="$(uname -s)"
ARCH="$(uname -m)"

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        SwarmContainer Fly.io Setup Assistant                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
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

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_flyctl() {
    print_info "Installing Fly.io CLI (flyctl)..."
    
    case "$OS" in
        Darwin)
            # macOS
            if command -v brew &> /dev/null; then
                brew install flyctl
            else
                curl -L https://fly.io/install.sh | sh
            fi
            ;;
        Linux)
            curl -L https://fly.io/install.sh | sh
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_info "Please install flyctl manually: https://fly.io/docs/flyctl/installing/"
            return 1
            ;;
    esac
    
    # Add to PATH if installed to home directory
    if [ -d "$HOME/.fly" ]; then
        echo "" >> "$HOME/.bashrc"
        echo "# Fly.io CLI" >> "$HOME/.bashrc"
        echo 'export FLYCTL_INSTALL="$HOME/.fly"' >> "$HOME/.bashrc"
        echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
        
        if [ -f "$HOME/.zshrc" ]; then
            echo "" >> "$HOME/.zshrc"
            echo "# Fly.io CLI" >> "$HOME/.zshrc"
            echo 'export FLYCTL_INSTALL="$HOME/.fly"' >> "$HOME/.zshrc"
            echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"' >> "$HOME/.zshrc"
        fi
        
        export FLYCTL_INSTALL="$HOME/.fly"
        export PATH="$FLYCTL_INSTALL/bin:$PATH"
    fi
}

install_dependencies() {
    local pkg_manager=$(detect_package_manager)
    local missing_deps=()
    
    # Check what's missing
    command -v git &> /dev/null || missing_deps+=("git")
    command -v docker &> /dev/null || missing_deps+=("docker")
    command -v jq &> /dev/null || missing_deps+=("jq")
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        return 0
    fi
    
    print_info "Installing missing dependencies: ${missing_deps[*]}"
    
    case "$pkg_manager" in
        apt)
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
            ;;
        brew)
            brew install "${missing_deps[@]}"
            ;;
        yum|dnf)
            sudo $pkg_manager install -y "${missing_deps[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${missing_deps[@]}"
            ;;
        *)
            print_warning "Please install manually: ${missing_deps[*]}"
            return 1
            ;;
    esac
}

setup_ssh_key() {
    if [ -f "$HOME/.ssh/id_rsa.pub" ] || [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        print_success "SSH key found"
        return 0
    fi
    
    print_info "No SSH key found. Would you like to generate one?"
    read -p "Generate SSH key? (y/N): " generate
    
    if [[ "$generate" =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519 -C "swarmcontainer@fly.io" -f "$HOME/.ssh/id_ed25519" -N ""
        print_success "SSH key generated"
    else
        print_warning "SSH key required for remote access"
    fi
}

setup_fly_account() {
    if flyctl auth whoami &> /dev/null; then
        local user=$(flyctl auth whoami)
        print_success "Already logged in as: $user"
        return 0
    fi
    
    print_info "Please log in to your Fly.io account"
    print_info "Don't have an account? Sign up at https://fly.io"
    echo
    
    flyctl auth login
}

create_initial_config() {
    local config_file=".env.fly"
    
    if [ -f "$config_file" ]; then
        print_info "Configuration file already exists"
        return 0
    fi
    
    print_info "Creating initial configuration..."
    
    # Get user inputs
    read -p "App name (lowercase, hyphens only): " app_name
    read -p "Region (default: iad): " region
    read -p "VM Size (default: shared-cpu-1x): " vm_size
    read -p "Memory (default: 1gb): " memory
    
    # Set defaults
    region=${region:-iad}
    vm_size=${vm_size:-shared-cpu-1x}
    memory=${memory:-1gb}
    
    # Create config
    cat > "$config_file" << EOF
# SwarmContainer Fly.io Configuration
# Generated by setup script

FLY_APP_NAME=$app_name
FLY_REGION=$region
FLY_VM_SIZE=$vm_size
FLY_VM_MEMORY=$memory
FLY_VOLUME_SIZE=30

# Security and environment
SECURITY_PRESET=development
NODE_ENV=development

# Cost controls
AUTO_STOP_MACHINES=true
MIN_MACHINES_RUNNING=0
AUTO_START_MACHINES=true

# SSH key (leave empty to use ~/.ssh/id_*.pub)
SSH_PUBLIC_KEY=

# Features
ENABLE_MCP_SERVERS=true
GENERATE_VSCODE_CONFIG=true
EOF
    
    print_success "Configuration created: $config_file"
}

check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running or not accessible"
        print_info "Please start Docker and ensure your user has access"
        
        if [ "$OS" = "Linux" ]; then
            print_info "You may need to run: sudo usermod -aG docker $USER"
            print_info "Then log out and back in"
        fi
        
        return 1
    fi
    
    print_success "Docker is running"
}

main() {
    print_header
    
    # Step 1: Check/install dependencies
    print_info "Checking dependencies..."
    
    # Install flyctl if missing
    if ! command -v flyctl &> /dev/null; then
        install_flyctl
    else
        print_success "flyctl is installed"
    fi
    
    # Install other dependencies
    install_dependencies
    
    # Step 2: Check Docker
    check_docker || exit 1
    
    # Step 3: Setup SSH
    echo
    print_info "Checking SSH configuration..."
    setup_ssh_key
    
    # Step 4: Fly.io account
    echo
    print_info "Checking Fly.io account..."
    setup_fly_account
    
    # Step 5: Create initial config
    echo
    create_initial_config
    
    # Summary
    echo
    print_success "Setup complete!"
    echo
    echo "Next steps:"
    echo "  1. Review configuration: cat .env.fly"
    echo "  2. Deploy: ./scripts/fly-deploy.sh deploy"
    echo "  3. Connect: ssh node@<app-name>.fly.dev -p 10022"
    echo
    echo "Useful commands:"
    echo "  ./scripts/fly-deploy.sh help     - Show all commands"
    echo "  ./scripts/fly-deploy.sh status   - Check deployment status"
    echo "  ./scripts/fly-deploy.sh destroy  - Remove deployment"
}

# Handle arguments
case "${1:-}" in
    --check)
        # Just check dependencies
        print_info "Checking dependencies..."
        command -v flyctl &> /dev/null && echo "✓ flyctl" || echo "✗ flyctl"
        command -v git &> /dev/null && echo "✓ git" || echo "✗ git"
        command -v docker &> /dev/null && echo "✓ docker" || echo "✗ docker"
        command -v jq &> /dev/null && echo "✓ jq" || echo "✗ jq"
        docker info &> /dev/null && echo "✓ docker daemon" || echo "✗ docker daemon"
        [ -f "$HOME/.ssh/id_rsa.pub" ] || [ -f "$HOME/.ssh/id_ed25519.pub" ] && echo "✓ ssh key" || echo "✗ ssh key"
        flyctl auth whoami &> /dev/null && echo "✓ fly.io auth" || echo "✗ fly.io auth"
        ;;
    *)
        main
        ;;
esac