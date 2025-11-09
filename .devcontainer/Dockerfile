FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG KIND_VERSION=v0.23.0
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

# Install basic tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    less \
    make \
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
    mkdir -p /var/run && \
    touch /var/run/docker.sock && \
    chmod 666 /var/run/docker.sock

# Add a script to fix permissions on container start
COPY --chmod=755 <<-"EOF" /usr/local/bin/fix-docker-permissions
#!/bin/bash
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
    echo "Fixed docker socket permissions"
fi
EOF

# Install KIND
RUN curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" -o /usr/local/bin/kind \
    && chmod +x /usr/local/bin/kind

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

ENV KIND_CLUSTER_NAME=workspace
