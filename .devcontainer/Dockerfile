FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG K3D_VERSION=v5.7.4
ARG KUBECTL_VERSION=v1.28.3
ARG HELM_VERSION=v3.13.2
ARG TERRAFORM_VERSION=1.6.3
ARG KUSTOMIZE_VERSION=v5.3.0
ARG K9S_VERSION=v0.32.4
ARG KUBECTX_VERSION=v0.9.5
ARG KUBENS_VERSION=v0.9.5
ARG STERN_VERSION=v1.29.0
ARG SKAFFOLD_VERSION=v2.10.0
ARG FLUX_VERSION=v2.3.0
ARG ARGOCD_VERSION=v2.9.5
ARG YQ_VERSION=v4.44.1

ENV DOCKER_BUILDKIT=1 \
    DOCKER_HOST=unix:///var/run/docker.sock \
    DOCKER_TLS_CERTDIR="" \
    K3D_CLUSTER_NAME=workspace

# Install basic tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    fuse-overlayfs \
    git \
    gnupg \
    jq \
    less \
    make \
    sudo \
    unzip \
    vim \
    zip \
    python3 \
    python3-pip \
    awscli \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Docker and set up permissions
RUN curl -fsSL https://get.docker.com | sh && \
    groupadd -f docker && \
    usermod -aG docker vscode && \
    mkdir -p /var/run /var/lib/docker

# Install k3d (lightweight k3s in Docker)
RUN curl -fsSL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o /usr/local/bin/k3d \
    && chmod +x /usr/local/bin/k3d

# Install kubectl
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Install Helm
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

# Install Terraform
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Kustomize
RUN curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tar.gz \
    && tar -xzf /tmp/kustomize.tar.gz -C /tmp \
    && mv /tmp/kustomize /usr/local/bin/kustomize \
    && rm -f /tmp/kustomize.tar.gz

# Install k9s
RUN curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" -o /tmp/k9s.tar.gz \
    && tar -xzf /tmp/k9s.tar.gz -C /tmp k9s \
    && mv /tmp/k9s /usr/local/bin/k9s \
    && rm -f /tmp/k9s.tar.gz

# Install kubectx and kubens
RUN curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx" -o /usr/local/bin/kubectx \
    && chmod +x /usr/local/bin/kubectx \
    && curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBENS_VERSION}/kubens" -o /usr/local/bin/kubens \
    && chmod +x /usr/local/bin/kubens

# Install stern
RUN STERN_VERSION_STR="${STERN_VERSION#v}" \
    && curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION_STR}_linux_amd64.tar.gz" -o /tmp/stern.tar.gz \
    && tar -xzf /tmp/stern.tar.gz -C /tmp stern \
    && mv /tmp/stern /usr/local/bin/stern \
    && rm -f /tmp/stern.tar.gz

# Install Skaffold
RUN curl -fsSL "https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64" -o /usr/local/bin/skaffold \
    && chmod +x /usr/local/bin/skaffold

# Install Flux CLI
RUN FLUX_VERSION_STR="${FLUX_VERSION#v}" \
    && curl -fsSL "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION_STR}_linux_amd64.tar.gz" -o /tmp/flux.tar.gz \
    && tar -xzf /tmp/flux.tar.gz -C /tmp flux \
    && mv /tmp/flux /usr/local/bin/flux \
    && rm -f /tmp/flux.tar.gz

# Install Argo CD CLI
RUN curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64" -o /usr/local/bin/argocd \
    && chmod +x /usr/local/bin/argocd

# Install yq
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

VOLUME /var/lib/docker

COPY --chmod=755 <<'EOF' /usr/local/bin/dind-entrypoint.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${DOCKER_DAEMON_LOG:-/var/log/dockerd.log}"

detect_storage_driver() {
  if [[ -n "${DOCKER_STORAGE_DRIVER:-}" ]]; then
    echo "${DOCKER_STORAGE_DRIVER}"
    return
  fi

  local backing_fs
  backing_fs="$(df -PT /var/lib/docker 2>/dev/null | awk 'NR==2 {print $2}' || true)"

  if [[ "${backing_fs}" == "overlay" || "${backing_fs}" == "overlayfs" ]]; then
    if command -v fuse-overlayfs >/dev/null 2>&1; then
      echo "fuse-overlayfs"
      return
    fi
    echo "vfs"
    return
  fi

  if grep -qw overlay /proc/filesystems; then
    echo "overlay2"
  else
    echo "vfs"
  fi
}

start_dockerd() {
  mkdir -p /var/run /var/log /var/lib/docker
  : > "${LOG_FILE}"

  local storage_driver
  storage_driver="$(detect_storage_driver)"
  local daemon_cmd=(dockerd "--host=${DOCKER_HOST}" "--storage-driver=${storage_driver}")

  if [[ "$(id -u)" -eq 0 ]]; then
    nohup "${daemon_cmd[@]}" > "${LOG_FILE}" 2>&1 &
  elif command -v sudo >/dev/null 2>&1; then
    nohup sudo -E "${daemon_cmd[@]}" > "${LOG_FILE}" 2>&1 &
  else
    echo "Docker daemon requires root or sudo" >&2
    exit 1
  fi
}

wait_for_docker() {
  for _ in {1..30}; do
    if docker info >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Docker daemon failed to start. Check ${LOG_FILE}." >&2
  return 1
}

if ! docker info >/dev/null 2>&1; then
  start_dockerd
  wait_for_docker
fi

exec "$@"
EOF

ENTRYPOINT ["/usr/local/bin/dind-entrypoint.sh"]
CMD ["sleep", "infinity"]
