#!/bin/bash

echo "🆚 Testing VS Code DevContainer Integration..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if VS Code CLI is available
if ! command -v code &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} VS Code CLI not found. Install it from VS Code: Shell Command: Install 'code' command in PATH"
    echo "   Continuing with other tests..."
    echo ""
fi

# Test 1: Check for VS Code specific configuration
echo "1️⃣ Checking VS Code configuration..."

if [ -f "devcontainer.json" ]; then
    echo -e "   ${GREEN}✓${NC} devcontainer.json found"
    
    # Check for required VS Code properties
    REQUIRED_PROPS=("customizations" "workspaceFolder" "remoteUser")
    for prop in "${REQUIRED_PROPS[@]}"; do
        if grep -q "\"$prop\"" devcontainer.json; then
            echo -e "   ${GREEN}✓${NC} $prop configured"
        else
            echo -e "   ${RED}✗${NC} Missing required property: $prop"
        fi
    done
else
    echo -e "   ${RED}✗${NC} devcontainer.json not found!"
fi

# Test 2: Validate VS Code extensions
echo ""
echo "2️⃣ Checking VS Code extensions..."

if grep -q "extensions" devcontainer.json; then
    EXTENSIONS=$(grep -A10 '"extensions"' devcontainer.json | grep -o '"[^"]*\.[^"]*"' | tr -d '"')
    if [ -n "$EXTENSIONS" ]; then
        echo -e "   ${GREEN}✓${NC} Extensions configured:"
        echo "$EXTENSIONS" | sed 's/^/      - /'
    else
        echo -e "   ${YELLOW}⚠${NC} No extensions configured"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} No extensions section found"
fi

# Test 3: Check for common VS Code issues
echo ""
echo "3️⃣ Checking for common VS Code integration issues..."

# Check if dockerfile or dockerFile is used (VS Code accepts both)
if grep -q '"dockerfile":\|"dockerFile":' devcontainer.json; then
    echo -e "   ${GREEN}✓${NC} Dockerfile reference found"
else
    echo -e "   ${RED}✗${NC} No Dockerfile reference in devcontainer.json"
fi

# Check for build context
if grep -q '"build"' devcontainer.json; then
    echo -e "   ${GREEN}✓${NC} Build configuration found"
elif grep -q '"image"' devcontainer.json; then
    echo -e "   ${GREEN}✓${NC} Image configuration found"
else
    echo -e "   ${RED}✗${NC} No build or image configuration found"
fi

# Test 4: Simulate VS Code container detection
echo ""
echo "4️⃣ Testing container detection simulation..."

# Create a temporary test script that simulates VS Code's behavior
cat > /tmp/test-vscode-sim.sh << 'EOF'
#!/bin/bash
# Simulate VS Code's devcontainer detection

CONFIG_FILE="devcontainer.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: No devcontainer.json found"
    exit 1
fi

# Check if it's valid JSON
if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "ERROR: Invalid JSON in devcontainer.json"
    exit 1
fi

# Extract key properties VS Code needs
echo "Checking VS Code requirements..."

# Check for workspace configuration
if grep -q '"workspaceFolder"' "$CONFIG_FILE" && grep -q '"workspaceMount"' "$CONFIG_FILE"; then
    echo "✓ Workspace configuration OK"
else
    echo "✗ Missing workspace configuration"
fi

# Check for user configuration
if grep -q '"remoteUser"' "$CONFIG_FILE"; then
    echo "✓ Remote user configured"
else
    echo "✗ No remote user specified"
fi

# Check for conflicting mount points
MOUNT_TARGETS=$(grep -o '"target":"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 | sort | uniq -d)
if [ -n "$MOUNT_TARGETS" ]; then
    echo "✗ Duplicate mount targets found: $MOUNT_TARGETS"
else
    echo "✓ No duplicate mounts"
fi

EOF

chmod +x /tmp/test-vscode-sim.sh
bash /tmp/test-vscode-sim.sh | sed 's/^/   /'
rm -f /tmp/test-vscode-sim.sh

# Test 5: Pre-build validation
echo ""
echo "5️⃣ Running pre-build validation..."

# This simulates checks VS Code might do before building
PREBUILD_ERRORS=0

# Check Docker daemon
if docker info > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Docker daemon accessible"
else
    echo -e "   ${RED}✗${NC} Docker daemon not running or not accessible"
    ((PREBUILD_ERRORS++))
fi

# Check for Dockerfile
if [ -f "Dockerfile" ]; then
    echo -e "   ${GREEN}✓${NC} Dockerfile exists"
    
    # Basic Dockerfile validation
    if grep -q "^FROM" Dockerfile; then
        echo -e "   ${GREEN}✓${NC} Dockerfile has FROM instruction"
    else
        echo -e "   ${RED}✗${NC} Dockerfile missing FROM instruction"
        ((PREBUILD_ERRORS++))
    fi
else
    echo -e "   ${RED}✗${NC} Dockerfile not found"
    ((PREBUILD_ERRORS++))
fi

# Test 6: Command execution test
echo ""
echo "6️⃣ Testing command execution flow..."

# Check postCreateCommand
if grep -q '"postCreateCommand"' devcontainer.json; then
    POST_CREATE=$(grep '"postCreateCommand"' devcontainer.json | cut -d'"' -f4)
    echo -e "   ${GREEN}✓${NC} postCreateCommand: $POST_CREATE"
    
    # Check if the command file exists
    if [[ "$POST_CREATE" == *".sh"* ]] && [[ "$POST_CREATE" != *"|| true"* ]]; then
        SCRIPT_FILE=$(echo "$POST_CREATE" | grep -o '[^ ]*\.sh' | head -1)
        if [ -f "$SCRIPT_FILE" ]; then
            echo -e "   ${GREEN}✓${NC} Script exists: $SCRIPT_FILE"
        else
            echo -e "   ${RED}✗${NC} Script not found: $SCRIPT_FILE"
        fi
    fi
fi

# Summary and recommendations
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📋 VS Code Integration Test Summary${NC}"
echo ""

if [ $PREBUILD_ERRORS -eq 0 ]; then
    echo -e "${GREEN}Pre-build checks passed.${NC}"
    echo ""
    echo "To test in VS Code:"
    echo "1. Open VS Code: code ."
    echo "2. When prompted, click 'Reopen in Container'"
    echo "3. Or use Command Palette: 'Remote-Containers: Reopen in Container'"
    echo ""
    echo "If issues occur, check:"
    echo "- VS Code Output panel → 'Remote-Containers' output"
    echo "- Docker logs for the container"
else
    echo -e "${RED}Pre-build validation failed!${NC}"
    echo "Fix the issues above before opening in VS Code."
fi

# Additional tips
echo ""
echo "💡 Tips for debugging VS Code container issues:"
echo "   - Check the Remote-Containers output in VS Code"
echo "   - Look for the 'Dev Container' log in the Output panel"
echo "   - Use 'Remote-Containers: Show Container Log' command"
echo "   - Rebuild without cache: 'Remote-Containers: Rebuild Container Without Cache'"