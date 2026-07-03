FROM ludorl82/console:v1.1.0

ARG USER
ARG UID=1000
ARG GID=1000

# Install GitHub CLI (gh) from its official apt repo
RUN set -eux; \
    (type -p wget >/dev/null || (apt-get update && apt-get install -y wget)); \
    mkdir -p -m 755 /etc/apt/keyrings; \
    wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg; \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y gh; \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (official installer, arch-aware)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip curl; \
    ARCH=$(dpkg --print-architecture); \
    case "$ARCH" in \
      amd64) AWS_ARCH=x86_64 ;; \
      arm64) AWS_ARCH=aarch64 ;; \
      *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscliv2.zip; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/awscliv2.zip /tmp/aws; \
    rm -rf /var/lib/apt/lists/*

# Remove or rename existing ubuntu user and group if they exist
# Then create new user with the specified name
RUN set -eux; \
    # Remove ubuntu user if exists
    if getent passwd ubuntu >/dev/null; then userdel -r ubuntu 2>/dev/null || true; fi; \
    # Remove ubuntu group if exists and no users depend on it
    if getent group ubuntu >/dev/null; then groupdel ubuntu 2>/dev/null || true; fi; \
    # Create new group with GID if it doesn't exist
    if ! getent group "$USER" >/dev/null; then groupadd -g "$GID" "$USER"; fi; \
    # Create new user
    if getent passwd "$USER" >/dev/null; then \
      usermod -d /home/"$USER" -s /usr/bin/zsh -u "$UID" -g "$GID" -aG docker,sudo "$USER"; \
    else \
      useradd -m -d /home/"$USER" -s /usr/bin/zsh -u "$UID" -g "$GID" -G docker,sudo "$USER"; \
    fi; \
    # Rename ubuntu home directory if it exists
    if [ -d /home/ubuntu ] && [ ! -d /home/"$USER" ]; then \
      mv /home/ubuntu /home/"$USER"; \
    fi; \
    # Ensure home directory exists and has correct ownership
    mkdir -p /home/"$USER"; \
    chown -R "$USER":"$USER" /home/"$USER"

# Retain USER at runtime (ARGs aren't available in the running container) so
# entrypoint.sh knows which account to set the password for.
ENV CONSOLE_USER=${USER}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
