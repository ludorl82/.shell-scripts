#!/bin/bash

# Print the start of the script and current environment information
echo -e "

==================== Script Start ====================

"

# Prompt for sudo to avoid prompt later
sudo echo "Sudo acquired."

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
echo -e "

==================== Printing Directory Variables ====================

"
echo "CONFIGS_DIR: $CONFIGS_DIR"
echo "SCRIPTS_DIR: $SCRIPTS_DIR"
echo "ZSH_DIR: $ZSH_DIR"
echo "ZSH_PLUGINS_DIR: $ZSH_PLUGINS_DIR"
echo "ZSH_THEMES_DIR: $ZSH_THEMES_DIR"
echo "TMUX_DIR: $TMUX_DIR"
echo "TMUX_PLUGINS_DIR: $TMUX_PLUGINS_DIR"
echo "FZF_DIR: $FZF_DIR"
echo "COC_NVIM_DIR: $COC_NVIM_DIR"
echo "SSH_DIR: $SSH_DIR"

echo -e "

==================== Printing File Variables ====================

"
echo "AUTHORIZED_KEYS_FILE: $AUTHORIZED_KEYS_FILE"
echo "SSHD_CONFIG: $SSHD_CONFIG"

echo -e "

==================== Printing Array Variables ====================

"
echo "ZSH_FILES: ${ZSH_FILES[@]}"
echo "TMUX_FILES: ${TMUX_FILES[@]}"
echo "SSH_CONFIGS: ${SSH_CONFIGS[@]}"

echo -e "

==================== Printing Other Variables ====================

"
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

# Function to download a single git archive from Nexus
download_git_archive() {
    local target_dir=$1
    local tar_url=$2

    echo "Downloading git archive from $tar_url..."
    mkdir -p $target_dir
    cd $target_dir
    curl -L -o temp.tar.gz $tar_url
    tar -xzf temp.tar.gz --strip-components=1
    rm temp.tar.gz
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
