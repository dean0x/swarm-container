# Task 015: Implement Cost Monitoring

## Objective
Create tools and documentation to help users monitor and control their Fly.io usage costs.

## Prerequisites
- [ ] Fly.io app deployed and running
- [ ] Understanding of Fly.io pricing model
- [ ] Billing alerts configured in Fly.io dashboard

## Workflow

### 1. Prerequisites Check
- Review current Fly.io pricing
- Understand billing metrics
- Identify cost optimization opportunities

### 2. Implementation

#### Step 2.1: Create Cost Monitoring Script
Create `scripts/fly-cost-monitor.sh`:

```bash
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
```

#### Step 2.2: Create Usage Tracking Script
Create `scripts/fly-usage-tracker.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "📊 SwarmContainer Usage Tracker"
echo "=============================="
echo ""

APP_NAME="${1:-}"
ACTION="${2:-report}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [action]"
    echo "Actions: report, export, reset"
    exit 1
fi

LOG_FILE="$HOME/.fly-usage-${APP_NAME}.log"

# Record current state
record_usage() {
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
    STATE=$(flyctl machine list -a "$APP_NAME" --json | jq -r '.[0].state' 2>/dev/null || echo "unknown")
    
    echo "$TIMESTAMP,$APP_NAME,$STATE" >> "$LOG_FILE"
}

# Generate report
generate_report() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "No usage data found. Start tracking first."
        exit 1
    fi
    
    echo "Usage Report for: $APP_NAME"
    echo ""
    
    # Calculate running time
    TOTAL_MINUTES=0
    LAST_STATE="stopped"
    LAST_TIME=""
    
    while IFS=, read -r timestamp app state; do
        if [ "$LAST_STATE" = "started" ] && [ "$state" != "started" ]; then
            # Machine stopped, calculate runtime
            if [ -n "$LAST_TIME" ]; then
                START_SEC=$(date -d "$LAST_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$LAST_TIME" +%s)
                END_SEC=$(date -d "$timestamp" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" +%s)
                MINUTES=$(( (END_SEC - START_SEC) / 60 ))
                TOTAL_MINUTES=$((TOTAL_MINUTES + MINUTES))
            fi
        fi
        
        if [ "$state" = "started" ] && [ "$LAST_STATE" != "started" ]; then
            LAST_TIME="$timestamp"
        fi
        
        LAST_STATE="$state"
    done < "$LOG_FILE"
    
    # If still running, add current session
    if [ "$LAST_STATE" = "started" ] && [ -n "$LAST_TIME" ]; then
        NOW=$(date -u +"%Y-%m-%d %H:%M:%S")
        START_SEC=$(date -d "$LAST_TIME" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$LAST_TIME" +%s)
        END_SEC=$(date -d "$NOW" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$NOW" +%s)
        MINUTES=$(( (END_SEC - START_SEC) / 60 ))
        TOTAL_MINUTES=$((TOTAL_MINUTES + MINUTES))
        echo "⚠️  Currently running since $LAST_TIME"
    fi
    
    echo "Total Runtime: $TOTAL_MINUTES minutes"
    echo "Total Hours: $(echo "scale=2; $TOTAL_MINUTES / 60" | bc) hours"
    echo ""
    
    # Estimate cost
    # Assuming shared-cpu-2x at ~$0.01/hour
    COST=$(echo "scale=2; ($TOTAL_MINUTES / 60) * 0.01" | bc)
    echo "Estimated Compute Cost: \$$COST"
}

case "$ACTION" in
    report)
        record_usage
        generate_report
        ;;
    export)
        if [ -f "$LOG_FILE" ]; then
            echo "Exporting to: usage-export-$APP_NAME.csv"
            cp "$LOG_FILE" "usage-export-$APP_NAME.csv"
            echo "Done!"
        else
            echo "No usage data to export"
        fi
        ;;
    reset)
        read -p "Reset usage data for $APP_NAME? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$LOG_FILE"
            echo "Usage data reset"
        fi
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
```

#### Step 2.3: Create Budget Alert Script
Create `scripts/fly-budget-alert.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "💸 SwarmContainer Budget Alert Setup"
echo "==================================="
echo ""

APP_NAME="${1:-}"
BUDGET="${2:-10}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [monthly-budget]"
    echo "Default budget: \$10/month"
    exit 1
fi

echo "Setting up budget alerts for: $APP_NAME"
echo "Monthly budget: \$$BUDGET"
echo ""

# Create monitoring script
cat > "$HOME/.fly-budget-monitor-$APP_NAME.sh" << 'EOF'
#!/bin/bash
APP_NAME="$1"
BUDGET="$2"

# Get current costs
VCPUS=$(flyctl machine list -a "$APP_NAME" --json | jq '[.[] | select(.state=="started") | .config.guest.cpus] | add' || echo 0)
MEMORY=$(flyctl machine list -a "$APP_NAME" --json | jq '[.[] | select(.state=="started") | .config.guest.memory_mb] | add' || echo 0)
STORAGE=$(flyctl volumes list -a "$APP_NAME" --json | jq '[.[].size_gb] | add' || echo 0)

# Calculate monthly estimate
COMPUTE_COST=$(echo "scale=2; ($VCPUS * 2.07) + (($MEMORY / 1024) * 0.26)" | bc)
STORAGE_COST=$(echo "scale=2; $STORAGE * 0.15" | bc)
TOTAL=$(echo "scale=2; $COMPUTE_COST + $STORAGE_COST" | bc)

# Check against budget
if (( $(echo "$TOTAL > $BUDGET" | bc -l) )); then
    echo "⚠️  BUDGET ALERT: $APP_NAME"
    echo "Estimated monthly: \$$TOTAL (Budget: \$$BUDGET)"
    echo "Action needed: Stop machines or reduce resources"
    
    # Could add email/notification here
    # mail -s "Fly.io Budget Alert" user@example.com << MSG
    # Your Fly.io app $APP_NAME is over budget!
    # Current estimate: \$$TOTAL/month
    # Budget: \$$BUDGET/month
    # MSG
fi
EOF

chmod +x "$HOME/.fly-budget-monitor-$APP_NAME.sh"

# Add to crontab (check every 6 hours)
echo "Adding to crontab..."
CRON_CMD="0 */6 * * * $HOME/.fly-budget-monitor-$APP_NAME.sh $APP_NAME $BUDGET"

# Check if already in crontab
if ! crontab -l 2>/dev/null | grep -q "fly-budget-monitor-$APP_NAME"; then
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "✅ Budget monitoring enabled"
    echo "   Checks every 6 hours"
    echo "   Budget: \$$BUDGET/month"
else
    echo "⚠️  Budget monitoring already configured"
fi

echo ""
echo "📝 Additional Fly.io Cost Controls:"
echo "1. Set up billing alerts at: https://fly.io/dashboard/billing"
echo "2. Review usage at: https://fly.io/dashboard/$APP_NAME/metrics"
echo "3. Enable spending limits in Fly.io dashboard"
echo ""
echo "To disable monitoring:"
echo "crontab -e  # Remove the line with $APP_NAME"
```

#### Step 2.4: Add Cost Section to Documentation
Add to `docs/fly-io-setup.md`:

```markdown
## Cost Monitoring and Control

### Monitoring Tools

1. **Cost Monitor**
   ```bash
   ./scripts/fly-cost-monitor.sh your-app-name
   ```
   Shows current configuration and estimated monthly costs.

2. **Usage Tracker**
   ```bash
   # Start tracking
   ./scripts/fly-usage-tracker.sh your-app-name report
   
   # Export data
   ./scripts/fly-usage-tracker.sh your-app-name export
   ```
   Tracks actual runtime and generates cost reports.

3. **Budget Alerts**
   ```bash
   # Set $15/month budget
   ./scripts/fly-budget-alert.sh your-app-name 15
   ```
   Monitors spending and alerts when approaching budget.

### Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| Shared CPU | $2.07/vCPU/month | When running |
| Memory | $0.26/GB/month | When running |
| Storage | $0.15/GB/month | Always charged |
| Stopped | $0 | No compute charges |
| Network | First 100GB free | Then $0.02/GB |

### Optimization Strategies

1. **Auto-Stop Configuration**
   ```toml
   # fly.toml - Aggressive auto-stop
   [[services]]
     auto_stop_machines = true
     auto_start_machines = true  
     min_machines_running = 0
   ```

2. **Right-Size Resources**
   ```bash
   # Development: minimal resources
   flyctl scale vm shared-cpu-1x --memory 512
   
   # Active development: comfortable resources
   flyctl scale vm shared-cpu-2x --memory 2048
   ```

3. **Volume Management**
   ```bash
   # Check usage
   ssh -p 10022 node@app.fly.dev "df -h"
   
   # Clean up
   ssh -p 10022 node@app.fly.dev "npm cache clean --force"
   ```

### Typical Monthly Costs

| Usage Pattern | Est. Cost | Configuration |
|---------------|-----------|---------------|
| Occasional (<50hr) | $2-5 | 1 CPU, 512MB, auto-stop |
| Regular (100hr) | $5-10 | 2 CPU, 2GB, auto-stop |
| Heavy (200hr) | $10-20 | 4 CPU, 4GB, auto-stop |
| Always-on | $30-60 | Varies, no auto-stop |

### Free Tier and Credits

- New accounts often include free credits
- First 3 shared-cpu-1x VMs free (with limitations)
- Check current offers at fly.io/pricing

### Budget Management

1. **Set Spending Limits**
   - Configure in Fly.io dashboard
   - Prevents unexpected charges
   
2. **Regular Reviews**
   ```bash
   # Weekly cost check
   ./scripts/fly-cost-monitor.sh
   
   # Monthly usage report
   ./scripts/fly-usage-tracker.sh your-app report
   ```

3. **Clean Up Unused Apps**
   ```bash
   # List all apps
   flyctl apps list
   
   # Destroy unused
   flyctl apps destroy unused-app-name
   ```
```

### 3. Testing

#### Test 3.1: Cost Monitor
```bash
chmod +x scripts/fly-cost-monitor.sh
./scripts/fly-cost-monitor.sh test-app
```

#### Test 3.2: Usage Tracker
```bash
chmod +x scripts/fly-usage-tracker.sh
# Simulate usage
./scripts/fly-usage-tracker.sh test-app report
./scripts/fly-usage-tracker.sh test-app export
```

#### Test 3.3: Budget Alerts
```bash
chmod +x scripts/fly-budget-alert.sh
./scripts/fly-budget-alert.sh test-app 10
```

### 4. Documentation

- Update main guide with cost section
- Add to troubleshooting guide
- Include in quick reference

### 5. Completion Criteria
- [ ] Cost monitor script working
- [ ] Usage tracking implemented
- [ ] Budget alerts configured
- [ ] Documentation updated
- [ ] All scripts tested
- [ ] Cost optimization tips included

## Design Principles

### Accuracy
- Use official pricing when available
- Clearly mark estimates
- Link to official sources
- Account for all resources

### Usability
- Simple commands
- Clear output
- Actionable insights
- Automation where possible

### Transparency
- Show calculations
- Explain assumptions
- Provide raw data access
- Enable custom analysis

## Future Enhancements

1. **API Integration**
   - Pull actual usage from Fly.io API
   - More accurate cost calculations
   - Historical trending

2. **Notifications**
   - Email alerts for budget
   - Slack/Discord webhooks
   - Mobile push notifications

3. **Optimization Bot**
   - Auto-stop after X hours
   - Downsize during quiet periods
   - Weekend/holiday schedules