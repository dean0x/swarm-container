# Multi-stage Dockerfile for SwarmContainer
# - base: Common setup for all deployments
# - local: VS Code Dev Container (default)
# - remote: Fly.io SSH deployment (future)

FROM mcr.microsoft.com/devcontainers/javascript-node:20-bullseye AS base

# Install essential tools and security utilities
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    git \
    jq \
    gettext-base \
    ripgrep \
    fd-find \
    bat \
    fzf \
    zsh \
    net-tools \
    dnsutils \
    iputils-ping \
    iptables \
    ipset \
    auditd \
    apparmor \
    apparmor-utils \
    libcap2-bin \
    inotify-tools \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install git-delta for better diffs (handle both amd64 and arm64)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then \
        wget -q https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-x86_64-unknown-linux-gnu.tar.gz \
        && tar -xzf delta-0.16.5-x86_64-unknown-linux-gnu.tar.gz \
        && mv delta-0.16.5-x86_64-unknown-linux-gnu/delta /usr/local/bin/ \
        && rm -rf delta-0.16.5-x86_64-unknown-linux-gnu*; \
    elif [ "$ARCH" = "arm64" ]; then \
        wget -q https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-aarch64-unknown-linux-gnu.tar.gz \
        && tar -xzf delta-0.16.5-aarch64-unknown-linux-gnu.tar.gz \
        && mv delta-0.16.5-aarch64-unknown-linux-gnu/delta /usr/local/bin/ \
        && rm -rf delta-0.16.5-aarch64-unknown-linux-gnu*; \
    fi

# Set up command history persistence
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.zsh_history" \
    && mkdir -p /commandhistory \
    && touch /commandhistory/.zsh_history \
    && chown -R node:node /commandhistory \
    && echo "$SNIPPET" >> "/home/node/.zshrc"

# Install global npm packages
RUN npm install -g \
    @anthropic-ai/claude-code \
    npm-check-updates \
    typescript \
    ts-node \
    nodemon

# Install gosu for privilege dropping (su-exec not in Debian repos)
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Install productivity CLI tools via apt
RUN apt-get update && apt-get install -y \
    jq \
    httpie \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for cargo-based tools (if not already present)
RUN if ! command -v cargo &> /dev/null; then \
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
        . $HOME/.cargo/env; \
    fi

# Add cargo to PATH for this RUN command
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Rust-based productivity tools
RUN cargo install zoxide --locked && \
    cargo install tokei --locked && \
    cargo install mcfly --locked

# Install productivity tools via npm
RUN npm install -g tldr

# Copy and run architecture-aware binary installation script
COPY scripts/install-productivity-tools.sh /tmp/install-productivity-tools.sh
RUN chmod +x /tmp/install-productivity-tools.sh && \
    /tmp/install-productivity-tools.sh && \
    rm /tmp/install-productivity-tools.sh

# Create workspace directory and ensure node user has proper shell
RUN mkdir -p /workspace && chown -R node:node /workspace \
    && usermod -s /bin/bash node || true

# Copy security initialization scripts
COPY scripts/security/init-security.sh /scripts/security/init-security.sh
COPY scripts/security/security-config.json /scripts/security/security-config.json
RUN chmod +x /scripts/security/init-security.sh

# Copy hook scripts
COPY scripts/hooks/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/hooks/set-node-memory.sh /scripts/hooks/set-node-memory.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /scripts/hooks/set-node-memory.sh

# Tmux removed - using VS Code pane splitting instead

# Set working directory
WORKDIR /workspace

# Configure git to use delta (as root for now)
RUN git config --global core.pager "delta" \
    && git config --global interactive.diffFilter "delta --color-only" \
    && git config --global delta.navigate true \
    && git config --global delta.light false \
    && git config --global delta.line-numbers true

# Set environment variables
ENV DEVCONTAINER=true
ENV SHELL=/bin/zsh
ENV NODE_ENV=development
# NODE_OPTIONS will be set dynamically based on container memory

# Set entrypoint - this runs as root since we haven't switched users yet
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

# Note: USER directive removed - the entrypoint handles user switching

# Local development stage - preserves current functionality
FROM base AS local
# No additional changes needed - inherits everything from base

# Remote development stage for Fly.io
FROM base AS remote

# Install SSH server and sudo
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd

# Add passwordless sudo for node user
RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH for security
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers node" >> /etc/ssh/sshd_config

# Enhanced SSH security configuration
RUN echo "# Security hardening" >> /etc/ssh/sshd_config \
    && echo "Protocol 2" >> /etc/ssh/sshd_config \
    && echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config \
    && echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config \
    && echo "MaxAuthTries 3" >> /etc/ssh/sshd_config \
    && echo "MaxSessions 10" >> /etc/ssh/sshd_config \
    && echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config \
    && echo "X11Forwarding no" >> /etc/ssh/sshd_config \
    && echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config \
    && echo "PermitTunnel no" >> /etc/ssh/sshd_config \
    && echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config

# Create login banner
RUN echo "****************************************************" > /etc/ssh/banner \
    && echo "* SwarmContainer Development Environment           *" >> /etc/ssh/banner \
    && echo "* Authorized access only. All actions logged.     *" >> /etc/ssh/banner \
    && echo "****************************************************" >> /etc/ssh/banner

# Generate SSH host keys during build
RUN ssh-keygen -A

# Create .ssh directory for node user
RUN mkdir -p /home/node/.ssh && \
    chown -R node:node /home/node/.ssh && \
    chmod 700 /home/node/.ssh

# Will be overridden by fly-entrypoint.sh
COPY --chown=node:node fly-entrypoint.sh /fly-entrypoint.sh
RUN chmod +x /fly-entrypoint.sh

# Switch to node user
USER node
WORKDIR /workspace

# SSH runs on port 22
EXPOSE 22

ENTRYPOINT ["/fly-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]