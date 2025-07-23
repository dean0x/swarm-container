#!/bin/bash
# Module: NPM Configuration
# Purpose: Configure npm settings for the container

echo "📦 Configuring npm..."

# Configure npm registry
npm config set registry https://registry.npmjs.org/

# Additional npm configurations can be added here
# npm config set cache /workspace/.npm-cache
# npm config set prefix /workspace/.npm-global

echo "✅ NPM configured successfully"