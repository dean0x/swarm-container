#!/bin/bash
set -euo pipefail

echo "💰 SwarmContainer Cost Monitor"
echo "============================="
echo ""

APP_NAME="${1:-}"
PERIOD="${2:-current}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [period]"
    echo "Periods: current, last-month, last-7-days"
    exit 1
fi

echo "📊 Cost Analysis for: $APP_NAME"
echo "📅 Period: $PERIOD"
echo ""

# Get machine info
echo "🖥️  Machine Configuration:"
MACHINE_INFO=$(flyctl machine list -a "$APP_NAME" --json 2>/dev/null || echo "[]")

if [ "$MACHINE_INFO" != "[]" ]; then
    echo "$MACHINE_INFO" | jq -r '.[] | "   \(.id): \(.config.guest.cpu_kind)-\(.config.guest.cpus)x (\(.config.guest.memory_mb)MB) - \(.state)"'
    
    # Calculate estimated costs
    echo ""
    echo "💵 Estimated Costs:"
    
    TOTAL_VCPU=0
    TOTAL_MEMORY=0
    RUNNING_MACHINES=0
    
    while IFS= read -r machine; do
        STATE=$(echo "$machine" | jq -r '.state')
        if [ "$STATE" = "started" ]; then
            CPUS=$(echo "$machine" | jq -r '.config.guest.cpus')
            MEMORY=$(echo "$machine" | jq -r '.config.guest.memory_mb')
            CPU_KIND=$(echo "$machine" | jq -r '.config.guest.cpu_kind')
            
            TOTAL_VCPU=$((TOTAL_VCPU + CPUS))
            TOTAL_MEMORY=$((TOTAL_MEMORY + MEMORY))
            RUNNING_MACHINES=$((RUNNING_MACHINES + 1))
        fi
    done < <(echo "$MACHINE_INFO" | jq -c '.[]')
    
    # Pricing (approximate as of 2024)
    # Shared CPU: $0.0000008/second = $2.07/month per vCPU
    # Memory: $0.0000001/second/GB = $0.26/month per GB
    # Performance CPU: ~3x shared price
    
    if [ $RUNNING_MACHINES -gt 0 ]; then
        VCPU_COST_MONTH=$(echo "scale=2; $TOTAL_VCPU * 2.07" | bc)
        MEMORY_COST_MONTH=$(echo "scale=2; ($TOTAL_MEMORY / 1024) * 0.26" | bc)
        TOTAL_COMPUTE=$(echo "scale=2; $VCPU_COST_MONTH + $MEMORY_COST_MONTH" | bc)
        
        echo "   Running Machines: $RUNNING_MACHINES"
        echo "   Total vCPUs: $TOTAL_VCPU"
        echo "   Total Memory: ${TOTAL_MEMORY}MB"
        echo ""
        echo "   Estimated Monthly Compute: \$$TOTAL_COMPUTE"
    else
        echo -e "   ${GREEN}No running machines - \$0 compute cost${NC}"
    fi
else
    echo "   No machines found"
fi

# Get volume info
echo ""
echo "💾 Storage Volumes:"
VOLUMES=$(flyctl volumes list -a "$APP_NAME" --json 2>/dev/null || echo "[]")

if [ "$VOLUMES" != "[]" ]; then
    TOTAL_STORAGE=0
    echo "$VOLUMES" | jq -r '.[] | "   \(.name): \(.size_gb)GB - \(.region)"'
    
    while IFS= read -r volume; do
        SIZE=$(echo "$volume" | jq -r '.size_gb')
        TOTAL_STORAGE=$((TOTAL_STORAGE + SIZE))
    done < <(echo "$VOLUMES" | jq -c '.[]')
    
    STORAGE_COST=$(echo "scale=2; $TOTAL_STORAGE * 0.15" | bc)
    echo ""
    echo "   Total Storage: ${TOTAL_STORAGE}GB"
    echo "   Estimated Monthly Storage: \$$STORAGE_COST"
else
    echo "   No volumes found"
fi

# Get actual usage (requires API access)
echo ""
echo "📈 Actual Usage:"
echo "   Visit: https://fly.io/dashboard/$APP_NAME/metrics"
echo "   Or run: flyctl dashboard metrics -a $APP_NAME"

# Cost optimization tips
echo ""
echo "💡 Cost Optimization Tips:"

if [ $RUNNING_MACHINES -gt 0 ]; then
    echo -e "   ${YELLOW}⚠️  You have running machines${NC}"
    echo "   - Enable auto-stop to save costs"
    echo "   - Stop manually: flyctl machine stop -a $APP_NAME"
fi

if [ "$TOTAL_STORAGE" -gt 20 ]; then
    echo -e "   ${YELLOW}⚠️  Large storage volumes detected${NC}"
    echo "   - Review if all space is needed"
    echo "   - Clean up old projects"
fi

echo ""
echo "   ✅ Auto-stop enabled saves ~90% on compute"
echo "   ✅ Use shared-cpu for development"
echo "   ✅ Monitor usage regularly"

# Total estimate
echo ""
echo "================================="
if [ $RUNNING_MACHINES -gt 0 ] || [ "$TOTAL_STORAGE" -gt 0 ]; then
    TOTAL_MONTHLY=$(echo "scale=2; $TOTAL_COMPUTE + $STORAGE_COST" | bc)
    echo -e "Estimated Monthly Total: ${GREEN}\$$TOTAL_MONTHLY${NC}"
    echo "(Assuming auto-stop is enabled)"
else
    echo -e "${GREEN}No active resources - \$0/month${NC}"
fi