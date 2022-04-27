# Bootstrapping the Shell
This section bootstraps an Ubuntu 20.04 VM from the following ISO:
https://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso

## Run installation
To bootstrap the shell, please run the following command:
| Method    | Command                                                                                                                                                              |
| :-------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **curl**  | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/ludorl82/.shell-scripts/master/bootstrap-shell/bootstrap_shell.sh)"` |
| **wget**  | `bash -c "$(wget -O- https://raw.githubusercontent.com/ludorl82/.shell-scripts/master/bootstrap-shell/bootstrap_shell.sh)"`                 |
| **fetch** | `bash -c "$(fetch -o - https://raw.githubusercontent.com/ludorl82/.shell-scripts/master/bootstrap-shell/bootstrap_shell.sh)"`               |
