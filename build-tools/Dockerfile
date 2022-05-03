FROM ubuntu:20.04

ARG USER

RUN echo User is: $USER

# Install packages
RUN apt update && export DEBIAN_FRONTEND=noninteractive && export TZ=America/Montreal && \
  apt install -y software-properties-common zsh python3-pip rsync bind9-dnsutils ruby-full \
                 open-vm-tools libnss-ldap libpam-ldap ldap-utils jq exuberant-ctags sudo \
                 curl golang git iftop mtr telnet wget && \
  add-apt-repository ppa:neovim-ppa/stable && \
  apt upgrade -y && apt install -y neovim

# Install docker
RUN apt -y install curl
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update
RUN apt -y install docker-ce-cli
RUN groupadd -g 998 docker

# Set timezone
RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Montreal /etc/localtime

# Create user
RUN useradd -rm -d /home/$USER -s /usr/bin/zsh -G sudo -G docker -u 1000 -p "$(openssl passwd -1 ubuntu)" $USER

# Install node and npm
RUN curl -sL https://deb.nodesource.com/setup_17.x -o nodesource_setup.sh && \
  bash nodesource_setup.sh && \
  apt install nodejs && \
  apt install build-essential && \
  npm i -g bash-language-server && \
  npm install -g yarn

# Install tmux
RUN apt update && apt install -y git automake build-essential pkg-config \
                                      libevent-dev libncurses5-dev byacc bison zsh
RUN rm -fr /tmp/tmux && \
  git clone https://github.com/tmux/tmux.git /tmp/tmux
WORKDIR /tmp/tmux
RUN git checkout 3.0
RUN sh autogen.sh
RUN ./configure && make
RUN make install
WORKDIR /home/$USER
RUN rm -fr /tmp/tmux

# Install tmuxinator
RUN gem install tmuxinator

USER $USER
WORKDIR /home/$USER
