ARG UBUNTU_VERSION=24.04
ARG DOCKER_VERSION=28.0.0
ARG ASDF_VERSION=v0.16.0
ARG DIRENV_VERSION=2.35.0

FROM docker:${DOCKER_VERSION} AS docker

FROM golang:latest AS asdf
ARG ASDF_VERSION

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl unzip build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install ASDF
RUN git clone https://github.com/asdf-vm/asdf.git /workspace/.asdf --branch ${ASDF_VERSION}

# Build ASDF
WORKDIR /workspace/.asdf
RUN make

FROM ubuntu:${UBUNTU_VERSION}
ARG VERSION
ARG COMMIT
ARG BUILD_DATE
ARG ASDF_VERSION
ARG SHELL
ARG DIRENV_VERSION

LABEL \
    org.opencontainers.image.title="Base DevContainer" \
    org.opencontainers.image.description="Base Ubuntu image for dev containers" \
    org.opencontainers.image.url="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.documentation="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.source="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.vendor="vertisky" \
    org.opencontainers.image.authors="etma@vertisky.com" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.created=$BUILD_DATE

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git git-doc \
    bash \
    tzdata \
    openssh-client \
    mandoc \
    locales \
    make \
    less \
    direnv \
    unzip \
    jq \
    wget

# install yq
RUN if [ -z "$PLATFORM" ]; then PLATFORM=$(uname -m); fi && \
    if [ "$PLATFORM" = "x86_64" ]; then PLATFORM="amd64"; fi && \
    if [ "$PLATFORM" = "aarch64" ]; then PLATFORM="arm64"; fi && \
    if [ "$PLATFORM" = "armv7l" ]; then PLATFORM="arm"; fi && \
    if [ "$PLATFORM" = "armv6l" ]; then PLATFORM="arm"; fi && \
    curl -sL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${PLATFORM} && \
    chmod +x /usr/local/bin/yq

# Install zsh and setup powerlevel10k theme
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y zsh
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN usermod -s /bin/zsh root

ENTRYPOINT [ "/bin/zsh" ]

COPY ./containers/shell/* /root/
RUN chmod +x /root/*.sh

# Install vim
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y vim

# Set vim as default editor
ENV EDITOR=vim \
    LANG=en_US.UTF-8 \
    TERM=xterm

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

# Setup git
RUN git config --global advice.detachedHead false

# Install docker
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker

# Install docker buildx
# COPY --from=docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Install asdf
COPY --from=asdf /workspace/.asdf/asdf /usr/bin/asdf

# auto whitelist /workspace in direnv config
RUN mkdir -p /root/.config/direnv && echo "[whitelist]" >> /root/.config/direnv/direnv.toml \
    && echo "prefix = [ \"/workspace\" ]" >> /root/.config/direnv/direnv.toml

# Install asdf base plugins
RUN asdf plugin add direnv && asdf install direnv ${DIRENV_VERSION} && asdf global direnv ${DIRENV_VERSION}

# cleanup
RUN apt-get clean && rm -r /var/lib/apt/lists/* && rm -r /var/cache/*
