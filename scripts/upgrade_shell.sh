#!/bin/bash

# Script: upgrade_shell.sh
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
# ./upgrade_shell.sh

# Define directories and files
# Directory Variables:
# CONFIGS_DIR: Directory where configuration files are located.
# SCRIPTS_DIR: Directory where scripts are located.
# VIM_PLUGINS_DIR: Directory where Vim plugins are stored.
# ZSH_DIR: Directory where Zsh configuration files are located.
# ZSH_PLUGINS_DIR: Directory where Zsh plugins are stored.
# ZSH_THEMES_DIR: Directory where Zsh themes are stored.
# TMUX_DIR: Directory where Tmux configuration files are located.
# TMUX_PLUGINS_DIR: Directory where Tmux plugins are stored.
# FZF_DIR: Directory where FZF is installed.
# COC_NVIM_DIR: Directory where coc.nvim is installed.
# SSH_DIR: Directory where SSH configuration files are located for the $USER.

CONFIGS_DIR="$HOME/.shell-configs/configs"
SCRIPTS_DIR="$HOME/.shell-scripts/scripts"
VIM_PLUGINS_DIR="$HOME/.config/nvim/pack/bundle/start"
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

ZSH_FILES=("zshrc.zsh" "Linux.zsh" "aliases.zsh" "fzf.zsh" "ludorl82.zsh" "bindings.zsh")
TMUX_FILES=("tmux.conf" "tmux.console.conf" "tmux.keys.conf" "tmux.Linux.conf" "gitmux.conf")
SSH_CONFIGS=(
    "X11Forwarding yes"
    "X11DisplayOffset 10"
    "X11UseLocalhost no"
    "AcceptEnv LANG LC_* ENV CLIENT DISPLAY"
)

# Other Variables:
# DOCKER_GID: Group ID of the Docker group.

DOCKER_GID=999

# Print the start of the script and current environment information
echo -e "\n\n==================== Script Start ====================\n\n"
echo "User: $USER"
echo "Working Directory: $PWD"
echo "Shell: $SHELL"
echo "Terminal: $TERM"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Operating System: $(uname -a)"
echo "Kernel: $(uname -r)"
echo "Distribution: $(lsb_release -a)"

# Print the variables that were previously defined
echo -e "\n\n==================== Printing Directory Variables ====================\n\n"
echo "CONFIGS_DIR: $CONFIGS_DIR"
echo "SCRIPTS_DIR: $SCRIPTS_DIR"
echo "VIM_PLUGINS_DIR: $VIM_PLUGINS_DIR"
echo "ZSH_DIR: $ZSH_DIR"
echo "ZSH_PLUGINS_DIR: $ZSH_PLUGINS_DIR"
echo "ZSH_THEMES_DIR: $ZSH_THEMES_DIR"
echo "TMUX_DIR: $TMUX_DIR"
echo "TMUX_PLUGINS_DIR: $TMUX_PLUGINS_DIR"
echo "FZF_DIR: $FZF_DIR"
echo "COC_NVIM_DIR: $COC_NVIM_DIR"
echo "SSH_DIR: $SSH_DIR"

echo -e "\n\n==================== Printing File Variables ====================\n\n"
echo "AUTHORIZED_KEYS_FILE: $AUTHORIZED_KEYS_FILE"
echo "SSHD_CONFIG: $SSHD_CONFIG"

echo -e "\n\n==================== Printing Array Variables ====================\n\n"
echo "ZSH_FILES: ${ZSH_FILES[@]}"
echo "TMUX_FILES: ${TMUX_FILES[@]}"
echo "SSH_CONFIGS: ${SSH_CONFIGS[@]}"

echo -e "\n\n==================== Printing Other Variables ====================\n\n"
echo "DOCKER_GID: $DOCKER_GID"


# Function to clone or pull git repositories
upgrade_git_repos() {
    local dir=$1
    shift
    echo "Creating directory $dir..."
    mkdir -p $dir
    cd $dir
    for repo in "$@"; do
        local dir_name=$(basename $repo .git)
        if [ ! -d $dir/$dir_name ]; then
            echo "Cloning repository $repo..."
            git clone $repo
        else
            echo "Pulling latest changes from repository $repo..."
            git --git-dir=$dir/$dir_name/.git --work-tree=$dir/$dir_name pull
        fi
    done
}

# Function to copy files and create symbolic links
copy_files_and_create_symlinks() {
    local source_dir=$1
    local target_dir=$2
    local files=("${!3}")
    local symlink_prefix=$4
    for file in "${files[@]}"; do
        cp "${source_dir}/.console.${file}" "${target_dir}/${file}"
        rm -f "${HOME}/${symlink_prefix}${file}" && ln -s -T "${target_dir}/${file}" "${HOME}/${symlink_prefix}${file}"
    done
}

# Function to install and build coc.nvim
install_and_build_coc_nvim() {
    cd $COC_NVIM_DIR
    echo "Installing esbuild..."
    npm i --save esbuild
    echo "Installing dependencies with yarn..."
    yarn install
    echo "Building coc.nvim..."
    yarn build
}

# Function to upgrade CopilotChat
upgrade_copilot_chat() {
    local copilot_chat_dir="$VIM_PLUGINS_DIR/CopilotChat.nvim"
    echo "Upgrading CopilotChat..."
    cd $copilot_chat_dir
    cp -r --backup=nil rplugin ~/.config/nvim/
    echo "Installing requirements..."
    pip install -r requirements.txt
}

# Function to apply SSH config if not already applied
apply_ssh_config() {
    local config=$1
    if [[ "$(grep "^${config}" $SSHD_CONFIG | wc -l)" == "0" ]]; then
        echo "${config}" | sudo tee -a $SSHD_CONFIG
        echo "Just applied ${config}"
    else
        echo "${config} already configured"
    fi
}

# Function to create SSH keys and import authorized key
create_ssh_keys_and_import_authorized_key() {
    if [ ! -d $SSH_DIR ]; then
        echo "Creating SSH directory..."
        mkdir -p $SSH_DIR
        chmod 700 $SSH_DIR
        echo "Generating SSH keys..."
        ssh-keygen
    fi
    if [ ! -f $AUTHORIZED_KEYS_FILE ]; then
        echo "Importing authorized key..."
        ssh-import-id-gh $USER
    fi
    echo "Sending SIGHUP to sshd to refresh keys..."
    sudo kill -1 1
}

# Function to change Docker GID inside container
change_docker_gid() {
    # Get the current GID of the docker group
    current_docker_gid=$(getent group docker | cut -d: -f3)

    # Check if DOCKER_GID is set and not equal to the current GID
    if [ -n "$DOCKER_GID" ] && [ "$DOCKER_GID" != "$current_docker_gid" ]; then
        # Check if docker group exists
        if getent group docker >/dev/null; then
            sudo gpasswd -d $USER docker
            echo "Changing Docker GID to $DOCKER_GID..."
            sudo groupmod -g "$DOCKER_GID" docker
        else
            echo "Creating Docker group with GID $DOCKER_GID..."
            sudo groupadd -g "$DOCKER_GID" docker
        fi
    else
        echo "DOCKER_GID is not set or already matches the current GID. Skipping group modification."
    fi
}

# Upgrade vim plugins
echo -e "\n\n==================== Upgrading vim plugins ====================\n\n"
upgrade_git_repos $VIM_PLUGINS_DIR \
    https://github.com/rafi/awesome-vim-colorschemes.git \
    https://github.com/neoclide/coc.nvim.git \
    https://github.com/github/copilot.vim \
    https://github.com/gptlang/CopilotChat.nvim \
    https://github.com/junegunn/fzf.vim.git \
    https://github.com/vim-airline/vim-airline.git \
    https://github.com/ryanoasis/vim-devicons.git \
    https://github.com/tpope/vim-fugitive.git \
    https://github.com/airblade/vim-gitgutter.git \
    https://github.com/adelarsq/vim-matchit.git \
    https://github.com/hashivim/vim-terraform.git \
    https://github.com/christoomey/vim-tmux-navigator.git

# Upgrade zsh plugins
echo -e "\n\n==================== Upgrading zsh plugins ====================\n\n"
upgrade_git_repos $ZSH_PLUGINS_DIR \
    https://github.com/junegunn/fzf.git \
    https://github.com/jeffreytse/zsh-vi-mode.git \
    https://github.com/superbrothers/zsh-kubectl-prompt.git \
    https://github.com/marlonrichert/zsh-autocomplete.git \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    https://github.com/zsh-users/zsh-autosuggestions.git

# Upgrade zsh themes
echo -e "\n\n==================== Upgrading zsh themes ====================\n\n"
upgrade_git_repos $ZSH_THEMES_DIR \
    https://github.com/agnoster/agnoster-zsh-theme.git

# Upgrade tmux plugins
# NOTE: tmux-themepack is not a plugin, but a collection of themes for tmux
echo -e "\n\n==================== Upgrading tmux plugins ====================\n\n"
upgrade_git_repos $TMUX_PLUGINS_DIR \
    https://github.com/jimeh/tmux-themepack.git \
    https://github.com/tmux-plugins/tmux-yank.git

# Upgrade CopilotChat
echo -e "\n\n==================== Upgrading CopilotChat ====================\n\n"
upgrade_copilot_chat

# Sync nvim configs
echo -e "\n\n==================== Syncing nvim configs ====================\n\n"
rsync -avh "${CONFIGS_DIR}/.console.config/nvim/" $HOME/.config/nvim

# Install and build coc.nvim
echo -e "\n\n==================== Installing and building coc.nvim ====================\n\n"
install_and_build_coc_nvim

# Copy ZSH configs and create symbolic links
echo -e "\n\n==================== Copying ZSH configs and creating symbolic links ====================\n\n"
copy_files_and_create_symlinks $CONFIGS_DIR $ZSH_DIR ZSH_FILES[@] "."
# Copy Tmux configs and create symbolic links
copy_files_and_create_symlinks $CONFIGS_DIR $TMUX_DIR TMUX_FILES[@] "."

# Bash for zsh console
echo -e "\n\n==================== Bash for zsh console ====================\n\n"
cp $CONFIGS_DIR/.console.bashrc ~/.bashrc
cp $CONFIGS_DIR/.console.inputrc ~/.inputrc
cp $CONFIGS_DIR/.console.fzf.bash $HOME/.fzf.bash

echo -e "\n\n==================== Applying various configs ====================\n\n"
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
echo -e "\n\n==================== Applying each SSH config ====================\n\n"
for config in "${SSH_CONFIGS[@]}"; do
    apply_ssh_config "${config}"
done

# Create SSH keys and import authorized key
echo -e "\n\n==================== Creating SSH keys and importing authorized key ====================\n\n"
create_ssh_keys_and_import_authorized_key

# Upgrade FZF
echo -e "\n\n==================== Upgrading FZF ====================\n\n"
upgrade_git_repos $FZF_DIR https://github.com/junegunn/fzf.git
echo "Installing FZF..."
yes | $FZF_DIR/install

# Change Docker GID inside container and add user to docker group
echo -e "\n\n==================== Changing Docker GID inside container and adding user to docker group ====================\n\n"
change_docker_gid
sudo usermod -aG docker $USER

echo "Script completed."
