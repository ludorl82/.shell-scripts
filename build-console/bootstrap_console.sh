#!/bin/bash

cd ~/

# Install packages
apt update && export DEBIAN_FRONTEND=noninteractive && \
  export TZ=America/Montreal && \
  apt install -y software-properties-common zsh ruby-full python3-pip \
  iftop mtr telnet squid rsync bind9-dnsutils open-vm-tools \
  libnss-ldap libpam-ldap ldap-utils jq exuberant-ctags
add-apt-repository ppa:neovim-ppa/stable 
apt upgrade && apt install -y neovim

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && rm -f install.sh

# Install tmuxinator
gem install tmuxinator
pip3 install --user virtualenvwrapper

# Installing fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install docker
apt -y install curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt -y install docker-ce-cli

# Add yourself to docker group
usermod -aG docker $(whoami)
newgrp docker

# Install tmux
apt update && apt install -y git automake build-essential pkg-config libevent-dev libncurses5-dev byacc bison
rm -fr /tmp/tmux
git clone https://github.com/tmux/tmux.git /tmp/tmux
cd /tmp/tmux
git checkout 3.0
sh autogen.sh
./configure && make
make install
cd -
rm -fr /tmp/tmux
