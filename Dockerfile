FROM mcr.microsoft.com/devcontainers/javascript-node:20-bullseye

# Install essential tools and security utilities
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    git \
    jq \
    ripgrep \
    fd-find \
    bat \
    fzf \
    zsh \
    tmux \
    htop \
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
    && chown -R node:node /commandhistory \
    && echo "$SNIPPET" >> "/home/node/.zshrc"

# Install global npm packages
RUN npm install -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    @google/gemini-cli \
    npm-check-updates \
    typescript \
    ts-node \
    nodemon

# Note: claude-flow will be cloned to workspace and installed from there
# This allows developers to work with the source code directly

# Install gosu for privilege dropping (su-exec not in Debian repos)
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Create workspace directory and ensure node user has proper shell
RUN mkdir -p /workspace && chown -R node:node /workspace \
    && usermod -s /bin/bash node || true

# Copy security initialization scripts
COPY scripts/security/init-security.sh /scripts/security/init-security.sh
COPY scripts/security/security-config.json /scripts/security/security-config.json
RUN chmod +x /scripts/security/init-security.sh

# Copy and setup entrypoint script
COPY scripts/hooks/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

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
# Increase Node.js memory limit to prevent OOM errors
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Set entrypoint - this runs as root since we haven't switched users yet
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

# Note: USER directive removed - the entrypoint handles user switching