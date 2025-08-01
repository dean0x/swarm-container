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