FROM ludorl82/console:latest

ARG USER
ARG UID=1000
ARG GID=1000

# GitHub CLI (gh) and AWS CLI v2 are provisioned by devcontainer Features
# (github-cli, aws-cli) -- see .devcontainer/devcontainer.json. Building this
# Dockerfile directly with `docker build`/`docker compose build` (bypassing
# the devcontainer CLI) skips those Features; use `devcontainer build` for a
# complete image.

# Trust the internal private CA so curl/Python/Node inside the container verify
# internal TLS hosts for real, instead of needing verify=False / ignoreTls.
#
# The cert files are deliberately NOT committed (this repo is public and they
# carry internal PKI metadata) -- console/ca-certs/*.crt is gitignored, and
# bootstrap_shell.sh populates it from the host before building. The whole
# directory is COPYed rather than a named file so the build still succeeds when
# it holds nothing but .gitkeep; you just get an image without that trust.
# Public certs only -- never put a private key in the build context, it stays
# readable in the image and travels with every push of it.
COPY ca-certs/ /usr/local/share/ca-certificates/
RUN rm -f /usr/local/share/ca-certificates/.gitkeep; \
    chmod 0644 /usr/local/share/ca-certificates/*.crt 2>/dev/null || true; \
    update-ca-certificates

# OpenTofu (not a devcontainer Feature: there is no official one, and the
# Terraform Feature installs Terraform, not this fork -- the aws-iac and
# cloudflare-iac repos are pinned to OpenTofu specifically for its native S3
# state locking, which needs >=1.10). Installed here via RUN rather than a
# Feature so it is present even on a plain `docker build`/`docker compose
# build`, which -- per the note above -- already skips the gh/aws-cli
# Features.
#
# Uses the official installer script rather than a hand-rolled apt-repo/gpg
# setup -- an earlier version of this step hardcoded those URLs from memory
# and got the repo signing-key URL wrong (get.opentofu.org/opentofu-repo.gpg
# does not exist; the real one is packages.opentofu.org/opentofu/tofu/gpgkey).
# Letting upstream's own script own those details avoids repeating that.
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh && \
    chmod +x /tmp/install-opentofu.sh && \
    /tmp/install-opentofu.sh --install-method deb && \
    rm -f /tmp/install-opentofu.sh && \
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
    chown -R "$USER":"$USER" /home/"$USER"; \
    # Passwordless sudo for this user
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd-"$USER"; \
    chmod 0440 /etc/sudoers.d/nopasswd-"$USER"; \
    visudo -cf /etc/sudoers.d/nopasswd-"$USER"

# Retain USER at runtime (ARGs aren't available in the running container) so
# entrypoint.sh knows which account to set the password for. Overrides the
# base image's own CONSOLE_USER=ubuntu.
ENV CONSOLE_USER=${USER}

# entrypoint.sh, ENTRYPOINT and CMD are inherited from ludorl82/console --
# no need to redeclare them here, and doing so would risk silently
# overwriting the base's entrypoint.sh (e.g. its docker-init.sh chaining)
# with a stale local copy.
