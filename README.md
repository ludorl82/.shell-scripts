# Bootstrapping the Shell

This section bootstraps a Linux system with shell configurations, Docker, and essential packages.

## Compatible Operating Systems
- Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS, and newer)
- Debian (11 Bullseye, 12 Bookworm, and newer)

## Supported Architectures
- amd64 (x86_64)
- arm64 (aarch64) - including Raspberry Pi 4/5

## Run installation
To bootstrap the shell, please run the following command:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ludorl82/.shell-scripts/master/bootstrap-shell/bootstrap_shell.sh)"
```

After installation completes, log out and back in (or reboot) for all changes to take effect.
