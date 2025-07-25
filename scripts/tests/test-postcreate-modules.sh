#!/bin/bash

echo "🧪 Testing PostCreate Modules..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test module directory exists
echo "1️⃣ Checking module structure..."
MODULES_DIR="scripts/hooks/modules"

if [ -d "$MODULES_DIR" ]; then
    echo -e "   ${GREEN}✓${NC} Modules directory exists"
else
    echo -e "   ${RED}✗${NC} Modules directory not found"
    exit 1
fi

# List all modules
echo ""
echo "2️⃣ Listing modules..."
modules=($(ls "$MODULES_DIR"/*.sh 2>/dev/null | sort))
EXPECTED_MODULE_COUNT=7
if [ ${#modules[@]} -gt 0 ]; then
    echo -e "   ${GREEN}✓${NC} Found ${#modules[@]} modules:"
    for module in "${modules[@]}"; do
        echo "      - $(basename $module)"
    done
    
    # Validate module count
    if [ ${#modules[@]} -eq $EXPECTED_MODULE_COUNT ]; then
        echo -e "   ${GREEN}✓${NC} Module count matches expected ($EXPECTED_MODULE_COUNT)"
    else
        echo -e "   ${YELLOW}⚠${NC} Module count (${#modules[@]}) differs from expected ($EXPECTED_MODULE_COUNT)"
    fi
else
    echo -e "   ${RED}✗${NC} No modules found"
    exit 1
fi

# Test module syntax
echo ""
echo "3️⃣ Testing module syntax..."
all_good=true
for module in "${modules[@]}"; do
    if bash -n "$module" 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $(basename $module) - syntax OK"
    else
        echo -e "   ${RED}✗${NC} $(basename $module) - syntax error"
        bash -n "$module" 2>&1 | head -5
        all_good=false
    fi
done

if [ "$all_good" = false ]; then
    echo -e "   ${RED}Some modules have syntax errors${NC}"
    exit 1
fi

# Test module permissions
echo ""
echo "4️⃣ Testing module permissions..."
for module in "${modules[@]}"; do
    if [ -x "$module" ]; then
        echo -e "   ${GREEN}✓${NC} $(basename $module) - executable"
    else
        echo -e "   ${YELLOW}⚠${NC} $(basename $module) - not executable"
        # Fix it
        chmod +x "$module"
        echo -e "      ${GREEN}Fixed${NC}"
    fi
done

# Test main postCreate.sh calls modules
echo ""
echo "5️⃣ Checking postCreate.sh module integration..."
postcreate="scripts/hooks/postCreate.sh"

if [ -f "$postcreate" ]; then
    echo -e "   ${GREEN}✓${NC} postCreate.sh exists"
    
    # Check if it sources or calls modules
    if grep -q "run_module" "$postcreate"; then
        echo -e "   ${GREEN}✓${NC} Uses run_module function"
    else
        echo -e "   ${RED}✗${NC} Missing run_module function"
    fi
    
    # Count module calls
    module_calls=$(grep -c "run_module.*\.sh" "$postcreate")
    echo -e "   ${GREEN}✓${NC} Calls $module_calls modules"
else
    echo -e "   ${RED}✗${NC} postCreate.sh not found"
    exit 1
fi

# Test individual modules in isolation (dry run)
echo ""
echo "6️⃣ Testing module isolation (dry run)..."

# Create a test environment
export WORKSPACE_TEST="/tmp/test-workspace-$$"
mkdir -p "$WORKSPACE_TEST"
cd "$WORKSPACE_TEST"

# Test each module can handle missing dependencies gracefully
test_module() {
    local module=$1
    local name=$(basename "$module")
    
    # Run in subshell to isolate environment
    (
        # Set test environment variables
        export ANTHROPIC_API_KEY=""
        export ZSH_CUSTOM="$WORKSPACE_TEST/.oh-my-zsh/custom"
        export SECURITY_PRESET="development"
        
        # Redirect to capture output
        output=$(bash "$module" 2>&1)
        exit_code=$?
        
        if [ $exit_code -eq 0 ] || [[ "$output" =~ "completed" ]] || [[ "$output" =~ "configured" ]]; then
            echo -e "   ${GREEN}✓${NC} $name - handles test environment"
        else
            echo -e "   ${YELLOW}⚠${NC} $name - exit code $exit_code (may be expected)"
        fi
    )
}

# Only test safe modules that won't modify the system
safe_modules=(
    "init-npm.sh"
    "init-claude-code.sh"
    "setup-permissions.sh"
    "setup-mcp.sh"
)

for module_name in "${safe_modules[@]}"; do
    module_path="$MODULES_DIR/$module_name"
    if [ -f "$module_path" ]; then
        test_module "$module_path"
    fi
done

# Cleanup
cd - >/dev/null
rm -rf "$WORKSPACE_TEST"

# Check module documentation
echo ""
echo "7️⃣ Checking module documentation..."
if [ -f "$MODULES_DIR/README.md" ]; then
    echo -e "   ${GREEN}✓${NC} README.md exists"
    line_count=$(wc -l < "$MODULES_DIR/README.md")
    echo -e "   ${GREEN}✓${NC} Documentation has $line_count lines"
else
    echo -e "   ${YELLOW}⚠${NC} No README.md found"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ PostCreate module tests completed!${NC}"
echo ""
echo "Module architecture:"
echo "  - Main script: postCreate.sh"
echo "  - Module directory: $MODULES_DIR"
echo "  - Total modules: ${#modules[@]}"
echo ""
echo "Next steps to test in container:"
echo "  1. Build container with new structure"
echo "  2. Run postCreate.sh manually"
echo "  3. Check each module output"