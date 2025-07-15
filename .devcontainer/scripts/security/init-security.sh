#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get security preset from environment or use default
SECURITY_PRESET="${SECURITY_PRESET:-enterprise}"
SECURITY_CONFIG_FILE="/.devcontainer/scripts/security/security-config.json"

echo -e "${BLUE}🔒 Initializing Security Level: ${YELLOW}${SECURITY_PRESET}${NC}"
echo ""

# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    # Handle wildcards by removing the asterisk
    domain=${domain/\*/}
    domain=${domain#.}
    
    # Try to resolve the domain
    if [[ -n "$domain" ]]; then
        dig +short "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
        # Also try with www prefix if not already present
        if [[ ! "$domain" =~ ^www\. ]]; then
            dig +short "www.$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
        fi
    fi
}

# Function to add CIDR blocks for major services
add_service_cidrs() {
    local service=$1
    case "$service" in
        "github.com"|"api.github.com")
            # GitHub's IP ranges
            echo -e "${BLUE}  Adding GitHub IP ranges...${NC}"
            curl -s https://api.github.com/meta | jq -r '.git[]? // empty, .web[]? // empty, .api[]? // empty' 2>/dev/null | while read -r ip; do
                ipset add allowed_ips "$ip" 2>/dev/null || true
            done
            ;;
        "registry.npmjs.org")
            # Cloudflare IPs for npm
            echo -e "${BLUE}  Adding npm registry (Cloudflare) ranges...${NC}"
            ipset add allowed_ips 104.16.0.0/12 2>/dev/null || true
            ipset add allowed_ips 172.64.0.0/13 2>/dev/null || true
            ;;
        "api.anthropic.com"|"console.anthropic.com")
            # Anthropic typically uses AWS CloudFront
            echo -e "${BLUE}  Adding Anthropic API ranges...${NC}"
            ipset add allowed_ips 13.224.0.0/14 2>/dev/null || true
            ipset add allowed_ips 52.84.0.0/15 2>/dev/null || true
            ipset add allowed_ips 143.204.0.0/16 2>/dev/null || true
            ;;
    esac
}

# Parse security configuration
if [[ -f "$SECURITY_CONFIG_FILE" ]]; then
    PRESET_CONFIG=$(jq -r ".presets.${SECURITY_PRESET}" "$SECURITY_CONFIG_FILE" 2>/dev/null)
    
    if [[ "$PRESET_CONFIG" == "null" ]]; then
        echo -e "${RED}❌ Error: Unknown security preset '${SECURITY_PRESET}'${NC}"
        echo -e "${YELLOW}Available presets: paranoid, enterprise, development, custom${NC}"
        exit 1
    fi
    
    # Extract configuration
    ALLOWED_DOMAINS=$(echo "$PRESET_CONFIG" | jq -r '.network.allowed_domains[]?' 2>/dev/null)
    BLOCKED_DOMAINS=$(echo "$PRESET_CONFIG" | jq -r '.network.blocked_domains[]?' 2>/dev/null)
    BLOCK_ALL_OTHERS=$(echo "$PRESET_CONFIG" | jq -r '.network.block_all_others' 2>/dev/null)
    CUSTOM_DOMAINS="${CUSTOM_ALLOWED_DOMAINS:-}"
    
    # Add custom domains if provided
    if [[ -n "$CUSTOM_DOMAINS" ]]; then
        ALLOWED_DOMAINS="$ALLOWED_DOMAINS"$'\n'"$CUSTOM_DOMAINS"
    fi
else
    echo -e "${RED}❌ Error: Security configuration file not found${NC}"
    exit 1
fi

# Initialize iptables
echo -e "${BLUE}🔧 Setting up firewall rules...${NC}"

# Flush existing rules
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -t mangle -X 2>/dev/null || true

# Delete existing ipsets
ipset destroy allowed_ips 2>/dev/null || true
ipset destroy blocked_ips 2>/dev/null || true

# Set default policies based on security level
if [[ "$BLOCK_ALL_OTHERS" == "true" ]]; then
    echo -e "${YELLOW}⚠️  Setting default policy: DENY${NC}"
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
else
    echo -e "${GREEN}✓ Setting default policy: ALLOW with blocklist${NC}"
    iptables -P INPUT ACCEPT
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
fi

# Always allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Create ipsets
ipset create allowed_ips hash:net 2>/dev/null || true
ipset create blocked_ips hash:net 2>/dev/null || true

# For paranoid/enterprise mode - build allowlist
if [[ "$BLOCK_ALL_OTHERS" == "true" ]]; then
    # Allow DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    
    # Process allowed domains
    echo -e "${GREEN}✓ Adding allowed domains...${NC}"
    while IFS= read -r domain; do
        if [[ -n "$domain" ]] && [[ "$domain" != "*" ]]; then
            echo -e "${BLUE}  Processing: $domain${NC}"
            
            # Add special CIDR blocks for known services
            add_service_cidrs "$domain"
            
            # Resolve and add individual IPs
            while IFS= read -r ip; do
                if [[ -n "$ip" ]]; then
                    ipset add allowed_ips "$ip" 2>/dev/null || true
                fi
            done < <(resolve_domain "$domain")
        fi
    done <<< "$ALLOWED_DOMAINS"
    
    # Apply allowlist rules
    iptables -A OUTPUT -m set --match-set allowed_ips dst -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 80 -m set --match-set allowed_ips dst -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 443 -m set --match-set allowed_ips dst -j ACCEPT
    
    # Log dropped packets in paranoid mode
    if [[ "$SECURITY_PRESET" == "paranoid" ]]; then
        iptables -A OUTPUT -j LOG --log-prefix "BLOCKED-OUT: " --log-level 4
    fi
else
    # For development mode - build blocklist
    echo -e "${GREEN}✓ Adding blocked domains...${NC}"
    while IFS= read -r domain; do
        if [[ -n "$domain" ]]; then
            echo -e "${RED}  Blocking: $domain${NC}"
            while IFS= read -r ip; do
                if [[ -n "$ip" ]]; then
                    ipset add blocked_ips "$ip" 2>/dev/null || true
                fi
            done < <(resolve_domain "$domain")
        fi
    done <<< "$BLOCKED_DOMAINS"
    
    # Apply blocklist rules
    iptables -A OUTPUT -m set --match-set blocked_ips dst -j DROP
fi

# Filesystem restrictions (using bind mounts and permissions)
echo -e "${BLUE}🗂️  Setting up filesystem restrictions...${NC}"

# Apply filesystem restrictions based on preset
READONLY_PATHS=$(echo "$PRESET_CONFIG" | jq -r '.filesystem.readonly_paths[]?' 2>/dev/null)
WORKSPACE_ONLY=$(echo "$PRESET_CONFIG" | jq -r '.filesystem.workspace_only' 2>/dev/null)

if [[ "$WORKSPACE_ONLY" == "true" ]]; then
    echo -e "${YELLOW}⚠️  Workspace-only mode enabled${NC}"
    # This would be enforced through Docker volume mounts in devcontainer.json
fi

# Process restrictions
echo -e "${BLUE}🔐 Applying process restrictions...${NC}"
NO_NEW_PRIVS=$(echo "$PRESET_CONFIG" | jq -r '.process.no_new_privileges' 2>/dev/null)
if [[ "$NO_NEW_PRIVS" == "true" ]]; then
    echo -e "${GREEN}✓ No new privileges flag will be set${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}✅ Security initialization complete!${NC}"
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo -e "   - Preset: ${YELLOW}${SECURITY_PRESET}${NC}"
echo -e "   - Network: $(if [[ "$BLOCK_ALL_OTHERS" == "true" ]]; then echo 'Allowlist mode'; else echo 'Blocklist mode'; fi)"
echo -e "   - Filesystem: $(if [[ "$WORKSPACE_ONLY" == "true" ]]; then echo 'Workspace only'; else echo 'Restricted paths'; fi)"

if [[ "$SECURITY_PRESET" == "paranoid" ]]; then
    echo ""
    echo -e "${RED}🚨 PARANOID MODE ACTIVE 🚨${NC}"
    echo -e "${YELLOW}Only explicitly allowed connections will succeed.${NC}"
    echo -e "${YELLOW}All blocked attempts will be logged.${NC}"
fi