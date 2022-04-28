FROM ubuntu:20.04

ARG USER

# Install packages
RUN apt update && export DEBIAN_FRONTEND=noninteractive && export TZ=America/Montreal && \
  apt install -y software-properties-common zsh ruby-full python3-pip rsync bind9-dnsutils \
                 open-vm-tools libnss-ldap libpam-ldap ldap-utils jq exuberant-ctags \
                 curl golang git && \
  add-apt-repository ppa:neovim-ppa/stable && \
  apt upgrade -y && apt install -y neovim

# Install docker
RUN apt -y install curl
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update
RUN apt -y install docker-ce-cli

RUN useradd -ms /usr/bin/zsh $USER

USER $USER
WORKDIR /home/$USER

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
  rm -f install.sh

# Install virtualenv
RUN pip3 install --user virtualenvwrapper

# Installing fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
  ~/.fzf/install

# Cloning configs and scripts
RUN git clone https://github.com/ludorl82/.shell-configs && \
    git clone https://github.com/ludorl82/.shell-scripts

ENTRYPOINT ["tail", "-f", "/dev/null"]
