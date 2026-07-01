#!/bin/bash

# Detects $OS, $OS_VERSION, $ARCH and validates they're supported.
# Source this file; it exits the calling script on unsupported platforms.

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "Cannot detect OS"
    exit 1
fi

ARCH=$(dpkg --print-architecture)

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "Error: This script only supports Ubuntu and Debian"
    echo "Detected OS: $OS"
    exit 1
fi

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "Error: This script only supports amd64 and arm64 architectures"
    echo "Detected architecture: $ARCH"
    exit 1
fi
