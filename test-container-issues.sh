#!/bin/bash

echo "🧪 Testing for Known Container Issues..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS_FOUND=0

# Test 1: Check for container exit issues
echo "1️⃣ Testing for container persistence..."
echo "   Checking for proper entrypoint configuration..."

# Check Dockerfile for entrypoint
if grep -q "ENTRYPOINT.*docker-entrypoint.sh" .devcontainer/Dockerfile; then
    echo -e "   ${GREEN}✓${NC} Entrypoint script configured"
    
    # Check if entrypoint script is copied before USER directive
    if awk '/COPY.*docker-entrypoint.sh/{found=1} /USER node/{if(found) exit 0; else exit 1}' .devcontainer/Dockerfile; then
        echo -e "   ${GREEN}✓${NC} Entrypoint created with correct permissions"
    else
        echo -e "   ${RED}✗${NC} ERROR: Entrypoint script created after USER directive"
        echo "      This will cause permission denied errors!"
        ((ERRORS_FOUND++))
    fi
else
    echo -e "   ${RED}✗${NC} ERROR: No entrypoint configured"
    echo "      Container will exit immediately after starting!"
    ((ERRORS_FOUND++))
fi

# Check devcontainer.json for overrideCommand
if grep -q '"overrideCommand":\s*true' .devcontainer/devcontainer.json; then
    echo -e "   ${GREEN}✓${NC} overrideCommand set to true"
else
    echo -e "   ${YELLOW}⚠${NC} WARNING: overrideCommand not set"
    echo "      VS Code might override the entrypoint"
fi

# Test 2: Check for mount configuration issues
echo ""
echo "2️⃣ Testing for mount configuration issues..."

# Check for problematic system file mounts
PROBLEMATIC_MOUNTS=("/etc/hosts" "/etc/resolv.conf" "/dev/null")
for mount in "${PROBLEMATIC_MOUNTS[@]}"; do
    if grep -q "target=$mount" .devcontainer/devcontainer.json; then
        echo -e "   ${RED}✗${NC} ERROR: Mounting to system file: $mount"
        echo "      This will cause container startup failures!"
        ((ERRORS_FOUND++))
    fi
done

if [ $ERRORS_FOUND -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} No problematic system file mounts found"
fi

# Test 3: Check for duplicate mount points
echo ""
echo "3️⃣ Testing for duplicate mount points..."

# Extract mount targets from devcontainer.json
WORKSPACE_MOUNTS=$(grep -E '"target":|"workspaceMount":' .devcontainer/devcontainer.json | grep -o '/workspace[^"]*' | sort)
DUPLICATE_COUNT=$(echo "$WORKSPACE_MOUNTS" | uniq -d | wc -l)

if [ $DUPLICATE_COUNT -gt 0 ]; then
    echo -e "   ${RED}✗${NC} ERROR: Duplicate workspace mount detected!"
    echo "      Found multiple mounts to the same location:"
    echo "$WORKSPACE_MOUNTS" | uniq -d | sed 's/^/      /'
    echo ""
    echo "      Check both 'mounts' array and 'workspaceMount' property"
    ((ERRORS_FOUND++))
else
    # Check if workspace is mounted
    if echo "$WORKSPACE_MOUNTS" | grep -q "/workspace"; then
        echo -e "   ${GREEN}✓${NC} Workspace mount configured correctly"
    else
        echo -e "   ${RED}✗${NC} ERROR: No workspace mount found!"
        ((ERRORS_FOUND++))
    fi
fi

# Test 4: Check for permission issues
echo ""
echo "4️⃣ Testing for potential permission issues..."

# Check if critical directories are created before USER switch
CRITICAL_DIRS=("/workspace" "/commandhistory")
for dir in "${CRITICAL_DIRS[@]}"; do
    if grep -A5 -B5 "mkdir.*$dir" .devcontainer/Dockerfile | grep -q "USER node" && \
       ! awk "/mkdir.*$dir/{found=1} /USER node/{if(found) exit 0; else exit 1}" .devcontainer/Dockerfile; then
        echo -e "   ${RED}✗${NC} ERROR: $dir created after USER switch"
        echo "      This may cause permission denied errors!"
        ((ERRORS_FOUND++))
    fi
done

# Check for proper ownership commands
if grep -q "chown.*node:node.*/workspace" .devcontainer/Dockerfile; then
    echo -e "   ${GREEN}✓${NC} Workspace ownership configured"
else
    echo -e "   ${YELLOW}⚠${NC} WARNING: Workspace ownership not explicitly set"
fi

# Test 5: Check JSON syntax
echo ""
echo "5️⃣ Validating JSON syntax..."

JSON_VALID=true
for file in .devcontainer/*.json; do
    if [ -f "$file" ]; then
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} $file valid"
        else
            echo -e "   ${RED}✗${NC} ERROR: $file has JSON syntax errors:"
            python3 -m json.tool "$file" 2>&1 | head -5 | sed 's/^/      /'
            ((ERRORS_FOUND++))
            JSON_VALID=false
        fi
    fi
done

# Test 6: Build test with error detection
echo ""
echo "6️⃣ Testing container build..."

BUILD_LOG=$(mktemp)
if docker build -t devcontainer-test -f .devcontainer/Dockerfile . > "$BUILD_LOG" 2>&1; then
    echo -e "   ${GREEN}✓${NC} Container builds successfully"
    
    # Check for warnings in build log
    if grep -i "warning" "$BUILD_LOG" > /dev/null; then
        echo -e "   ${YELLOW}⚠${NC} Build warnings detected:"
        grep -i "warning" "$BUILD_LOG" | head -5 | sed 's/^/      /'
    fi
else
    echo -e "   ${RED}✗${NC} ERROR: Container build failed!"
    echo "      Last 10 lines of build log:"
    tail -10 "$BUILD_LOG" | sed 's/^/      /'
    ((ERRORS_FOUND++))
fi
rm -f "$BUILD_LOG"

# Test 7: Runtime test
echo ""
echo "7️⃣ Testing container runtime..."

if [ $ERRORS_FOUND -eq 0 ] && [ "$JSON_VALID" = "true" ]; then
    # Test container startup
    CONTAINER_ID=$(docker run -d \
        -v "$(pwd):/workspace" \
        -v "claude-flow-node-modules:/workspace/node_modules" \
        --cap-add=NET_ADMIN \
        --cap-add=NET_RAW \
        -e SECURITY_PRESET=development \
        devcontainer-test \
        sleep 60 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✓${NC} Container starts successfully"
        
        # Wait a moment for container to initialize
        sleep 2
        
        # Check if container is still running
        if docker ps -q --no-trunc | grep -q "$CONTAINER_ID"; then
            echo -e "   ${GREEN}✓${NC} Container stays running"
            
            # Test workspace access
            if docker exec "$CONTAINER_ID" ls /workspace > /dev/null 2>&1; then
                echo -e "   ${GREEN}✓${NC} Workspace accessible"
            else
                echo -e "   ${RED}✗${NC} ERROR: Cannot access workspace!"
                ((ERRORS_FOUND++))
            fi
            
            # Check user - VS Code will handle this via remoteUser
            CONTAINER_USER=$(docker exec "$CONTAINER_ID" whoami 2>/dev/null)
            if [ "$CONTAINER_USER" = "node" ] || [ "$CONTAINER_USER" = "root" ]; then
                echo -e "   ${GREEN}✓${NC} Container user check passed (VS Code will use remoteUser: node)"
            else
                echo -e "   ${RED}✗${NC} ERROR: Unexpected user: $CONTAINER_USER"
                ((ERRORS_FOUND++))
            fi
        else
            echo -e "   ${RED}✗${NC} ERROR: Container exited immediately!"
            echo "      Container logs:"
            docker logs "$CONTAINER_ID" 2>&1 | head -10 | sed 's/^/      /'
            ((ERRORS_FOUND++))
        fi
        
        # Cleanup
        docker stop "$CONTAINER_ID" > /dev/null 2>&1
        docker rm "$CONTAINER_ID" > /dev/null 2>&1
    else
        echo -e "   ${RED}✗${NC} ERROR: Failed to start container"
        ((ERRORS_FOUND++))
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Skipping runtime tests due to previous errors"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "The devcontainer should work correctly with VS Code."
else
    echo -e "${RED}❌ Found $ERRORS_FOUND error(s)!${NC}"
    echo ""
    echo "Please fix the errors above before using the devcontainer."
    echo "These are the same issues that caused problems before."
    exit 1
fi