# Publishing SwarmContainer as a Docker Image

## Overview
This document outlines the plan for publishing SwarmContainer as a standalone Docker image, making it accessible beyond VS Code Dev Containers.

## Publishing Options

### 1. Docker Hub (Recommended)
- Most popular registry, free for public images
- Easy integration with GitHub Actions
- Support for multi-architecture builds (amd64, arm64)
- URL: `docker.io/yourusername/swarmcontainer`

### 2. GitHub Container Registry (ghcr.io)
- Integrated with GitHub repository
- Better for GitHub-centric workflows
- Same namespace as your repo
- URL: `ghcr.io/yourusername/swarmcontainer`

### 3. Both Registries (Best Approach)
- Publish to both registries for maximum availability
- Users can choose their preferred registry

## Implementation Plan

### Step 1: Create Standalone Dockerfile
- Move the current `.devcontainer/Dockerfile` to root as `Dockerfile`
- Modify it to work both as devcontainer and standalone image
- Remove devcontainer-specific paths
- Ensure all scripts are copied correctly

### Step 2: Add Docker Compose Support
Create `docker-compose.yml` for easy local usage:

```yaml
version: '3.8'
services:
  swarmcontainer:
    image: yourusername/swarmcontainer:latest
    container_name: swarmcontainer
    volumes:
      - ./workspace:/workspace
      - /var/run/docker.sock:/var/run/docker.sock  # Optional: for Docker-in-Docker
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - SECURITY_PRESET=${SECURITY_PRESET:-development}
    cap_add:
      - NET_ADMIN
      - NET_RAW
    security_opt:
      - seccomp=unconfined
      - no-new-privileges:true
    stdin_open: true
    tty: true
```

### Step 3: Create Multi-Architecture Build Workflow
Add `.github/workflows/docker-publish.yml`:

```yaml
name: Docker Publish

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: |
            yourusername/swarmcontainer
            ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=tag
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Step 4: Dockerfile Modifications
Add build arguments and optimize for standalone use:

```dockerfile
ARG SECURITY_PRESET=development
ARG NODE_VERSION=20

FROM mcr.microsoft.com/devcontainers/javascript-node:${NODE_VERSION}-bullseye

# ... existing content ...

# Add labels for better discoverability
LABEL org.opencontainers.image.source="https://github.com/yourusername/swarmcontainer"
LABEL org.opencontainers.image.description="Secure container for AI agent swarms"
LABEL org.opencontainers.image.licenses="MIT"
```

### Step 5: Usage Documentation
Add to README.md:

```markdown
## Quick Start with Docker

```bash
# Pull and run
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  yourusername/swarmcontainer:latest

# With specific security preset
docker run -it --rm \
  -v $(pwd):/workspace \
  -e SECURITY_PRESET=paranoid \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  yourusername/swarmcontainer:latest

# Using docker-compose
docker-compose run swarmcontainer
```

### Step 6: Image Optimization
- Use multi-stage builds to reduce size
- Clean up apt cache after installations
- Remove unnecessary files
- Consider creating alpine variant for smaller size

Example multi-stage approach:
```dockerfile
# Build stage
FROM mcr.microsoft.com/devcontainers/javascript-node:20-bullseye AS builder
# ... build steps ...

# Runtime stage
FROM mcr.microsoft.com/devcontainers/javascript-node:20-bullseye-slim
COPY --from=builder /needed/files /destination
# ... runtime setup ...
```

## Benefits of Docker Image Distribution

1. **No VS Code Required** - Users can run directly with Docker
2. **CI/CD Integration** - Use in GitHub Actions, GitLab CI, Jenkins, etc.
3. **Consistent Environment** - Same container everywhere
4. **Easy Updates** - Users just `docker pull` for latest
5. **Multi-Platform Support** - Works on any system with Docker
6. **Version Control** - Tagged releases for stability
7. **Security Scanning** - Automated vulnerability checks

## Usage Scenarios

### Development Environment
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  yourusername/swarmcontainer:latest \
  bash
```

### CI/CD Pipeline
```yaml
# GitHub Actions example
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: yourusername/swarmcontainer:latest
      options: --cap-add NET_ADMIN --cap-add NET_RAW
    steps:
      - uses: actions/checkout@v3
      - run: claude --dangerously-skip-permissions test
```

### Batch Processing
```bash
docker run --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  yourusername/swarmcontainer:latest \
  claude --dangerously-skip-permissions process
```

## Security Considerations

1. **Never include API keys in the image**
2. **Use secrets management for credentials**
3. **Scan images for vulnerabilities**
4. **Sign images for verification**
5. **Document security presets clearly**
6. **Regular updates for security patches**

## Maintenance

1. **Automated Builds** - Trigger on push to main
2. **Version Tags** - Follow semantic versioning
3. **Security Updates** - Automated PRs for dependency updates
4. **Documentation** - Keep Docker Hub description in sync
5. **Testing** - Test multi-arch builds before release

## Next Steps

1. Set up Docker Hub account and create repository
2. Add secrets to GitHub repository (DOCKER_USERNAME, DOCKER_TOKEN)
3. Create initial Dockerfile in root
4. Test local builds for both architectures
5. Implement GitHub Actions workflow
6. Create first release with v1.0.0 tag
7. Update README with Docker badges and instructions