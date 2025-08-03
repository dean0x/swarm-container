#!/bin/bash
set -euo pipefail

echo "🔧 SwarmContainer Quick Fix Tool"
echo "==============================="
echo ""

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    if [ -f "fly.toml" ]; then
        APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
    fi
fi

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [app-name]"
    exit 1
fi

echo "🎯 Checking: $APP_NAME"
echo ""

# Fix 1: Wake up machine
echo "1. Waking up machine..."
flyctl machine list -a "$APP_NAME" | grep stopped && {
    echo "   Machine is stopped, starting..."
    flyctl machine start -a "$APP_NAME"
    sleep 5
}

# Fix 2: Check SSH keys
echo ""
echo "2. Checking SSH keys..."
if ! flyctl secrets list -a "$APP_NAME" | grep -q SSH_AUTHORIZED_KEYS; then
    echo "   ❌ No SSH keys found!"
    echo "   Run: ./scripts/fly-ssh-setup.sh"
else
    echo "   ✅ SSH keys configured"
fi

# Fix 3: Test connectivity
echo ""
echo "3. Testing connectivity..."
if timeout 5 ssh -o ConnectTimeout=3 -p 10022 node@${APP_NAME}.fly.dev "echo OK" > /dev/null 2>&1; then
    echo "   ✅ SSH connection working"
else
    echo "   ❌ SSH connection failed"
    echo "   Checking app status..."
    flyctl status -a "$APP_NAME"
fi

# Fix 4: Check volumes
echo ""
echo "4. Checking volumes..."
VOLUME_COUNT=$(flyctl volumes list -a "$APP_NAME" | grep -c "created" || echo 0)
if [ "$VOLUME_COUNT" -lt 2 ]; then
    echo "   ⚠️  Missing volumes! Found: $VOLUME_COUNT, expected: 2"
    echo "   Run: ./scripts/fly-volume-setup.sh"
else
    echo "   ✅ Volumes configured"
fi

echo ""
echo "=============================="
echo "Quick fix complete!"
echo ""
echo "Still having issues? See: docs/fly-io-troubleshooting.md"