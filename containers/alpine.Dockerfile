ARG ALPINE_VERSION=3.16
ARG DOCKER_VERSION=20.10.22
ARG ASDF_VERSION=v0.11.0
ARG DOCKER_COMPOSE_VERSION=v2.15.0
ARG KUBECTL_VERSION=1.26.0
ARG HELM_VERSION=3.9.2
ARG KUBECTX_VERSION=0.9.4
ARG MINIKUBE_VERSION=1.28.0
ARG KUSTOMIZE_VERSION=4.5.7
ARG K9S_VERSION=0.26.7
ARG KIND_VERSION=0.17.0
ARG KUBE_CAPACITY_VERSION=v0.7.1
ARG FLUX2_VERSION=0.38.2


FROM docker:${DOCKER_VERSION} AS docker

FROM alpine:${ALPINE_VERSION}
ARG VERSION
ARG COMMIT
ARG BUILD_DATE
ARG ASDF_VERSION
ARG SHELL
ARG DOCKER_COMPOSE_VERSION
ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG KUBECTX_VERSION
ARG MINIKUBE_VERSION
ARG KUSTOMIZE_VERSION
ARG K9S_VERSION
ARG KIND_VERSION
ARG KUBE_CAPACITY_VERSION
ARG FLUX2_VERSION
LABEL \
    org.opencontainers.image.title="DevContainers" \
    org.opencontainers.image.description="Base Alpine image for dev containers" \
    org.opencontainers.image.url="https://github.com/vertisky/devcontainers" \
    org.opencontainers.image.documentation="https://github.com/vertisky/devcontainers" \
    org.opencontainers.image.source="https://github.com/vertisky/devcontainers" \
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
    direnv

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
RUN /root/.asdf/bin/asdf plugin add docker-compose-v1 && /root/.asdf/bin/asdf install docker-compose-v1 ${DOCKER_COMPOSE_VERSION} && /root/.asdf/bin/asdf global docker-compose-v1 ${DOCKER_COMPOSE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubectl && /root/.asdf/bin/asdf install kubectl ${KUBECTL_VERSION} && /root/.asdf/bin/asdf global kubectl ${KUBECTL_VERSION}
RUN /root/.asdf/bin/asdf plugin add helm && /root/.asdf/bin/asdf install helm ${HELM_VERSION} && /root/.asdf/bin/asdf global helm ${HELM_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubectx && /root/.asdf/bin/asdf install kubectx ${KUBECTX_VERSION} && /root/.asdf/bin/asdf global kubectx ${KUBECTX_VERSION}
RUN /root/.asdf/bin/asdf plugin add minikube && /root/.asdf/bin/asdf install minikube ${MINIKUBE_VERSION} && /root/.asdf/bin/asdf global minikube ${MINIKUBE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kustomize && /root/.asdf/bin/asdf install kustomize ${KUSTOMIZE_VERSION} && /root/.asdf/bin/asdf global kustomize ${KUSTOMIZE_VERSION}
RUN /root/.asdf/bin/asdf plugin add k9s && /root/.asdf/bin/asdf install k9s ${K9S_VERSION} && /root/.asdf/bin/asdf global k9s ${K9S_VERSION}
RUN /root/.asdf/bin/asdf plugin add kind && /root/.asdf/bin/asdf install kind ${KIND_VERSION} && /root/.asdf/bin/asdf global kind ${KIND_VERSION}
RUN /root/.asdf/bin/asdf plugin add kube-capacity && /root/.asdf/bin/asdf install kube-capacity ${KUBE_CAPACITY_VERSION} && /root/.asdf/bin/asdf global kube-capacity ${KUBE_CAPACITY_VERSION}
RUN /root/.asdf/bin/asdf plugin add flux2 && /root/.asdf/bin/asdf install flux2 ${FLUX2_VERSION} && /root/.asdf/bin/asdf global flux2 ${FLUX2_VERSION}
