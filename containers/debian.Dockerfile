ARG DEBIAN_VERSION=bullseye-slim
ARG DOCKER_VERSION=20.10.23
ARG ASDF_VERSION=v0.11.1
ARG DOCKER_COMPOSE_VERSION=v2.15.0
ARG KUBECTL_VERSION=1.26.0
ARG HELM_VERSION=3.11.0
ARG KUBECTX_VERSION=0.9.4
ARG MINIKUBE_VERSION=1.29.0
ARG KUSTOMIZE_VERSION=4.5.7
ARG K9S_VERSION=0.27.2
ARG KIND_VERSION=0.17.0
ARG KUBE_CAPACITY_VERSION=v0.7.3
ARG FLUX2_VERSION=0.38.3
ARG OIDC_LOGIN_VERSION=v1.26.0
ARG DIRENV_VERSION=2.32.2
ARG KUBESPY_VERSION=0.6.1
ARG KUBECONFORM_VERSION=0.5.0
ARG POPEYE_VERSION=v0.10.1
ARG KUBE_SCORE_VERSION=1.16.1
ARG KUBE_LINTER_VERSION=0.6.0

FROM docker:${DOCKER_VERSION} AS docker

FROM debian:${DEBIAN_VERSION}
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
ARG OIDC_LOGIN_VERSION
ARG DIRENV_VERSION
ARG KUBESPY_VERSION
ARG KUBECONFORM_VERSION
ARG POPEYE_VERSION
ARG KUBE_SCORE_VERSION
ARG KUBE_LINTER_VERSION
LABEL \
    org.opencontainers.image.title="Base DevContainer" \
    org.opencontainers.image.description="Base Debian image for dev containers" \
    org.opencontainers.image.url="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.documentation="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.source="https://github.com/vertisky/devcontainers-base" \
    org.opencontainers.image.vendor="vertisky" \
    org.opencontainers.image.authors="etma@vertisky.com" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.created=$BUILD_DATE

RUN apt-get update && apt-get install --no-install-recommends -y \
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
RUN apt-get install --no-install-recommends -y zsh
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN usermod -s /bin/zsh root

ENTRYPOINT [ "/bin/zsh" ]

COPY ./containers/shell/* /root/
RUN chmod +x /root/*.sh

# Install vim
RUN apt-get install --no-install-recommends -y vim

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
COPY --from=docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Install asdf
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $ASDF_VERSION

# auto whitelist /workspace in direnv config
RUN mkdir -p /root/.config/direnv && echo "[whitelist]" >> /root/.config/direnv/direnv.toml \
    && echo "prefix = [ \"/workspace\" ]" >> /root/.config/direnv/direnv.toml

# Install asdf base plugins
RUN touch /root/.tool-versions
# RUN /root/.asdf/bin/asdf plugin add docker-compose-v1 && /root/.asdf/bin/asdf install docker-compose-v1 ${DOCKER_COMPOSE_VERSION} && /root/.asdf/bin/asdf global docker-compose-v1 ${DOCKER_COMPOSE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubectl && /root/.asdf/bin/asdf install kubectl ${KUBECTL_VERSION} && /root/.asdf/bin/asdf global kubectl ${KUBECTL_VERSION}
RUN /root/.asdf/bin/asdf plugin add helm && /root/.asdf/bin/asdf install helm ${HELM_VERSION} && /root/.asdf/bin/asdf global helm ${HELM_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubectx && /root/.asdf/bin/asdf install kubectx ${KUBECTX_VERSION} && /root/.asdf/bin/asdf global kubectx ${KUBECTX_VERSION}
RUN /root/.asdf/bin/asdf plugin add minikube && /root/.asdf/bin/asdf install minikube ${MINIKUBE_VERSION} && /root/.asdf/bin/asdf global minikube ${MINIKUBE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kustomize && /root/.asdf/bin/asdf install kustomize ${KUSTOMIZE_VERSION} && /root/.asdf/bin/asdf global kustomize ${KUSTOMIZE_VERSION}
RUN /root/.asdf/bin/asdf plugin add k9s && /root/.asdf/bin/asdf install k9s ${K9S_VERSION} && /root/.asdf/bin/asdf global k9s ${K9S_VERSION}
RUN /root/.asdf/bin/asdf plugin add kind && /root/.asdf/bin/asdf install kind ${KIND_VERSION} && /root/.asdf/bin/asdf global kind ${KIND_VERSION}
RUN /root/.asdf/bin/asdf plugin add kube-capacity && /root/.asdf/bin/asdf install kube-capacity ${KUBE_CAPACITY_VERSION} && /root/.asdf/bin/asdf global kube-capacity ${KUBE_CAPACITY_VERSION}
RUN /root/.asdf/bin/asdf plugin add flux2 && /root/.asdf/bin/asdf install flux2 ${FLUX2_VERSION} && /root/.asdf/bin/asdf global flux2 ${FLUX2_VERSION}
RUN /root/.asdf/bin/asdf plugin add direnv && /root/.asdf/bin/asdf install direnv ${DIRENV_VERSION} && /root/.asdf/bin/asdf global direnv ${DIRENV_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubespy && /root/.asdf/bin/asdf install kubespy ${KUBESPY_VERSION} && /root/.asdf/bin/asdf global kubespy ${KUBESPY_VERSION}
RUN /root/.asdf/bin/asdf plugin add kubeconform && /root/.asdf/bin/asdf install kubeconform ${KUBECONFORM_VERSION} && /root/.asdf/bin/asdf global kubeconform ${KUBECONFORM_VERSION}
RUN /root/.asdf/bin/asdf plugin add popeye && /root/.asdf/bin/asdf install popeye ${POPEYE_VERSION} && /root/.asdf/bin/asdf global popeye ${POPEYE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kube-score && /root/.asdf/bin/asdf install kube-score ${KUBE_SCORE_VERSION} && /root/.asdf/bin/asdf global kube-score ${KUBE_SCORE_VERSION}
RUN /root/.asdf/bin/asdf plugin add kube-linter && /root/.asdf/bin/asdf install kube-linter ${KUBE_LINTER_VERSION} && /root/.asdf/bin/asdf global kube-linter ${KUBE_LINTER_VERSION}

# install kubectl-oidc-login, download it from github release
# if PLATFORM is linux/amd64, download from https://github.com/int128/kubelogin/releases/download/<OIDC_LOGIN_VERSION>/kubelogin_linux_amd64.zip
# if PLATFORM is linux/arm64, download from https://github.com/int128/kubelogin/releases/download/<OIDC_LOGIN_VERSION>/kubelogin_linux_arm64.zip
RUN if [ -z "$PLATFORM" ]; then PLATFORM=$(uname -m); fi && \
    if [ "$PLATFORM" = "x86_64" ]; then PLATFORM="amd64"; fi && \
    if [ "$PLATFORM" = "aarch64" ]; then PLATFORM="arm64"; fi && \
    if [ "$PLATFORM" = "armv7l" ]; then PLATFORM="arm"; fi && \
    if [ "$PLATFORM" = "armv6l" ]; then PLATFORM="arm"; fi && \
    echo "PLATFORM=$PLATFORM" && case ${PLATFORM} in \
        amd64) \
            curl -L -o /tmp/kubelogin.zip https://github.com/int128/kubelogin/releases/download/${OIDC_LOGIN_VERSION}/kubelogin_linux_amd64.zip \
            ;; \
        arm64) \
            curl -L -o /tmp/kubelogin.zip https://github.com/int128/kubelogin/releases/download/${OIDC_LOGIN_VERSION}/kubelogin_linux_arm64.zip \
            ;; \
        *) \
            echo "Unsupported platform: ${PLATFORM}" \
            exit 1 \
            ;; \
    esac && \
    unzip /tmp/kubelogin.zip && \
    mv kubelogin /usr/local/bin/kubectl-oidc_login && \
    chmod +x /usr/local/bin/kubectl-oidc_login


# cleanup
RUN apt-get clean && rm -r /var/lib/apt/lists/* && rm -r /var/cache/* && rm -r /tmp/*
