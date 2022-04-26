# Bootstrapping the Shell
This section bootstraps an Ubuntu 20.04 VM from the following ISO:
https://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso

## Run installation
To bootstrap the shell, please run the following command:
| Method    | Command                                                                                                                                                              |
| :-------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **curl**  | `sh -c "$(read -p 'Github Username:' user && curl -kfsSL --user $user https://raw.github.com/ludorl82/.shell-scripts/master/scripts/bootstrap_shell.sh)"` |
| **wget**  | `sh -c "$(read -p 'Github Username:' user && wget -O- https://raw.github.com/ludorl82/.shell-scripts/master/scripts/bootstrap_shell.sh)"`                 |
| **fetch** | `sh -c "$(read -p 'Github Username:' user && fetch -o - https://raw.github.com/ludorl82/.shell-scripts/master/scripts/bootstrap_shell.sh)"`               |
