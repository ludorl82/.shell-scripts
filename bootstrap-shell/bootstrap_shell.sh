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

# Set timezone
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/Montreal /etc/localtime
 
# Installing packages
sudo apt install -y openssh-server iftop mtr telnet squid open-vm-tools ruby-full

# Install tmux
sudo apt update && sudo apt install -y git automake build-essential pkg-config libevent-dev libncurses5-dev byacc bison zsh
rm -fr /tmp/tmux
git clone https://github.com/tmux/tmux.git /tmp/tmux
cd /tmp/tmux
git checkout 3.0
sh autogen.sh
./configure && make
sudo make install
cd -
rm -fr /tmp/tmux

# Install tmuxinator
sudo gem install tmuxinator

# Install configs
$HOME/.shell-scripts/scripts/upgrade_shell.sh
