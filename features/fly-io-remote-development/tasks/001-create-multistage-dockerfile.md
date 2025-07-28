# Task 001: Create Multi-Stage Dockerfile

## Objective
Convert the existing Dockerfile to use multi-stage builds, preparing for the addition of a remote development stage.

## Prerequisites
- [ ] No prerequisites - this is the first task

## Workflow

### 1. Prerequisites Check
- Verify current Dockerfile exists and is functional
- Ensure no active changes to Dockerfile in other branches

### 2. Implementation

#### Step 2.1: Add Base Stage
- Add `AS base` to the current FROM line
- This stage contains all common setup

#### Step 2.2: Create Local Stage
- Add new stage: `FROM base AS local`
- This preserves current functionality
- No additional changes needed in this stage

#### Step 2.3: Update devcontainer.json
- Add explicit build target (optional but recommended):
```json
"build": {
  "dockerfile": "Dockerfile",
  "target": "local"
}
```

### 3. Testing

#### Test 3.1: Build Base Stage
```bash
docker build --target base -t swarmcontainer:base .
```

#### Test 3.2: Build Local Stage
```bash
docker build --target local -t swarmcontainer:local .
```

#### Test 3.3: Test Dev Container
- Open in VS Code
- Verify "Reopen in Container" works
- Ensure all existing features function

### 4. Documentation
- Add comment at top of Dockerfile explaining multi-stage structure
- Document the purpose of each stage

### 5. Completion Criteria
- [ ] Dockerfile has explicit `base` and `local` stages
- [ ] Local development works exactly as before
- [ ] Both stages build successfully
- [ ] devcontainer.json optionally specifies target
- [ ] No functionality lost

## Expected Changes

### Dockerfile
```dockerfile
# Multi-stage Dockerfile for SwarmContainer
# - base: Common setup for all deployments
# - local: VS Code Dev Container (default)
# - remote: Fly.io SSH deployment (future)

FROM mcr.microsoft.com/devcontainers/javascript-node:20-bullseye AS base

# ... all existing Dockerfile content ...

# Local development stage - preserves current functionality
FROM base AS local
# No additional changes needed - inherits everything from base
```

### devcontainer.json (optional)
```json
{
  "build": {
    "dockerfile": "Dockerfile",
    "target": "local"
  }
}
```

## Notes
- This change is purely structural - no functional changes
- Sets foundation for adding remote stage without affecting current users
- Multi-stage builds are a Docker best practice