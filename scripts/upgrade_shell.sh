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
[ ! -d $VIM_PLUGINS_DIR/fzf ] && git clone https://github.com/junegunn/fzf.git
[ ! -d $VIM_PLUGINS_DIR/fzf.vim ] && git clone https://github.com/junegunn/fzf.vim.git
[ ! -d $VIM_PLUGINS_DIR/nerdtree ] && git clone https://github.com/preservim/nerdtree.git
[ ! -d $VIM_PLUGINS_DIR/vim-airline ] && git clone https://github.com/vim-airline/vim-airline.git
[ ! -d $VIM_PLUGINS_DIR/vim-devicons ] && git clone https://github.com/ryanoasis/vim-devicons.git
[ ! -d $VIM_PLUGINS_DIR/vim-fugitive ] && git clone https://github.com/tpope/vim-fugitive.git
[ ! -d $VIM_PLUGINS_DIR/vim-gitgutter ] && git clone https://github.com/airblade/vim-gitgutter.git
[ ! -d $VIM_PLUGINS_DIR/vim-matchit ] && git clone https://github.com/adelarsq/vim-matchit.git
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
[ ! -d $ZSH_PLUGINS_DIR/zsh-vi-mode ] && git clone https://github.com/jeffreytse/zsh-vi-mode.git
[ ! -d $ZSH_PLUGINS_DIR/zsh-kubectl-prompt ] && git clone https://github.com/superbrothers/zsh-kubectl-prompt
find $ZSH_PLUGINS_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull \;

# Upgrade zsh themes
mkdir -p $ZSH_THEMES_DIR
cd $ZSH_THEMES_DIR
[ ! -d $ZSH_THEMES_DIR/agnoster-zsh-theme ] && git clone https://github.com/agnoster/agnoster-zsh-theme.git
find $ZSH_THEMES_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull \;

# ZSH
cp $CONFIGS_DIR/.console.zshrc $ZSH_DIR/.zshrc
cp $CONFIGS_DIR/.console.zshrc-Darwin $ZSH_DIR/.zshrc-Darwin
cp $CONFIGS_DIR/.console.zshrc-Linux $ZSH_DIR/.zshrc-Linux
cp $CONFIGS_DIR/.console.zshrc-aliases $ZSH_DIR/.zshrc-aliases
cp $CONFIGS_DIR/.console.zshrc-fzf $ZSH_DIR/.zshrc-fzf
cp $CONFIGS_DIR/.console.zshrc-ludorl82 $ZSH_DIR/.zshrc-ludorl82
[ ! -e $HOME/.zshrc ] && ln -s -T $ZSH_DIR/.zshrc $HOME/.zshrc

# Upgrade tmux plugins
mkdir -p $TMUX_PLUGINS_DIR
cd $TMUX_PLUGINS_DIR
[ ! -d $TMUX_PLUGINS_DIR/tmux-themepack ] && git clone https://github.com/jimeh/tmux-themepack.git
[ ! -d $TMUX_PLUGINS_DIR/tmux-yank ] && git clone https://github.com/tmux-plugins/tmux-yank.git
find $TMUX_PLUGINS_DIR -mindepth 1 -maxdepth 1 -type d -exec git --git-dir={}/.git --work-tree={} pull \;

# Tmux configs import
cp $CONFIGS_DIR/.console.tmux.conf $TMUX_DIR/.tmux.conf
cp $CONFIGS_DIR/.console.tmux.console.conf $TMUX_DIR/.tmux.console.conf
cp $CONFIGS_DIR/.console.tmux.keys.conf $TMUX_DIR/.tmux.keys.conf
cp $CONFIGS_DIR/.console.tmux.Linux.conf $TMUX_DIR/.tmux.Linux.conf
cp $CONFIGS_DIR/.console.gitmux.conf $TMUX_DIR/.gitmux.conf
rsync -avh "$CONFIGS_DIR/.console.config/tmuxinator/" $HOME/.config/tmuxinator --delete
[ ! -e $HOME/.tmux.conf ] && ln -s -T $TMUX_DIR/.tmux.conf $HOME/.tmux.conf

# Ensure SSH configs are done
SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG1="X11Forwarding yes"
SSH_CONFIG2="AcceptEnv LANG LC_* ENV CLIENT"
if [[ "$(grep "^$SSH_CONFIG1" $SSHD_CONFIG | wc -l)" == "0" ]]; then
  echo "${SSH_CONFIG1}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG1
else
  echo $SSH_CONFIG1 already configured
fi
if [[ "$(grep "${SSH_CONFIG2:20}" $SSHD_CONFIG | wc -l)" = "0" ]]; then
  echo "${SSH_CONFIG2}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG2
else
  echo $SSH_CONFIG2 already configured
fi

# Sync console configs
# FZF
if [ ! -d $HOME/.fzf ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  yes | $HOME/.fzf/install
else
  cd ~/.fzf && git pull && yes | $HOME/.fzf/install
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
cd
if [ ! -f nodesource_setup.sh ]; then
  curl -sL https://deb.nodesource.com/setup_17.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh
  sudo apt install nodejs
  sudo apt install build-essential
  sudo npm i -g bash-language-server
  sudo npm install -g yarn
  yarn config set "strict-ssl" false -g
  yarn install
fi

# Git
cp $CONFIGS_DIR/.console.gitconfig $HOME/.gitconfig

# Bash for zsh console
cp $CONFIGS_DIR/.console.bashrc $HOME/.bashrc
cp $CONFIGS_DIR/.console.inputrc $HOME/.inputrc
