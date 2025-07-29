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