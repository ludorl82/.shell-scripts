#!/bin/bash

# Clone or update .shell-configs and save git creds
if [[ ! -d $HOME/.shell-configs ]]; then
	git clone https://github.com/ludorl82/.shell-configs.git $HOME/.shell-configs
else
	git -C $HOME/.shell-configs pull
fi

# Install docker
bash $HOME/.shell-scripts/scripts/install_docker.sh

# Set timezone
sudo timedatectl set-timezone America/Montreal
 
# Installing openssh-server
sudo apt install -y openssh-server
