ARG ALPINE_VERSION=3.21
ARG DOCKER_VERSION=28.0.0
ARG ASDF_VERSION=v0.16.4
ARG DIRENV_VERSION=2.35.0


FROM docker:${DOCKER_VERSION} AS docker

FROM golang:1.24.0-alpine AS asdf
ARG ASDF_VERSION

RUN go install github.com/asdf-vm/asdf/cmd/asdf@${ASDF_VERSION} 

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
    jq \
    yq \
    vim 

# Install zsh and setup powerlevel10k theme
# RUN apk add -q --update --progress --no-cache zsh zsh-vcs
# RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
# RUN apk add -q --update --progress --no-cache zsh-theme-powerlevel10k gitstatus && \
#     ln -s /usr/share/zsh/plugins/powerlevel10k ~/.oh-my-zsh/custom/themes/powerlevel10k
# RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# RUN apk add -q --update --progress --no-cache shadow && \
#     usermod -s /bin/zsh root && \
#     apk del shadow

ENTRYPOINT [ "/bin/bash" ]

COPY ./containers/shell/* /root/

RUN chmod +x /root/*.sh

# Install vim
# RUN apk add -q --update --progress --no-cache vim

# Set vim as default editor
ENV EDITOR=vim \
    LANG=en_US.UTF-8 \
    TERM=xterm

# Setup git
RUN git config --global advice.detachedHead false

# Install docker
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker

# Install docker buildx
# COPY --from=docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx


# Install asdf
COPY --from=asdf /go/bin/asdf /usr/bin/asdf
# add export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH" to .bash_profile
RUN echo "export PATH=\"\${ASDF_DATA_DIR:-\$HOME/.asdf}/shims:\$PATH\"" >> /root/.bashrc
# add bash completions . <(asdf completion bash)
RUN echo ". <(asdf completion bash)" >> /root/.bashrc

# VSCode specific (speed up setup)
RUN apk add -q --update --progress --no-cache libstdc++

# auto whitelist /workspace in direnv config
RUN mkdir -p /root/.config/direnv && echo "[whitelist]" >> /root/.config/direnv/direnv.toml \
    && echo "prefix = [ \"/workspace\" ]" >> /root/.config/direnv/direnv.toml


# Install asdf base plugins
# RUN touch /root/.tool-versions
RUN asdf plugin add direnv && asdf install direnv ${DIRENV_VERSION} && asdf set -u direnv ${DIRENV_VERSION} && asdf direnv setup --shell bash --version ${DIRENV_VERSION} && asdf reshim direnv
#install direnv ${DIRENV_VERSION} && asdf global direnv ${DIRENV_VERSION} && asdf reshim 