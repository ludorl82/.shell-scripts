#!/bin/bash

# Canonical list of sshd_config lines needed across all scripts.
# Single source of truth -- do not duplicate this list elsewhere.
SSH_CONFIGS=(
    "X11Forwarding yes"
    "X11DisplayOffset 10"
    "X11UseLocalhost no"
    "AcceptEnv LANG LC_* ENV CLIENT DISPLAY"
)

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

# Apply every entry in SSH_CONFIGS, skipping any already present
apply_all_ssh_configs() {
    for config in "${SSH_CONFIGS[@]}"; do
        apply_ssh_config "${config}"
    done
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
    # Get the current GID of the docker group (empty if the group doesn't exist yet)
    current_docker_gid=$(getent group docker | cut -d: -f3) || true

    # Check if DOCKER_GID is set and not equal to the current GID
    if [ -n "$DOCKER_GID" ] && [ "$DOCKER_GID" != "$current_docker_gid" ]; then
        # Check if docker group exists
        if getent group docker >/dev/null; then
            # Fails harmlessly if the user isn't currently a member
            sudo gpasswd -d $USER docker || true
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
