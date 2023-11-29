#!/bin/bash
CONFIGS_DIR="$HOME/.shell-configs/configs"
SCRIPTS_DIR="$HOME/.shell-scripts/scripts"
VIM_PLUGINS_DIR="$HOME/.config/nvim/pack/bundle/start"
ZSH_DIR="$HOME/.zsh"
ZSH_PLUGINS_DIR="$ZSH_DIR/plugins"
ZSH_THEMES_DIR="$ZSH_DIR/themes"
TMUX_DIR=$HOME/.tmux
TMUX_PLUGINS_DIR=$TMUX_DIR/plugins

# Upgrade vim plugins
mkdir -p $VIM_PLUGINS_DIR
cd $VIM_PLUGINS_DIR
[ ! -d $VIM_PLUGINS_DIR/awesome-vim-colorschemes ] && git clone https://github.com/rafi/awesome-vim-colorschemes.git
[ ! -d $VIM_PLUGINS_DIR/coc.nvim ] && git clone https://github.com/neoclide/coc.nvim.git
[ ! -d $VIM_PLUGINS_DIR/copilot.vim ] && git clone https://github.com/github/copilot.vim
[ ! -d $VIM_PLUGINS_DIR/fzf.vim ] && git clone https://github.com/junegunn/fzf.vim.git
[ ! -d $VIM_PLUGINS_DIR/nerdtree ] && git clone https://github.com/preservim/nerdtree.git
[ ! -d $VIM_PLUGINS_DIR/vim-airline ] && git clone https://github.com/vim-airline/vim-airline.git
[ ! -d $VIM_PLUGINS_DIR/vim-devicons ] && git clone https://github.com/ryanoasis/vim-devicons.git
[ ! -d $VIM_PLUGINS_DIR/vim-fugitive ] && git clone https://github.com/tpope/vim-fugitive.git
[ ! -d $VIM_PLUGINS_DIR/vim-gitgutter ] && git clone https://github.com/airblade/vim-gitgutter.git
[ ! -d $VIM_PLUGINS_DIR/vim-matchit ] && git clone https://github.com/adelarsq/vim-matchit.git
[ ! -d $VIM_PLUGINS_DIR/vim-terraform ] && git clone https://github.com/hashivim/vim-terraform.git
[ ! -d $VIM_PLUGINS_DIR/vim-tmux-navigator ] && git clone https://github.com/christoomey/vim-tmux-navigator.git
find $VIM_PLUGINS_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull \;

# Sync nvim configs
rsync -avh "${CONFIGS_DIR}/.console.config/nvim/" $HOME/.config/nvim

cd ~/.config/nvim/pack/bundle/start/coc.nvim/
yarn install
yarn build

# Upgrade zsh plugins
mkdir -p $ZSH_PLUGINS_DIR
cd $ZSH_PLUGINS_DIR
[ ! -d $ZSH_PLUGINS_DIR/fzf ] && git clone https://github.com/junegunn/fzf.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-vi-mode ] && git clone https://github.com/jeffreytse/zsh-vi-mode.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-kubectl-prompt ] && git clone https://github.com/superbrothers/zsh-kubectl-prompt.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-autocomplete ] && git clone https://github.com/marlonrichert/zsh-autocomplete.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-syntax-highlighting ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions.git
find $ZSH_PLUGINS_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull --ff-only \;

# Upgrade zsh themes
mkdir -p $ZSH_THEMES_DIR
cd $ZSH_THEMES_DIR
[ ! -d $ZSH_THEMES_DIR/agnoster-zsh-theme ] && git clone https://github.com/agnoster/agnoster-zsh-theme.git
find $ZSH_THEMES_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull --ff-only \;

# ZSH configs import
cp $CONFIGS_DIR/.console.zshrc.zsh $ZSH_DIR/zshrc.zsh
cp $CONFIGS_DIR/.console.Linux.zsh $ZSH_DIR/Linux.zsh
cp $CONFIGS_DIR/.console.aliases.zsh $ZSH_DIR/aliases.zsh
cp $CONFIGS_DIR/.console.fzf.zsh $ZSH_DIR/fzf.zsh
cp $CONFIGS_DIR/.console.ludorl82.zsh $ZSH_DIR/ludorl82.zsh
cp $CONFIGS_DIR/.console.bindings.zsh $ZSH_DIR/bindings.zsh
rm -f $HOME/.zshrc && ln -s -T $ZSH_DIR/zshrc.zsh $HOME/.zshrc
rm -f $HOME/.fzf.zsh && ln -s -T $ZSH_DIR/fzf.zsh $HOME/.fzf.zsh

# Upgrade tmux plugins
mkdir -p $TMUX_PLUGINS_DIR
cd $TMUX_PLUGINS_DIR
[ ! -d $TMUX_PLUGINS_DIR/tmux-themepack ] && git clone https://github.com/jimeh/tmux-themepack.git
[ ! -d $TMUX_PLUGINS_DIR/tmux-yank ] && git clone https://github.com/tmux-plugins/tmux-yank.git
find $TMUX_PLUGINS_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull --ff-only \;

# Tmux configs import
cp $CONFIGS_DIR/.console.tmux.conf $TMUX_DIR/.tmux.conf
cp $CONFIGS_DIR/.console.tmux.console.conf $TMUX_DIR/.tmux.console.conf
cp $CONFIGS_DIR/.console.tmux.keys.conf $TMUX_DIR/.tmux.keys.conf
cp $CONFIGS_DIR/.console.tmux.Linux.conf $TMUX_DIR/.tmux.Linux.conf
cp $CONFIGS_DIR/.console.gitmux.conf $TMUX_DIR/.gitmux.conf
rsync -avh "$CONFIGS_DIR/.console.config/tmuxinator/" $HOME/.config/tmuxinator --delete
[ ! -e $HOME/.tmux.conf ] && ln -s -T $TMUX_DIR/.tmux.conf $HOME/.tmux.conf
mkdir -p $HOME/tmp

# Ensure SSH configs are done
SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG1="X11Forwarding yes"
SSH_CONFIG2="X11DisplayOffset 10"
SSH_CONFIG3="X11UseLocalhost no"
SSH_CONFIG4="AcceptEnv LANG LC_* ENV CLIENT DISPLAY"
if [[ "$(grep "^$SSH_CONFIG1" $SSHD_CONFIG | wc -l)" == "0" ]]; then
  echo "${SSH_CONFIG1}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG1
else
  echo $SSH_CONFIG1 already configured
fi
if [[ "$(grep "^${SSH_CONFIG2}" $SSHD_CONFIG | wc -l)" = "0" ]]; then
  echo "${SSH_CONFIG2}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG2
else
  echo $SSH_CONFIG2 already configured
fi
if [[ "$(grep "^${SSH_CONFIG3}" $SSHD_CONFIG | wc -l)" = "0" ]]; then
  echo "${SSH_CONFIG3}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG3
else
  echo $SSH_CONFIG3 already configured
fi
if [[ "$(grep "${SSH_CONFIG4:38}" $SSHD_CONFIG | wc -l)" = "0" ]]; then
  echo "${SSH_CONFIG4}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG4
else
  echo $SSH_CONFIG4 already configured
fi

# Sync console configs
# FZF
if [ ! -d $HOME/.fzf ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  yes | $HOME/.fzf/install
else
  cd ~/.fzf && git pull --ff-only && yes | $HOME/.fzf/install
fi

# SSH
[ ! -d ~/.ssh/ ] && mkdir -p ~/.ssh/ && ssh-keygen
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/authorized_keys ]; then
  ssh-import-id-gh ludorl82
fi

# Install virtualenv
pip3 install --user virtualenvwrapper

# Install node and npm https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-18-04
echo "Checking if Node is installed ..."
if ! command -v node &> /dev/null; then
  curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh
  sudo apt install nodejs
  sudo apt install build-essential
  sudo npm i -g bash-language-server
  sudo npm install -g yarn
  yarn config set "strict-ssl" false -g
  yarn install
else
	echo "Node has already been installed."
fi

# Git
cp $CONFIGS_DIR/.console.gitconfig ~/.gitconfig

# Bash for zsh console
cp $CONFIGS_DIR/.console.bashrc ~/.bashrc
cp $CONFIGS_DIR/.console.inputrc ~/.inputrc
cp $CONFIGS_DIR/.console.fzf.bash $HOME/.fzf.bash
# Copy docker config
[ ! -d $HOME/.docker ] && mkdir $HOME/.docker
#cp $CONFIGS_DIR/.console.docker/config.json $HOME/.docker/

# Copy Xauthority for sudo vim
sudo cp $HOME/.Xauthority /root/.Xauthority

# Set perms for ip
sudo chmod u+s /sbin/ip
