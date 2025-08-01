#!/bin/bash
set -euo pipefail

echo "🎛️  SwarmContainer Fly.io Manager"
echo "================================"
echo ""

APP_NAME="${1:-}"
ACTION="${2:-menu}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [action]"
    echo ""
    echo "Actions:"
    echo "  status    - Show app status"
    echo "  start     - Start the app"
    echo "  stop      - Stop the app"
    echo "  restart   - Restart the app"
    echo "  logs      - Show recent logs"
    echo "  ssh       - Connect via SSH"
    echo "  scale     - Change machine size"
    echo "  backup    - Backup volumes"
    echo "  destroy   - Destroy app (careful!)"
    exit 1
fi

case "$ACTION" in
    menu)
        echo "Select action for: $APP_NAME"
        echo ""
        echo "1) Status"
        echo "2) Start"
        echo "3) Stop"
        echo "4) Restart"
        echo "5) Logs"
        echo "6) SSH"
        echo "7) Scale"
        echo "8) Backup"
        echo "9) Destroy (careful!)"
        echo "0) Exit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) ACTION="status" ;;
            2) ACTION="start" ;;
            3) ACTION="stop" ;;
            4) ACTION="restart" ;;
            5) ACTION="logs" ;;
            6) ACTION="ssh" ;;
            7) ACTION="scale" ;;
            8) ACTION="backup" ;;
            9) ACTION="destroy" ;;
            0) exit 0 ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
        ;;
esac

# Execute action
case "$ACTION" in
    status)
        echo "📊 App Status:"
        flyctl status -a "$APP_NAME"
        echo ""
        echo "💾 Volumes:"
        flyctl volumes list -a "$APP_NAME"
        ;;
        
    start)
        echo "▶️  Starting app..."
        flyctl machine start -a "$APP_NAME"
        ;;
        
    stop)
        echo "⏹️  Stopping app..."
        flyctl machine stop -a "$APP_NAME"
        ;;
        
    restart)
        echo "🔄 Restarting app..."
        flyctl machine restart -a "$APP_NAME"
        ;;
        
    logs)
        echo "📜 Recent logs:"
        flyctl logs -n 100 -a "$APP_NAME"
        ;;
        
    ssh)
        echo "🔌 Connecting via SSH..."
        ssh -p 10022 node@${APP_NAME}.fly.dev
        ;;
        
    scale)
        echo "📏 Current scale:"
        flyctl scale show -a "$APP_NAME"
        echo ""
        echo "Available options:"
        echo "1) shared-cpu-1x (256MB)"
        echo "2) shared-cpu-1x (512MB)"
        echo "3) shared-cpu-2x (2GB)"
        echo "4) shared-cpu-4x (4GB)"
        echo "5) shared-cpu-8x (8GB)"
        echo "6) performance-1x (2GB)"
        echo "7) performance-2x (4GB)"
        echo "8) performance-4x (8GB)"
        echo ""
        read -p "Choice (or 0 to cancel): " scale_choice
        
        case $scale_choice in
            1) flyctl scale vm shared-cpu-1x --memory 256 -a "$APP_NAME" ;;
            2) flyctl scale vm shared-cpu-1x --memory 512 -a "$APP_NAME" ;;
            3) flyctl scale vm shared-cpu-2x -a "$APP_NAME" ;;
            4) flyctl scale vm shared-cpu-4x -a "$APP_NAME" ;;
            5) flyctl scale vm shared-cpu-8x -a "$APP_NAME" ;;
            6) flyctl scale vm performance-1x -a "$APP_NAME" ;;
            7) flyctl scale vm performance-2x -a "$APP_NAME" ;;
            8) flyctl scale vm performance-4x -a "$APP_NAME" ;;
            0) echo "Cancelled" ;;
            *) echo "Invalid choice" ;;
        esac
        ;;
        
    backup)
        echo "💾 Creating backup..."
        ./scripts/fly-volume-backup.sh "$APP_NAME"
        ;;
        
    destroy)
        echo "⚠️  WARNING: This will destroy the app and all data!"
        echo "App to destroy: $APP_NAME"
        echo ""
        read -p "Type the app name to confirm: " confirm
        
        if [ "$confirm" = "$APP_NAME" ]; then
            echo "Destroying app..."
            flyctl apps destroy "$APP_NAME" --yes
            echo "✅ App destroyed"
        else
            echo "❌ Cancelled - names don't match"
        fi
        ;;
        
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac