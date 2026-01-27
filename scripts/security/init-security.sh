#!/bin/bash
set -e

# Source logging library if available
LOGGING_LIB="/scripts/lib/logging.sh"
if [ -f "$LOGGING_LIB" ]; then
    # shellcheck source=/dev/null
    source "$LOGGING_LIB"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
    log_security() { echo "[SECURITY] $1"; }
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get security preset from environment or use default
SECURITY_PRESET="${SECURITY_PRESET:-development}"
SECURITY_CONFIG_FILE="/scripts/security/security-config.json"

echo -e "${BLUE}Initializing Security Level: ${YELLOW}${SECURITY_PRESET}${NC}"
echo ""

# Domain validation function
# Validates that a domain name is properly formatted to prevent injection attacks
# Valid: alphanumeric, dots, hyphens, wildcards (*.example.com)
# Invalid: spaces, special chars, command injection attempts
validate_domain() {
    local domain="$1"

    # Empty domain is invalid
    if [[ -z "$domain" ]]; then
        return 1
    fi

    # Allow wildcard prefix (*.example.com or just *)
    if [[ "$domain" == "*" ]]; then
        return 0
    fi

    # Strip wildcard prefix for validation
    local check_domain="${domain#\*.}"

    # Domain must match: alphanumeric segments separated by dots
    # Each segment: starts/ends with alphanumeric, can contain hyphens in middle
    # Regex breakdown:
    #   ^[a-zA-Z0-9]                         - starts with alphanumeric
    #   ([a-zA-Z0-9-]*[a-zA-Z0-9])?          - optional middle part (alphanumeric or hyphen, ends alphanumeric)
    #   (\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ - repeated dot-separated segments
    if [[ ! "$check_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi

    # Additional security checks - reject if contains suspicious patterns
    # These patterns could indicate command injection attempts
    if [[ "$domain" =~ [\;\|\&\$\`\(\)\{\}\[\]\<\>\"\'\!\#\%\^\=\+\\] ]]; then
        log_security "Rejected suspicious domain pattern" "{\"domain\":\"$domain\"}"
        return 1
    fi

    return 0
}

# Validate and sanitize custom domains
validate_custom_domains() {
    local input="$1"
    local validated=""
    local rejected=""

    # Split on comma or newline
    local IFS=$',\n'
    for domain in $input; do
        # Trim whitespace
        domain=$(echo "$domain" | tr -d '[:space:]')

        if [[ -z "$domain" ]]; then
            continue
        fi

        if validate_domain "$domain"; then
            if [[ -n "$validated" ]]; then
                validated="$validated"$'\n'"$domain"
            else
                validated="$domain"
            fi
        else
            log_error "Invalid domain format rejected" "{\"domain\":\"$domain\"}"
            echo -e "${RED}ERROR: Invalid domain format rejected: $domain${NC}"
            if [[ -n "$rejected" ]]; then
                rejected="$rejected, $domain"
            else
                rejected="$domain"
            fi
        fi
    done

    if [[ -n "$rejected" ]]; then
        echo -e "${YELLOW}WARNING: The following domains were rejected due to invalid format: $rejected${NC}"
    fi

    echo "$validated"
}

# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    # Handle wildcards by removing the asterisk
    domain=${domain/\*/}
    domain=${domain#.}

    # Try to resolve the domain
    if [[ -n "$domain" ]]; then
        local ips
        ips=$(dig +short +time=5 +tries=2 "$domain" 2>&1)
        local dig_status=$?

        if [[ $dig_status -ne 0 ]]; then
            log_warn "DNS resolution failed for $domain" "{\"exit_code\":$dig_status}"
        fi

        # Filter to only IPv4 addresses
        echo "$ips" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true

        # Also try with www prefix if not already present
        if [[ ! "$domain" =~ ^www\. ]]; then
            local www_ips
            www_ips=$(dig +short +time=5 +tries=2 "www.$domain" 2>&1)
            echo "$www_ips" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
        fi
    fi
}

# Function to safely add IP to ipset (handles duplicates gracefully)
safe_ipset_add() {
    local set_name="$1"
    local ip="$2"

    if [[ -z "$ip" ]]; then
        return 0
    fi

    # Validate IP format
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        log_warn "Invalid IP format, skipping" "{\"ip\":\"$ip\"}"
        return 1
    fi

    # Add to ipset - entry already exists is not an error
    if ! ipset add "$set_name" "$ip" 2>/dev/null; then
        # Check if it's a duplicate (expected) vs real error
        if ipset test "$set_name" "$ip" 2>/dev/null; then
            # Already exists, this is fine
            return 0
        else
            log_warn "Failed to add IP to ipset" "{\"set\":\"$set_name\",\"ip\":\"$ip\"}"
            return 1
        fi
    fi
    return 0
}

# Function to add CIDR blocks for major services
# These are static fallbacks that ensure connectivity even when DNS fails
add_service_cidrs() {
    local service=$1
    local added=0

    case "$service" in
        "github.com"|"api.github.com")
            # GitHub's IP ranges - fetch dynamically with static fallback
            echo -e "${BLUE}  Adding GitHub IP ranges...${NC}"
            local github_meta
            github_meta=$(curl -s --connect-timeout 5 https://api.github.com/meta 2>/dev/null)
            if [[ -n "$github_meta" ]]; then
                echo "$github_meta" | jq -r '.git[]? // empty, .web[]? // empty, .api[]? // empty' 2>/dev/null | while read -r ip; do
                    safe_ipset_add allowed_ips "$ip" && ((added++)) || true
                done
            else
                # Static fallback CIDRs for GitHub
                log_warn "Could not fetch GitHub meta, using static fallback CIDRs"
                safe_ipset_add allowed_ips "140.82.112.0/20"
                safe_ipset_add allowed_ips "192.30.252.0/22"
                safe_ipset_add allowed_ips "185.199.108.0/22"
                safe_ipset_add allowed_ips "143.55.64.0/20"
            fi
            ;;
        "registry.npmjs.org")
            # Cloudflare IPs for npm (static - Cloudflare publishes these)
            echo -e "${BLUE}  Adding npm registry (Cloudflare) ranges...${NC}"
            safe_ipset_add allowed_ips "104.16.0.0/12"
            safe_ipset_add allowed_ips "172.64.0.0/13"
            ;;
        "api.anthropic.com"|"console.anthropic.com")
            # Anthropic typically uses AWS CloudFront
            echo -e "${BLUE}  Adding Anthropic API ranges...${NC}"
            safe_ipset_add allowed_ips "13.224.0.0/14"
            safe_ipset_add allowed_ips "52.84.0.0/15"
            safe_ipset_add allowed_ips "143.204.0.0/16"
            safe_ipset_add allowed_ips "99.86.0.0/16"
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

    # Validate and sanitize custom domains before use
    if [[ -n "${CUSTOM_ALLOWED_DOMAINS:-}" ]]; then
        echo -e "${BLUE}Validating custom allowed domains...${NC}"
        VALIDATED_CUSTOM_DOMAINS=$(validate_custom_domains "$CUSTOM_ALLOWED_DOMAINS")
        if [[ -n "$VALIDATED_CUSTOM_DOMAINS" ]]; then
            ALLOWED_DOMAINS="$ALLOWED_DOMAINS"$'\n'"$VALIDATED_CUSTOM_DOMAINS"
            log_info "Custom domains validated and added" "{\"count\":$(echo "$VALIDATED_CUSTOM_DOMAINS" | wc -l | tr -d ' ')}"
        fi
    fi
else
    echo -e "${RED}❌ Error: Security configuration file not found${NC}"
    exit 1
fi

# Initialize iptables
echo -e "${BLUE}Setting up firewall rules...${NC}"

# Check if iptables is available
if ! command -v iptables &>/dev/null; then
    log_error "iptables command not found - firewall rules cannot be applied"
    echo -e "${RED}ERROR: iptables not available${NC}"
    exit 1
fi

# Flush existing rules (errors expected if tables/chains don't exist yet)
log_info "Flushing existing iptables rules"
iptables -F 2>/dev/null || log_info "No filter rules to flush"
iptables -X 2>/dev/null || log_info "No custom filter chains to delete"
iptables -t nat -F 2>/dev/null || log_info "No nat rules to flush"
iptables -t nat -X 2>/dev/null || log_info "No custom nat chains to delete"
iptables -t mangle -F 2>/dev/null || log_info "No mangle rules to flush"
iptables -t mangle -X 2>/dev/null || log_info "No custom mangle chains to delete"

# Check if ipset is available
if ! command -v ipset &>/dev/null; then
    log_error "ipset command not found - IP set based rules cannot be applied"
    echo -e "${RED}ERROR: ipset not available${NC}"
    exit 1
fi

# Delete existing ipsets (errors expected if sets don't exist yet)
ipset destroy allowed_ips 2>/dev/null || log_info "No existing allowed_ips set to destroy"
ipset destroy blocked_ips 2>/dev/null || log_info "No existing blocked_ips set to destroy"

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
if ! ipset create allowed_ips hash:net 2>/dev/null; then
    # Set might already exist, try to verify
    if ipset list allowed_ips &>/dev/null; then
        log_info "allowed_ips ipset already exists, reusing"
    else
        log_error "Failed to create allowed_ips ipset"
        exit 1
    fi
fi

if ! ipset create blocked_ips hash:net 2>/dev/null; then
    # Set might already exist, try to verify
    if ipset list blocked_ips &>/dev/null; then
        log_info "blocked_ips ipset already exists, reusing"
    else
        log_error "Failed to create blocked_ips ipset"
        exit 1
    fi
fi

# For paranoid/enterprise mode - build allowlist
if [[ "$BLOCK_ALL_OTHERS" == "true" ]]; then
    # Allow DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    
    # Process allowed domains
    echo -e "${GREEN}Adding allowed domains...${NC}"
    local domain_count=0
    local ip_count=0
    while IFS= read -r domain; do
        if [[ -n "$domain" ]] && [[ "$domain" != "*" ]]; then
            echo -e "${BLUE}  Processing: $domain${NC}"
            ((domain_count++)) || true

            # Add special CIDR blocks for known services
            add_service_cidrs "$domain"

            # Resolve and add individual IPs
            while IFS= read -r ip; do
                if [[ -n "$ip" ]]; then
                    if safe_ipset_add allowed_ips "$ip"; then
                        ((ip_count++)) || true
                    fi
                fi
            done < <(resolve_domain "$domain")
        fi
    done <<< "$ALLOWED_DOMAINS"
    log_info "Processed allowed domains" "{\"domains\":$domain_count,\"ips_added\":$ip_count}"
    
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
    echo -e "${GREEN}Adding blocked domains...${NC}"
    local blocked_count=0
    local blocked_ip_count=0
    while IFS= read -r domain; do
        if [[ -n "$domain" ]]; then
            echo -e "${RED}  Blocking: $domain${NC}"
            ((blocked_count++)) || true
            while IFS= read -r ip; do
                if [[ -n "$ip" ]]; then
                    if safe_ipset_add blocked_ips "$ip"; then
                        ((blocked_ip_count++)) || true
                    fi
                fi
            done < <(resolve_domain "$domain")
        fi
    done <<< "$BLOCKED_DOMAINS"
    log_info "Processed blocked domains" "{\"domains\":$blocked_count,\"ips_blocked\":$blocked_ip_count}"

    # Apply blocklist rules
    if ! iptables -A OUTPUT -m set --match-set blocked_ips dst -j DROP; then
        log_error "Failed to apply blocklist iptables rule"
        exit 1
    fi
fi

# Filesystem restrictions (using bind mounts and permissions)
echo -e "${BLUE}Setting up filesystem restrictions...${NC}"

# Note: Filesystem restrictions are configured via Docker volume mounts in devcontainer.json
# and runArgs security options. This script only reads the config for display purposes.
READONLY_PATHS=$(echo "$PRESET_CONFIG" | jq -r '.filesystem.readonly_paths[]?' 2>/dev/null)

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
echo -e "   - Filesystem: Restricted paths (via Docker mounts)"

if [[ "$SECURITY_PRESET" == "paranoid" ]]; then
    echo ""
    echo -e "${RED}🚨 PARANOID MODE ACTIVE 🚨${NC}"
    echo -e "${YELLOW}Only explicitly allowed connections will succeed.${NC}"
    echo -e "${YELLOW}All blocked attempts will be logged.${NC}"
fi