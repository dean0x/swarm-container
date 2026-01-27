# Multi-stage Dockerfile for SwarmContainer
# - base: Common setup for all deployments
# - local: VS Code Dev Container (default)

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
    && echo "$SNIPPET" >> "/root/.zshrc"

# Configure npm global directory (running as root)
RUN mkdir -p /root/.npm-global && \
    npm config set prefix '/root/.npm-global' && \
    echo 'export PATH=/root/.npm-global/bin:$PATH' >> /root/.bashrc && \
    echo 'export PATH=/root/.npm-global/bin:$PATH' >> /root/.zshrc

# Install global npm packages
# Most versions pinned for reproducible builds; claude-code uses latest
RUN npm install -g \
    @anthropic-ai/claude-code \
    npm-check-updates@17.1.3 \
    typescript@5.3.3 \
    ts-node@10.9.2 \
    nodemon@3.0.3

# Install productivity CLI tools via apt
RUN apt-get update && apt-get install -y \
    jq \
    httpie \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y \
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
    cargo install mcfly --locked && \
    # Move binaries to system-wide location
    mv /root/.cargo/bin/zoxide /usr/local/bin/ && \
    mv /root/.cargo/bin/tokei /usr/local/bin/ && \
    mv /root/.cargo/bin/mcfly /usr/local/bin/ && \
    chmod +x /usr/local/bin/zoxide /usr/local/bin/tokei /usr/local/bin/mcfly

# Install productivity tools via npm
# Pin tldr version for reproducible builds
RUN npm install -g tldr@3.4.0

# Copy and run architecture-aware binary installation script
COPY scripts/install-productivity-tools.sh /tmp/install-productivity-tools.sh
RUN chmod +x /tmp/install-productivity-tools.sh && \
    /tmp/install-productivity-tools.sh && \
    rm /tmp/install-productivity-tools.sh


# Create workspace directory
RUN mkdir -p /workspace

# Copy shared library scripts
COPY scripts/lib/logging.sh /scripts/lib/logging.sh
RUN chmod +x /scripts/lib/logging.sh

# Copy security initialization scripts
COPY scripts/security/init-security.sh /scripts/security/init-security.sh
COPY scripts/security/security-config.json /scripts/security/security-config.json
COPY scripts/security/refresh-dns-rules.sh /scripts/security/refresh-dns-rules.sh
RUN chmod +x /scripts/security/init-security.sh /scripts/security/refresh-dns-rules.sh

# Copy hook scripts
COPY scripts/hooks/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/hooks/set-node-memory.sh /scripts/hooks/set-node-memory.sh
COPY scripts/health-check.sh /scripts/health-check.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /scripts/hooks/set-node-memory.sh /scripts/health-check.sh

# Tmux removed - using VS Code pane splitting instead

# Set working directory
WORKDIR /workspace

# Configure git to use delta
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

# Set entrypoint - runs as root for security initialization
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

# Running as root - no USER directive needed

# Local development stage - preserves current functionality
FROM base AS local
# No additional changes needed - inherits everything from base