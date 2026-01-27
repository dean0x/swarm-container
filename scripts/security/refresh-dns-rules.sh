#!/bin/bash
# Refresh DNS-based firewall rules
# Called by cron every 4 hours to update DNS-resolved IP addresses
# Prevents stale firewall rules from blocking legitimate traffic after IP changes

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

SECURITY_CONFIG_FILE="/scripts/security/security-config.json"
REFRESH_LOG="/var/log/dns-refresh.log"

# Static CIDR fallbacks for critical services
# These are added in addition to DNS-resolved IPs to ensure connectivity
# even when DNS is unavailable or returns different IPs
declare -A STATIC_CIDRS
STATIC_CIDRS["github.com"]="140.82.112.0/20 192.30.252.0/22 185.199.108.0/22 143.55.64.0/20"
STATIC_CIDRS["api.github.com"]="140.82.112.0/20 192.30.252.0/22"
STATIC_CIDRS["registry.npmjs.org"]="104.16.0.0/12 172.64.0.0/13"
STATIC_CIDRS["api.anthropic.com"]="13.224.0.0/14 52.84.0.0/15 143.204.0.0/16 99.86.0.0/16"
STATIC_CIDRS["console.anthropic.com"]="13.224.0.0/14 52.84.0.0/15 143.204.0.0/16 99.86.0.0/16"

# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    # Handle wildcards by removing the asterisk
    domain=${domain/\*/}
    domain=${domain#.}

    if [[ -n "$domain" ]]; then
        # Try dig first, fall back to getent
        local ips=""
        ips=$(dig +short +time=5 +tries=2 "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

        if [[ -z "$ips" ]]; then
            # Fallback to getent
            ips=$(getent ahosts "$domain" 2>/dev/null | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u)
        fi

        echo "$ips"

        # Also try with www prefix if not already present
        if [[ ! "$domain" =~ ^www\. ]]; then
            local www_ips
            www_ips=$(dig +short +time=5 +tries=2 "www.$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
            if [[ -n "$www_ips" ]]; then
                echo "$www_ips"
            fi
        fi
    fi
}

# Function to add IP to ipset with error handling
add_to_ipset() {
    local ip="$1"
    local ipset_name="${2:-allowed_ips}"

    # Validate IP/CIDR format
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        log_warn "Invalid IP format, skipping" "{\"ip\":\"$ip\"}"
        return 1
    fi

    # Add to ipset (ignore errors for duplicates)
    if ipset add "$ipset_name" "$ip" 2>/dev/null; then
        return 0
    else
        # Entry might already exist, which is fine
        return 0
    fi
}

# Function to refresh rules for a single domain
refresh_domain() {
    local domain="$1"
    local added=0
    local failed=0

    # Skip empty domains and wildcards
    if [[ -z "$domain" ]] || [[ "$domain" == "*" ]]; then
        return 0
    fi

    log_info "Refreshing DNS rules for domain" "{\"domain\":\"$domain\"}"

    # Add static CIDR fallbacks first (if available for this domain)
    if [[ -n "${STATIC_CIDRS[$domain]}" ]]; then
        for cidr in ${STATIC_CIDRS[$domain]}; do
            if add_to_ipset "$cidr"; then
                ((added++)) || true
            fi
        done
    fi

    # Resolve current DNS and add IPs
    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            if add_to_ipset "$ip"; then
                ((added++)) || true
            else
                ((failed++)) || true
            fi
        fi
    done < <(resolve_domain "$domain")

    log_info "Domain refresh complete" "{\"domain\":\"$domain\",\"added\":$added,\"failed\":$failed}"
    return 0
}

# Main refresh logic
main() {
    log_info "Starting DNS firewall rule refresh"

    # Check if we're in a mode that uses DNS-based rules
    local security_preset="${SECURITY_PRESET:-development}"
    if [[ "$security_preset" == "development" ]]; then
        log_info "Development mode - skipping DNS refresh (not using allowlist)"
        exit 0
    fi

    # Check if ipset is available and configured
    if ! command -v ipset &>/dev/null; then
        log_error "ipset command not available"
        exit 1
    fi

    if ! ipset list allowed_ips &>/dev/null; then
        log_warn "allowed_ips ipset does not exist - security may not be initialized"
        exit 0
    fi

    # Get allowed domains from config
    if [[ ! -f "$SECURITY_CONFIG_FILE" ]]; then
        log_error "Security config file not found" "{\"path\":\"$SECURITY_CONFIG_FILE\"}"
        exit 1
    fi

    local allowed_domains
    allowed_domains=$(jq -r ".presets.${security_preset}.network.allowed_domains[]?" "$SECURITY_CONFIG_FILE" 2>/dev/null)

    # Add custom domains
    if [[ -n "$CUSTOM_ALLOWED_DOMAINS" ]]; then
        allowed_domains="$allowed_domains"$'\n'"$CUSTOM_ALLOWED_DOMAINS"
    fi

    # Refresh each domain
    local total_domains=0
    local refreshed_domains=0
    while IFS= read -r domain; do
        if [[ -n "$domain" ]]; then
            ((total_domains++)) || true
            if refresh_domain "$domain"; then
                ((refreshed_domains++)) || true
            fi
        fi
    done <<< "$allowed_domains"

    log_info "DNS refresh complete" "{\"total\":$total_domains,\"refreshed\":$refreshed_domains}"

    # Log refresh timestamp
    {
        echo "$(date -Iseconds): Refreshed $refreshed_domains/$total_domains domains"
        echo "Preset: $security_preset"
    } >> "$REFRESH_LOG" 2>/dev/null || true
}

main "$@"
