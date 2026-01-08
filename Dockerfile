# Mobile Dev Pod - SSH/mosh access with Claude Code
FROM ubuntu:24.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Australia/Melbourne

# Install system packages
RUN apt-get update && apt-get install -y \
    # SSH and remote access
    openssh-server \
    mosh \
    # Terminal multiplexer
    tmux \
    # Development essentials
    git \
    curl \
    wget \
    vim \
    nano \
    # Build tools
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    # Utilities
    jq \
    fzf \
    ripgrep \
    fd-find \
    htop \
    locales \
    ca-certificates \
    gnupg \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user 'dev' with UID 1000
RUN useradd -m -s /bin/bash -u 1000 dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# Configure SSH
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers dev" >> /etc/ssh/sshd_config

# SSH port
EXPOSE 22/tcp
# Mosh UDP port range
EXPOSE 60000-60010/udp

# Create directories for Claude Code hooks
RUN mkdir -p /home/dev/.claude/hooks \
    && chown -R dev:dev /home/dev/.claude

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default to dev user home
WORKDIR /home/dev

# Entrypoint handles SSH key setup and service startup
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
