FROM ludorl82/console:v1.1.0

ARG USER
ARG UID=1000
ARG GID=1000

# Create or modify user and group
# - Create group with GID if missing
# - Create user if missing; otherwise modify existing
# - Set shell, home, UID/GID, add to docker & sudo, set password
RUN set -eux; \
    if ! getent group "$USER" >/dev/null; then groupadd -g "$GID" "$USER"; fi; \
    if getent passwd "$USER" >/dev/null; then \
      usermod -d /home/"$USER" -s /usr/bin/zsh -u "$UID" -g "$GID" -a -G docker,sudo "$USER"; \
    else \
      useradd -m -d /home/"$USER" -s /usr/bin/zsh -u "$UID" -g "$GID" -G docker,sudo "$USER"; \
    fi; \
    mkdir -p /home/"$USER"; \
    chown -R "$USER":"$USER" /home/"$USER"; \
    echo "$USER:$(cat ~/.ludorl82)" | chpasswd
