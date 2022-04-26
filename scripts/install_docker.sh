#!/bin/bash

################################################################################
# Docker Installation Script
################################################################################
#
# Description:
#   This script automatically installs Docker CE (Community Edition) on 
#   supported Linux distributions. It detects the OS and system architecture
#   automatically and configures the appropriate Docker repository.
#
# Usage:
#   ./install_docker.sh
#
#   After installation completes, log out and back in (or reboot) for docker 
#   group membership to take effect.
#
# What it does:
#   - Installs Docker CE, Docker CLI, and containerd
#   - Adds the official Docker repository for your OS
#   - Adds the current user to the docker group (allows running docker without sudo)
#
# Requirements:
#   - Root/sudo access
#   - Internet connection
#   - curl and gpg (installed automatically if missing)
#
################################################################################

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

# Detect architecture
ARCH=$(dpkg --print-architecture)

# Validate OS
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "This script only supports Ubuntu and Debian"
    exit 1
fi

# Validate architecture
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "This script only supports amd64 and arm64 architectures"
    exit 1
fi

echo "Detected OS: $OS"
echo "Detected Architecture: $ARCH"

# Install Docker
sudo apt -y install curl
curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io

# Add yourself to docker group
sudo usermod -aG docker $(whoami)

echo "Docker installation complete. Please log out and back in for group membership to take effect."
