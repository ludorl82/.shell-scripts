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
#   - Builds and starts Docker containers from ~/git/console
#
# Requirements:
#   - Root/sudo access
#   - Internet connection
#   - Git installed
#   - ~/git/console directory with docker-compose.yml
#
# Prerequisites:
#   The following must exist before running this script:
#   - GitHub repositories: ludorl82/.shell-configs and ludorl82/.shell-scripts
#   - $HOME/.shell-scripts/scripts/install_docker.sh
#   - $HOME/git/console/docker-compose.yml (or compose.yaml)
#
################################################################################

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
                    ruby-full $DOCKER_COMPOSE_PKG
echo ""

# Build docker images
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
echo ""

if [[ -d ~/git/console ]]; then
    echo "Building and starting Docker containers..."
    cd ~/git/console
    
    # Check if docker-compose or docker compose is available
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    /usr/bin/newgrp docker <<EONG
$COMPOSE_CMD up -d
EONG
    echo ""
else
    echo "Warning: ~/git/console directory not found. Skipping Docker container setup."
    echo ""
fi

echo "========================================="
echo "Bootstrap complete!"
echo "========================================="
echo "Please log out and back in (or reboot) for all changes to take effect."
echo ""
