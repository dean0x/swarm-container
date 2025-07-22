#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Container Security Initialization${NC}"

# Check if we're running as root (we should be at this point)
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}❌ Error: Entrypoint must run as root${NC}"
    exit 1
fi

# Source environment variables
SECURITY_PRESET="${SECURITY_PRESET:-development}"
echo -e "${BLUE}🔒 Security Level: ${SECURITY_PRESET}${NC}"

# Run security initialization as root
# The script is copied during build to /scripts/security/
if [ -f "/scripts/security/init-security.sh" ]; then
    echo -e "${BLUE}🔧 Applying security rules...${NC}"
    
    # Export environment variables for the security script
    export SECURITY_PRESET="${SECURITY_PRESET}"
    export CUSTOM_ALLOWED_DOMAINS="${CUSTOM_ALLOWED_DOMAINS:-}"
    
    # Run the security initialization
    bash /scripts/security/init-security.sh
    SECURITY_STATUS=$?
    
    if [ $SECURITY_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ Security rules applied successfully${NC}"
    else
        echo -e "${RED}❌ Security initialization failed with code $SECURITY_STATUS${NC}"
        echo -e "${YELLOW}⚠️  Continuing anyway - check logs for details${NC}"
    fi
else
    echo -e "${RED}❌ Security script not found!${NC}"
    echo -e "    Expected at: /scripts/security/init-security.sh"
    echo -e "${YELLOW}⚠️  Container starting without security rules${NC}"
fi

# Create a marker file to indicate security was initialized
echo "$(date): Security initialized with preset: $SECURITY_PRESET" > /var/log/container-security.log

# Set dynamic Node.js memory options based on container memory
if [ -f "/scripts/hooks/set-node-memory.sh" ]; then
    echo -e "${BLUE}🧠 Configuring Node.js memory settings...${NC}"
    source /scripts/hooks/set-node-memory.sh
    # Export for all child processes
    export NODE_OPTIONS
else
    echo -e "${YELLOW}⚠️  Memory configuration script not found, using defaults${NC}"
fi

# Copy git config to node user
if [ -f /root/.gitconfig ]; then
    cp /root/.gitconfig /home/node/.gitconfig
    chown node:node /home/node/.gitconfig
fi

# Now handle the command execution
if [ $# -eq 0 ]; then
    # No command provided, run bash as the specified user
    echo -e "${GREEN}✅ Security initialization complete, starting shell${NC}"
    exec gosu node /bin/bash
else
    # Command provided
    if [ "$1" = "/bin/sh" ] && [ "$2" = "-c" ]; then
        # VS Code command format, execute as node user
        echo -e "${GREEN}✅ Security initialization complete, executing VS Code command${NC}"
        exec gosu node "$@"
    else
        # Other command, execute as-is
        echo -e "${GREEN}✅ Security initialization complete, executing command${NC}"
        exec "$@"
    fi
fi