#!/bin/bash
set -euo pipefail

echo "📊 SSH Connection Monitor"
echo "======================="

APP_NAME="${1:-}"
INTERVAL="${2:-5}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [interval-seconds]"
    exit 1
fi

echo "Monitoring: $APP_NAME (every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Test connection and measure latency
    if LATENCY=$(ssh -o ConnectTimeout=5 -p 10022 node@${APP_NAME}.fly.dev \
        "echo 'pong'" 2>&1 | grep -oE '[0-9]+ms' || echo "timeout"); then
        echo "[$TIMESTAMP] ✅ Connected - Latency: $LATENCY"
    else
        echo "[$TIMESTAMP] ❌ Connection failed"
    fi
    
    sleep $INTERVAL
done