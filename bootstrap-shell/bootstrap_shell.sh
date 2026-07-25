#!/bin/bash

################################################################################
# System Bootstrap Script
################################################################################
#
# Description:
#   This script bootstraps a new Linux system with common tools, configurations,
#   and Docker setup. It clones shell configuration repositories, installs
#   essential packages, sets up Docker, and starts Docker containers.
#
# Usage:
#   ./bootstrap_shell.sh
#
#   After script completes, log out and back in (or reboot) for all changes
#   to take effect.
#
# What it does:
#   - Clones/updates .shell-configs and .shell-scripts repositories
#   - Installs Docker CE via install_docker.sh script
#   - Sets timezone to America/Montreal
#   - Installs essential system packages and utilities
#   - Enables and starts Docker service
#   - Stages any private CA certs into the console build context
#     (see CONSOLE_CA_CERT below); skipped with a warning if none found
#   - Builds (via the devcontainer CLI, so its gh/aws Features actually
#     apply) and starts the personalized console container from
#     ~/.shell-scripts/console, layered on top of the ludorl82/console:latest
#     base image pulled from Docker Hub
#
# Optional environment:
#   CONSOLE_CA_CERT - path to a private CA's *public* cert to trust inside the
#     console container. Defaults to the local CAs this host already trusts
#     (/usr/local/share/ca-certificates/*.crt). Certs are never committed --
#     this repo is public.
#
# Requirements:
#   - Root/sudo access
#   - Internet connection
#   - Git installed
#
# Prerequisites:
#   The following must exist before running this script:
#   - GitHub repositories: ludorl82/.shell-configs and ludorl82/.shell-scripts
#   - $HOME/.shell-scripts/scripts/install_docker.sh
#
################################################################################

set -euo pipefail

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "Cannot detect OS"
    exit 1
fi

# Detect architecture
ARCH=$(dpkg --print-architecture)

# Validate OS
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "Error: This script only supports Ubuntu and Debian"
    echo "Detected OS: $OS"
    exit 1
fi

# Validate architecture
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "Error: This script only supports amd64 and arm64 architectures"
    echo "Detected architecture: $ARCH"
    exit 1
fi

echo "========================================="
echo "System Bootstrap Script"
echo "========================================="
echo "Detected OS: $OS $OS_VERSION"
echo "Detected Architecture: $ARCH"
echo "========================================="
echo ""

# Clone or update .shell-configs, .shell-scripts
echo "Setting up shell configurations..."
for repo in configs scripts; do
  if [[ ! -d $HOME/.shell-$repo ]]; then
    echo "Cloning .shell-$repo..."
    git clone https://github.com/ludorl82/.shell-$repo.git $HOME/.shell-$repo
  else
    echo "Updating .shell-$repo..."
    git -C $HOME/.shell-$repo pull
  fi
done
echo ""

# Install docker
echo "Installing Docker..."
if [[ -f $HOME/.shell-scripts/scripts/install_docker.sh ]]; then
    $HOME/.shell-scripts/scripts/install_docker.sh
else
    echo "Error: install_docker.sh not found at $HOME/.shell-scripts/scripts/"
    exit 1
fi
echo ""

# Set timezone
echo "Setting timezone to America/Montreal..."
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/Montreal /etc/localtime
echo ""

# Installing packages
echo "Updating system and installing packages..."
sudo apt update && sudo apt upgrade -y

# Determine correct docker-compose package name based on OS and version
DOCKER_COMPOSE_PKG="docker-compose-plugin"
if [[ "$OS" == "debian" && "$OS_VERSION" == "11" ]] || [[ "$OS" == "ubuntu" && "${OS_VERSION%%.*}" -lt 22 ]]; then
    DOCKER_COMPOSE_PKG="docker-compose"
fi

sudo apt install -y openssh-server iftop mtr telnet squid \
                    ruby-full nodejs npm $DOCKER_COMPOSE_PKG
echo ""

# Build docker images
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
echo ""

if [[ -d "$HOME/.shell-scripts/console" ]]; then
    # Stage any private CA certs into the image build context, so the container
    # trusts internal TLS hosts instead of needing verify=False. The certs are
    # not in git (this repo is public), so take them from this host: an explicit
    # $CONSOLE_CA_CERT if set, otherwise whatever local CAs the host itself
    # already trusts. Missing is not fatal -- the build then just yields an
    # image without that trust.
    echo "Staging private CA certs into the console build context..."
    CA_DEST="$HOME/.shell-scripts/console/ca-certs"
    CA_HOST_STORE="/usr/local/share/ca-certificates"
    mkdir -p "$CA_DEST"
    rm -f "$CA_DEST"/*.crt
    ca_staged=0
    for ca_src in "${CONSOLE_CA_CERT:-}" "$CA_HOST_STORE"/*.crt; do
        [[ -n "$ca_src" && -f "$ca_src" ]] || continue
        # Never stage a file carrying key material: it would stay readable in
        # the image and travel with every push of it.
        if grep -q "PRIVATE KEY" "$ca_src"; then
            echo "  Refusing $(basename "$ca_src") -- it contains a private key."
            continue
        fi
        if command -v openssl >/dev/null && ! openssl x509 -in "$ca_src" -noout 2>/dev/null; then
            echo "  Skipping $(basename "$ca_src") -- not a readable certificate."
            continue
        fi
        install -m 0644 "$ca_src" "$CA_DEST/$(basename "$ca_src")"
        echo "  Staged $(basename "$ca_src")"
        ca_staged=$((ca_staged + 1))
    done
    if [[ "$ca_staged" -eq 0 ]]; then
        echo "  Warning: no private CA cert found on this host."
        echo "  The console container will not trust internal TLS hosts."
        echo "  Set CONSOLE_CA_CERT=/path/to/ca.crt and re-run to add one."
    fi
    echo ""

    echo "Building and starting the personalized console container..."
    cd "$HOME/.shell-scripts/console"

    # Check if docker-compose or docker compose is available
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi

    # Plain `docker compose build` skips this image's devcontainer Features
    # (github-cli, aws-cli) -- build through the devcontainer CLI instead,
    # which applies them and re-pulls the ludorl82/console:latest base
    # fresh from Docker Hub every time, then let compose just run the
    # already-tagged image.
    export GID="$(id -g)"
    /usr/bin/newgrp docker <<EONG
npx --yes @devcontainers/cli build --workspace-folder . --image-name ludorl82/console-personal:latest
$COMPOSE_CMD up -d
EONG
    echo ""
else
    echo "Warning: $HOME/.shell-scripts/console directory not found. Skipping Docker container setup."
    echo ""
fi

echo "========================================="
echo "Bootstrap complete!"
echo "========================================="
echo "Please log out and back in (or reboot) for all changes to take effect."
echo ""
