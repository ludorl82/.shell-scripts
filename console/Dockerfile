FROM ludorl82/console:latest

ARG USER
ARG UID=1000
ARG GID=1000

# All tooling (gh, aws, tofu) is installed via plain RUN steps below -- no
# devcontainer Features. An earlier revision provisioned gh/aws through
# Features, which meant a plain `docker build`/`docker compose build` silently
# produced an image without them; anything the image needs now lives in this
# file, and any builder yields a complete image.

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

# kubectl, from the official release binaries. It was never in this image
# before 2026-07-25 — it had been installed by hand in the running container,
# which the first image-recreate silently wiped. TARGETARCH (amd64/arm64)
# matches dl.k8s.io's artifact naming directly.
ARG TARGETARCH
RUN KVER="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" && \
    curl -fsSL -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KVER}/bin/linux/${TARGETARCH:-$(dpkg --print-architecture)}/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client >/dev/null

# GitHub CLI, from its official apt repo (per cli/cli install_linux.md).
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# AWS CLI v2, from the official zip installer (there is no apt package for v2).
# $(uname -m) resolves to x86_64 / aarch64, matching Amazon's artifact names,
# so this works for both architectures of the base image.
RUN cd /tmp && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o awscliv2.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    aws --version

# OpenTofu, via its official installer script (the aws-iac and cloudflare-iac
# repos are pinned to OpenTofu, not Terraform, for its native S3 state locking,
# which needs >=1.10).
#
# The script is used rather than a hand-rolled apt-repo/gpg setup -- an earlier
# version of this step hardcoded those URLs from memory and got the repo
# signing-key URL wrong (get.opentofu.org/opentofu-repo.gpg does not exist; the
# real one is packages.opentofu.org/opentofu/tofu/gpgkey). Letting upstream's
# own script own those details avoids repeating that.
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
