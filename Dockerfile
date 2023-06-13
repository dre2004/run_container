FROM ubuntu:22.04
ARG APP_ENV

ENV APP_ENV=${APP_ENV} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.4.1 \
    DEBIAN_FRONTEND=noninteractive \
    AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    GIT_LFS_VERSION="3.2.0" \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PYENV_ROOT=/github/home/.pyenv


RUN mkdir -p $AGENT_TOOLSDIRECTORY
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Locale stuff
RUN set -xe \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install locales apt-utils -y \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales

# Install base dependencies
RUN set -xe \
    && apt-get install git unzip lsb-release wget curl jq build-essential ca-certificates dumb-init \
    libssl-dev libffi-dev openssh-client tar apt-transport-https sudo gpg-agent software-properties-common zstd gettext libcurl4-openssl-dev jq \
    gnupg zip locales zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev --no-install-recommends -y \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
    && sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu jammy stable" \
    && apt-cache policy docker-ce \
    && apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin containerd.io docker-compose-plugin --no-install-recommends --allow-unauthenticated \
    && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && mkdir -p /github/home \
    && export PYENV_ROOT=$PYENV_ROOT \
    && curl https://pyenv.run | bash \
    && echo 'export PATH="/github/home/.pyenv/bin:$PATH"' >> /github/home/.bash_profile \
    && echo 'eval "$(pyenv init -)"' >> /github/home/.bash_profile \
    && echo 'eval "$(pyenv virtualenv-init -)"' >> /github/home/.bash_profile \
    && echo 'export PATH="/github/home/.pyenv/bin:$PATH"' >> /github/home/.bashrc \
    && echo 'eval "$(pyenv init -)"' >> /github/home/.bashrc \
    && echo 'eval "$(pyenv virtualenv-init -)"' >> /github/home/.bashrc

# Install python versions
RUN set -xe \
    && source /github/home/.bash_profile && pyenv install 3.8.17 \
    && pyenv install 3.9.17 \
    && pyenv install 3.10.12 

WORKDIR /build

# Install NodeJS
RUN set -xe \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

# Install Terraform 
RUN set -xe \
    && wget https://releases.hashicorp.com/terraform/1.3.2/terraform_1.3.2_linux_arm.zip \
    && unzip terraform_1.3.2_linux_arm.zip \
    && chmod +x terraform \
    && mv terraform /usr/bin/ \
    && npm i -g cdktf-cli@0.15.2

# Install AWS CLI
RUN set -xe \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && chmod +x ./aws/install \
    && ./aws/install 

# Environment
RUN set -xe \
    && echo 'export PATH="/github/home/.pyenv/bin:$PATH"' >> /etc/profile \
    && echo 'eval "$(pyenv init -)"' >> /etc/profile  \
    && echo 'eval "$(pyenv virtualenv-init -)"' >> /etc/profile


# Clean up
RUN set -xe \ 
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /build 

WORKDIR /github/home

COPY start.sh /start.sh
RUN chmod +x /start.sh
