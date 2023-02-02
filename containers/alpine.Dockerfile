ARG ALPINE_VERSION=3.16
ARG DOCKER_VERSION=20.10.23
ARG ASDF_VERSION=v0.11.1
ARG DIRENV_VERSION=2.32.2


FROM docker:${DOCKER_VERSION} AS docker

FROM alpine:${ALPINE_VERSION}
ARG VERSION
ARG COMMIT
ARG BUILD_DATE
ARG ASDF_VERSION
ARG SHELL
ARG DIRENV_VERSION

LABEL \
    org.opencontainers.image.title="Base DevContainer" \
    org.opencontainers.image.description="Base Alpine image for dev containers" \
    org.opencontainers.image.url="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.documentation="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.source="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.vendor="vertisky" \
    org.opencontainers.image.authors="etma@vertisky.com" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.created=$BUILD_DATE

RUN apk add -q --update --progress --no-cache \
    ca-certificates \
    curl \
    git git-doc \
    bash \
    tzdata \
    openssh-client \
    mandoc \
    make \
    less \
    direnv \
    jq \
    yq 

# Install zsh and setup powerlevel10k theme
RUN apk add -q --update --progress --no-cache zsh zsh-vcs
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
RUN apk add -q --update --progress --no-cache zsh-theme-powerlevel10k gitstatus && \
    ln -s /usr/share/zsh/plugins/powerlevel10k ~/.oh-my-zsh/custom/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN apk add -q --update --progress --no-cache shadow && \
    usermod -s /bin/zsh root && \
    apk del shadow

ENTRYPOINT [ "/bin/zsh" ]

COPY ./containers/shell/* /root/

RUN chmod +x /root/*.sh

# Install vim
RUN apk add -q --update --progress --no-cache vim

# Set vim as default editor
ENV EDITOR=vim \
    LANG=en_US.UTF-8 \
    TERM=xterm

# Setup git
RUN git config --global advice.detachedHead false

# Install docker
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker

# Install docker buildx
COPY --from=docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Install asdf
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $ASDF_VERSION

# VSCode specific (speed up setup)
RUN apk add -q --update --progress --no-cache libstdc++

# auto whitelist /workspace in direnv config
RUN mkdir -p /root/.config/direnv && echo "[whitelist]" >> /root/.config/direnv/direnv.toml \
    && echo "prefix = [ \"/workspace\" ]" >> /root/.config/direnv/direnv.toml


# Install asdf base plugins
RUN touch /root/.tool-versions
RUN /root/.asdf/bin/asdf plugin add direnv && /root/.asdf/bin/asdf install direnv ${DIRENV_VERSION} && /root/.asdf/bin/asdf global direnv ${DIRENV_VERSION}
