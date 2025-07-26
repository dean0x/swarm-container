#!/bin/bash
# Module: Claude Code Initialization
# Purpose: Initialize Claude Code if API key is available

echo "🤖 Checking Claude Code configuration..."

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "🤖 Initializing Claude Code..."
    claude --version
    echo "✅ Claude Code initialized"
else
    echo "⚠️  ANTHROPIC_API_KEY not set. You have two options:"
    echo "   Option 1: Browser login after activating Claude Code"
    echo "   Option 2: Set it by running: export ANTHROPIC_API_KEY='your-api-key'"
fi