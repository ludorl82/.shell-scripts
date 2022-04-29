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
 
# Installing packages
sudo apt install -y openssh-server iftop mtr telnet squid open-vm-tools

# Install tmux
sudo apt update && sudo apt install -y git automake build-essential pkg-config libevent-dev libncurses5-dev byacc bison
rm -fr /tmp/tmux
git clone https://github.com/tmux/tmux.git /tmp/tmux
cd /tmp/tmux
git checkout 3.0
sh autogen.sh
./configure && make
sudo make install
cd -
rm -fr /tmp/tmux
