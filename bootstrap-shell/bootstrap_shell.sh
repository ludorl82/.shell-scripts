#!/bin/bash

# Clone or update .shell-configs, .shell-scripts and save git creds
for repo in configs scripts; do
  if [[ ! -d $HOME/.shell-$repo ]]; then
    git clone https://github.com/ludorl82/.shell-$repo.git $HOME/.shell-$repo
  else
    git -C $HOME/.shell-$repo pull
  fi
done

# Install docker
$HOME/.shell-scripts/scripts/install_docker.sh
newgrp docker

# Set timezone
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/Montreal /etc/localtime
 
# Installing packages
sudo apt update & sudo apt upgrade -y
sudo apt install -y openssh-server iftop mtr telnet squid open-vm-tools \
                    ruby-full docker-compose

# Build docker images
git clone https://github.com/ludorl82/.shell-configs.git
git clone https://github.com/ludorl82/.shell-scripts.git
cd ~/.shell-scripts/build-tools
docker-compose up -d
