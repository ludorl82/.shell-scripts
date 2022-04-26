#!/bin/bash

# Script: upgrade_console.sh
# Purpose: This script automates the setup of a development environment with various tools and configurations.

# The script performs the following operations:
# 1. Clones or pulls the latest versions of various git repositories.
# 2. Copies configuration files.
# 3. Creates symbolic links.
# 4. Installs and builds coc.nvim.
# 5. Sets up gitconfig.
# 6. Copies Xauthority for sudo vim.
# 7. Sets permissions for special tools.
# 8. Syncs Tmuxinator configs.
# 9. Applies SSH configurations.
# 10. Creates SSH keys and imports an authorized key.
# 11. Installs FZF.

# Usage Instructions:
# Execute this script from the command line using the following command:
# ./upgrade_console.sh

# Define directories and files
# Directory Variables:
# CONFIGS_DIR: Directory where configuration files are located.
# SCRIPTS_DIR: Directory where scripts are located.
# ZSH_DIR: Directory where Zsh configuration files are located.
# ZSH_PLUGINS_DIR: Directory where Zsh plugins are stored.
# ZSH_THEMES_DIR: Directory where Zsh themes are stored.
# TMUX_DIR: Directory where Tmux configuration files are located.
# TMUX_PLUGINS_DIR: Directory where Tmux plugins are stored.
# FZF_DIR: Directory where FZF is installed.
# COC_NVIM_DIR: Directory where coc.nvim is installed.
# SSH_DIR: Directory where SSH configuration files are located for the $USER.

CONFIGS_DIR="$HOME/.shell-configs"
SCRIPTS_DIR="$HOME/.shell-scripts/scripts"
VIM_CONFIG_DIR="$HOME/.config/nvim"
ZSH_DIR="$HOME/.zsh"
ZSH_PLUGINS_DIR="$ZSH_DIR/plugins"
ZSH_THEMES_DIR="$ZSH_DIR/themes"
TMUX_DIR=$HOME/.tmux
TMUX_PLUGINS_DIR=$TMUX_DIR/plugins
FZF_DIR="$HOME/.fzf"
COC_NVIM_DIR="$HOME/.config/nvim/pack/bundle/start/coc.nvim"
SSH_DIR="$HOME/.ssh"

# File Variables:
# AUTHORIZED_KEYS_FILE: File where authorized SSH keys are stored.
# SSHD_CONFIG: SSH daemon configuration file location.

AUTHORIZED_KEYS_FILE="$SSH_DIR/authorized_keys"
SSHD_CONFIG="/etc/ssh/sshd_config"

# Array Variables:
# ZSH_FILES: Array of Zsh configuration files to be copied and linked.
# TMUX_FILES: Array of Tmux configuration files to be copied and linked.
# SSH_CONFIGS: Array of SSH configurations to be applied.

ZSH_FILES=("zshrc.zsh" "bindings.zsh" "zshenv")
TMUX_FILES=("tmux.conf" "tmux.keys.conf")
SSH_CONFIGS=(
    "X11Forwarding yes"
    "X11DisplayOffset 10"
    "X11UseLocalhost no"
    "AcceptEnv LANG LC_* ENV CLIENT DISPLAY"
)

# Other Variables:
# DOCKER_GID: Group ID of the Docker group.

DOCKER_GID=124

source $SCRIPTS_DIR/upgrade_shell_functions.sh

# Upgrade zsh plugins
echo -e "

==================== Upgrading zsh plugins ====================

"
upgrade_git_repos $ZSH_PLUGINS_DIR \
    https://github.com/junegunn/fzf.git \
    https://github.com/jeffreytse/zsh-vi-mode.git \
    https://github.com/superbrothers/zsh-kubectl-prompt.git \
    https://github.com/marlonrichert/zsh-autocomplete.git \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    https://github.com/zsh-users/zsh-autosuggestions.git

# Upgrade zsh themes
echo -e "

==================== Upgrading zsh themes ====================

"
upgrade_git_repos $ZSH_THEMES_DIR \
    https://github.com/agnoster/agnoster-zsh-theme.git

# Upgrade tmux plugins
# NOTE: tmux-themepack is not a plugin, but a collection of themes for tmux
echo -e "

==================== Upgrading tmux plugins ====================

"
upgrade_git_repos $TMUX_PLUGINS_DIR \
    https://github.com/jimeh/tmux-themepack.git \
    https://github.com/tmux-plugins/tmux-yank.git

# Sync nvim configs
echo -e "

==================== Syncing nvim configs ====================

"
rsync -avh "${CONFIGS_DIR}/.console.config/nvim/" $HOME/.config/nvim

# Copy ZSH configs and create symbolic links
echo -e "

==================== Copying ZSH configs and creating symbolic links ====================

"
copy_files_and_create_symlinks $CONFIGS_DIR $ZSH_DIR ZSH_FILES[@] "."
# Copy Tmux configs and create symbolic links
copy_files_and_create_symlinks $CONFIGS_DIR $TMUX_DIR TMUX_FILES[@] "."

# Bash for zsh console
echo -e "

==================== Bash for zsh console ====================

"
cp $CONFIGS_DIR/.console.bashrc ~/.bashrc
cp $CONFIGS_DIR/.console.bash_profile ~/.bash_profile
cp $CONFIGS_DIR/.console.aliases.sh ~/.aliases.sh
cp $CONFIGS_DIR/.console.inputrc ~/.inputrc

echo -e "

==================== Applying various configs ====================

"
echo "Setting up gitconfig"
cp $CONFIGS_DIR/.console.gitconfig ~/.gitconfig

echo "Copying Xauthority for sudo vim"
sudo cp $HOME/.Xauthority /root/.Xauthority

echo "Setting permissions for ip manipulation"
sudo chmod u+s /sbin/ip

echo "Syncing Tmuxinator configs"
rsync -avh "$CONFIGS_DIR/.console.config/tmuxinator/" $HOME/.config/tmuxinator --delete

echo "Creating tmp directory if not exists"
mkdir -p $HOME/tmp

# Apply each SSH config
echo -e "

==================== Applying each SSH config ====================

"
for config in "${SSH_CONFIGS[@]}"; do
    apply_ssh_config "${config}"
done

# Create SSH keys and import authorized key
echo -e "

==================== Creating SSH keys and importing authorized key ====================

"
create_ssh_keys_and_import_authorized_key

# Upgrade FZF
echo -e "

==================== Upgrading FZF ====================

"
upgrade_git_repos $FZF_DIR https://github.com/junegunn/fzf.git
echo "Installing FZF..."
yes | $FZF_DIR/fzf/install

# Change Docker GID inside container and add user to docker group
echo -e "

==================== Changing Docker GID inside container and adding user to docker group ====================

"
change_docker_gid
sudo usermod -aG docker $USER

echo "Script completed."
