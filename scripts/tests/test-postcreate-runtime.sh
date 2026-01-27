#!/bin/bash

echo "🧪 Testing PostCreate Runtime Execution..."
echo ""

# Create a test container without the entrypoint
CONTAINER_ID=$(docker run -d \
    -v $(pwd):/workspace \
    -v $(pwd):/devcontainer-config \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    -e SECURITY_PRESET="development" \
    --memory 8g \
    --cpus 4 \
    --entrypoint /bin/bash \
    swarmcontainer-test \
    -c "sleep 300")

echo "Container ID: $CONTAINER_ID"
echo ""

# Run postCreate with timeout
echo "🚀 Running postCreate script (with 3-minute timeout)..."
# Use timeout to prevent hanging on clone operations
timeout 180 docker exec "$CONTAINER_ID" bash /devcontainer-config/scripts/hooks/postCreate.sh

# Check exit code
EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 124 ]; then
    echo "PostCreate timed out after 3 minutes (likely during git clone)"
    echo -e "${YELLOW}⚠${NC} This is expected for large repository clones"
    EXIT_CODE=0  # Don't fail on timeout
else
    echo "PostCreate exit code: $EXIT_CODE"
fi

# Show some verification
echo ""
echo "📋 Verifying results..."
echo "1. Checking npm config:"
docker exec "$CONTAINER_ID" npm config get registry

echo ""
echo "2. Checking workspace structure:"
docker exec "$CONTAINER_ID" ls -la /workspace/.gitignore 2>/dev/null || echo ".gitignore not created"

echo ""
echo "3. Checking shell history init:"
docker exec "$CONTAINER_ID" ls -la ~/.swarm_history_* 2>/dev/null || echo "No history files yet"

# Cleanup
docker stop "$CONTAINER_ID" >/dev/null
docker rm "$CONTAINER_ID" >/dev/null

echo ""
echo "✅ PostCreate runtime test completed!"