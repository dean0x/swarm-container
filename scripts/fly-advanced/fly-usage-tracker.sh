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