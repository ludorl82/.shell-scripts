FROM ludorl82/console:latest

ARG USER
ARG UID=1000
ARG GID=1000

# GitHub CLI (gh) and AWS CLI v2 are provisioned by devcontainer Features
# (github-cli, aws-cli) -- see .devcontainer/devcontainer.json. Building this
# Dockerfile directly with `docker build`/`docker compose build` (bypassing
# the devcontainer CLI) skips those Features; use `devcontainer build` for a
# complete image.

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
# entrypoint.sh knows which account to set the password for. Overrides the
# base image's own CONSOLE_USER=ubuntu.
ENV CONSOLE_USER=${USER}

# entrypoint.sh, ENTRYPOINT and CMD are inherited from ludorl82/console --
# no need to redeclare them here, and doing so would risk silently
# overwriting the base's entrypoint.sh (e.g. its docker-init.sh chaining)
# with a stale local copy.
