#!/bin/bash
# Install productivity CLI tools for SwarmContainer
# This script handles architecture-aware installation of modern CLI tools

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installing Productivity CLI Tools${NC}"

# Detect architecture
ARCH=$(dpkg --print-architecture)
echo "📦 Detected architecture: $ARCH"

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Function to install a tool
install_tool() {
    local name=$1
    local url=$2
    local binary=$3
    
    echo -e "${BLUE}Installing $name...${NC}"
    if wget -q "$url" -O download.tar.gz; then
        tar -xzf download.tar.gz
        if [ -f "$binary" ]; then
            chmod +x "$binary"
            mv "$binary" /usr/local/bin/
            echo -e "${GREEN}✓ $name installed${NC}"
        else
            # Try without subdirectory
            if [ -f "$(basename $binary)" ]; then
                chmod +x "$(basename $binary)"
                mv "$(basename $binary)" /usr/local/bin/
                echo -e "${GREEN}✓ $name installed${NC}"
            else
                echo -e "${RED}✗ Failed to find $name binary${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Failed to download $name${NC}"
    fi
    rm -f download.tar.gz
}

# Install lazygit
if [ "$ARCH" = "amd64" ]; then
    install_tool "lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/download/v0.41.0/lazygit_0.41.0_Linux_x86_64.tar.gz" \
        "lazygit"
elif [ "$ARCH" = "arm64" ]; then
    install_tool "lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/download/v0.41.0/lazygit_0.41.0_Linux_arm64.tar.gz" \
        "lazygit"
fi

# Install lazydocker
if [ "$ARCH" = "amd64" ]; then
    install_tool "lazydocker" \
        "https://github.com/jesseduffield/lazydocker/releases/download/v0.23.1/lazydocker_0.23.1_Linux_x86_64.tar.gz" \
        "lazydocker"
elif [ "$ARCH" = "arm64" ]; then
    install_tool "lazydocker" \
        "https://github.com/jesseduffield/lazydocker/releases/download/v0.23.1/lazydocker_0.23.1_Linux_arm64.tar.gz" \
        "lazydocker"
fi

# Install eza (exa successor)
if [ "$ARCH" = "amd64" ]; then
    echo -e "${BLUE}Installing eza...${NC}"
    wget -q "https://github.com/eza-community/eza/releases/download/v0.18.0/eza_x86_64-unknown-linux-gnu.tar.gz" -O eza.tar.gz
    tar -xzf eza.tar.gz
    mv eza /usr/local/bin/
    echo -e "${GREEN}✓ eza installed${NC}"
elif [ "$ARCH" = "arm64" ]; then
    echo -e "${BLUE}Installing eza...${NC}"
    wget -q "https://github.com/eza-community/eza/releases/download/v0.18.0/eza_aarch64-unknown-linux-gnu.tar.gz" -O eza.tar.gz
    tar -xzf eza.tar.gz
    mv eza /usr/local/bin/
    echo -e "${GREEN}✓ eza installed${NC}"
fi

# Install bottom
if [ "$ARCH" = "amd64" ]; then
    install_tool "bottom" \
        "https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_x86_64-unknown-linux-gnu.tar.gz" \
        "btm"
elif [ "$ARCH" = "arm64" ]; then
    install_tool "bottom" \
        "https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_aarch64-unknown-linux-gnu.tar.gz" \
        "btm"
fi

# Install dust
if [ "$ARCH" = "amd64" ]; then
    install_tool "dust" \
        "https://github.com/bootandy/dust/releases/download/v0.8.6/dust-v0.8.6-x86_64-unknown-linux-gnu.tar.gz" \
        "dust-v0.8.6-x86_64-unknown-linux-gnu/dust"
elif [ "$ARCH" = "arm64" ]; then
    install_tool "dust" \
        "https://github.com/bootandy/dust/releases/download/v0.8.6/dust-v0.8.6-aarch64-unknown-linux-gnu.tar.gz" \
        "dust-v0.8.6-aarch64-unknown-linux-gnu/dust"
fi

# Install gping
if [ "$ARCH" = "amd64" ]; then
    echo -e "${BLUE}Installing gping...${NC}"
    if wget -q "https://github.com/orf/gping/releases/download/gping-v1.16.1/gping-Linux-x86_64.tar.gz" -O gping.tar.gz; then
        if tar -xzf gping.tar.gz 2>/dev/null; then
            if [ -f gping ]; then
                mv gping /usr/local/bin/
                chmod +x /usr/local/bin/gping
                echo -e "${GREEN}✓ gping installed${NC}"
            else
                echo -e "${RED}✗ gping binary not found in archive${NC}"
            fi
        else
            echo -e "${RED}✗ Failed to extract gping${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to download gping${NC}"
    fi
elif [ "$ARCH" = "arm64" ]; then
    echo -e "${BLUE}Installing gping...${NC}"
    if wget -q "https://github.com/orf/gping/releases/download/gping-v1.16.1/gping-Linux-aarch64.tar.gz" -O gping.tar.gz; then
        if tar -xzf gping.tar.gz 2>/dev/null; then
            if [ -f gping ]; then
                mv gping /usr/local/bin/
                chmod +x /usr/local/bin/gping
                echo -e "${GREEN}✓ gping installed${NC}"
            else
                echo -e "${RED}✗ gping binary not found in archive${NC}"
            fi
        else
            echo -e "${RED}✗ Failed to extract gping${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to download gping${NC}"
    fi
fi
rm -f gping.tar.gz

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Binary tools installation complete${NC}"