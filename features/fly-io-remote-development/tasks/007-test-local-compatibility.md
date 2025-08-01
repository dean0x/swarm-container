# Task 007: Test Local Compatibility

## Objective
Ensure that all changes made for Fly.io support do not break existing local VS Code Dev Container functionality.

## Prerequisites
- [ ] Tasks 001-006 completed: All Fly.io changes implemented

## Workflow

### 1. Prerequisites Check
- Verify all previous tasks are complete
- Ensure no uncommitted changes
- Have VS Code with Dev Containers extension installed

### 2. Implementation

#### Step 2.1: Create Compatibility Test Script
Create `scripts/tests/test-fly-compatibility.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "🧪 SwarmContainer Fly.io Compatibility Test Suite"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Dockerfile syntax
echo "📋 Running Dockerfile tests..."
run_test "Dockerfile syntax" "docker run --rm -i hadolint/hadolint < Dockerfile"
run_test "Base stage builds" "docker build --target base -t test:base ."
run_test "Local stage builds" "docker build --target local -t test:local ."
run_test "Remote stage builds" "docker build --target remote -t test:remote ."

# Test 2: Local stage isolation
echo ""
echo "📋 Testing local stage isolation..."
run_test "No SSH in local stage" "! docker run --rm test:local which sshd"
run_test "PostCreate exists in local" "docker run --rm test:local test -f /workspace/scripts/hooks/postCreate.sh"

# Test 3: File structure
echo ""
echo "📋 Testing file structure..."
run_test "fly.toml exists" "test -f fly.toml"
run_test "fly-entrypoint.sh exists" "test -f fly-entrypoint.sh"
run_test "devcontainer.json unchanged" "grep -q 'SwarmContainer' devcontainer.json"

# Test 4: Build target compatibility
echo ""
echo "📋 Testing build targets..."
run_test "Default build uses last stage" "docker build -t test:default . && docker run --rm test:default which sshd"
run_test "Explicit local target" "docker build --target local -t test:explicit-local . && ! docker run --rm test:explicit-local which sshd"

# Test 5: Scripts executable
echo ""
echo "📋 Testing script permissions..."
for script in scripts/fly-*.sh; do
    if [ -f "$script" ]; then
        run_test "$(basename $script) is executable" "test -x $script"
    fi
done

# Summary
echo ""
echo "========================================"
echo "Test Summary:"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All compatibility tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix issues before proceeding.${NC}"
    exit 1
fi
```

#### Step 2.2: Manual VS Code Test Checklist
Create `features/fly-io-remote-development/test-checklist.md`:

```markdown
# VS Code Dev Container Test Checklist

## Pre-test Setup
- [ ] Close VS Code completely
- [ ] Run `docker system prune` to clear caches
- [ ] Delete any existing containers

## Test 1: Fresh Container Creation
1. [ ] Open project in VS Code
2. [ ] Click "Reopen in Container" when prompted
3. [ ] Container builds successfully
4. [ ] No errors in VS Code terminal
5. [ ] Shell prompt appears

## Test 2: Feature Verification
- [ ] Run `echo $NODE_OPTIONS` - shows memory settings
- [ ] Run `echo $SECURITY_PRESET` - shows "development"
- [ ] Run `claude --version` - Claude Code installed
- [ ] Run `which sshd` - should return nothing (not found)
- [ ] Check MCP servers: `claude mcp list`

## Test 3: Script Execution
- [ ] PostCreate runs automatically
- [ ] Oh-my-zsh is installed
- [ ] Command history works (arrow up)
- [ ] Aliases work (if configured)

## Test 4: Rebuild Test
1. [ ] Add comment to Dockerfile
2. [ ] Rebuild container (F1 -> "Rebuild Container")
3. [ ] Rebuild completes successfully
4. [ ] Features still work

## Test 5: Security Presets
- [ ] Copy `.env.development` to `.env`
- [ ] Rebuild and test
- [ ] Copy `.env.enterprise` to `.env`
- [ ] Rebuild and test
- [ ] Features work in all presets

## Test 6: File Persistence
1. [ ] Create file: `echo "test" > ~/test.txt`
2. [ ] Rebuild container
3. [ ] Check file persists: `cat ~/test.txt`

## Edge Cases
- [ ] Open without .env file - uses defaults
- [ ] Open with invalid Dockerfile target - falls back gracefully
- [ ] Multiple rebuilds in succession - no issues
```

### 3. Testing

#### Test 3.1: Run Automated Tests
```bash
chmod +x scripts/tests/test-fly-compatibility.sh
./scripts/tests/test-fly-compatibility.sh
```

#### Test 3.2: Manual VS Code Testing
Follow the checklist in `test-checklist.md`

#### Test 3.3: Clean Build Test
```bash
# Remove all Docker artifacts
docker system prune -a --volumes

# Test fresh build
code .
# Reopen in container and verify
```

### 4. Documentation

Document compatibility guarantee:

```markdown
## Compatibility Guarantee

The Fly.io integration maintains 100% compatibility with existing local development:

- No changes to devcontainer.json required
- No changes to existing scripts
- No impact on local performance
- All features work exactly as before

The remote functionality is completely optional and activated only when explicitly deploying to Fly.io.
```

### 5. Completion Criteria
- [ ] Automated tests pass
- [ ] Manual VS Code tests pass
- [ ] No regression in functionality
- [ ] Performance unchanged
- [ ] All security presets work
- [ ] Documentation updated

## Test Coverage

### What We Test
1. **Build Isolation**: Local and remote stages don't interfere
2. **Feature Parity**: All SwarmContainer features work
3. **Performance**: No degradation in build or runtime
4. **Security**: All presets function correctly
5. **Persistence**: Volume mounts work as expected

### What Could Break
1. **Build target**: If not specified, uses last stage (remote)
   - *Mitigation*: Set explicit target in devcontainer.json
2. **File conflicts**: New files might conflict
   - *Mitigation*: Careful naming (fly- prefix)
3. **Dependencies**: SSH adds to remote image size
   - *Mitigation*: Only in remote stage

## Rollback Plan

If issues found:
1. Remove remote stage from Dockerfile
2. Delete fly-* files
3. Revert to previous commit

## Success Metrics
- Zero bug reports from existing users
- Identical functionality in local mode
- No performance regression
- Clean separation of concerns