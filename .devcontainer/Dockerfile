FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG KIND_VERSION=v0.23.0
ARG KUBECTL_VERSION=v1.28.3
ARG HELM_VERSION=v3.13.2
ARG TERRAFORM_VERSION=1.6.3

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

ENV KIND_CLUSTER_NAME=workspace
