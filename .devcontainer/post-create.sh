#!/usr/bin/env bash
# Remove strict mode to prevent script from failing
set -uo pipefail

echo "Starting post-create setup..."

# Set up docker permissions first
if command -v docker >/dev/null 2>&1; then
  echo "Docker CLI found. Setting up permissions..."
  
  if [ -S /var/run/docker.sock ]; then
    echo "Docker socket found at /var/run/docker.sock"
    
    # Ensure docker socket has correct permissions
    if command -v sudo >/dev/null 2>&1; then
      echo "Setting docker socket permissions..."
      sudo chmod 666 /var/run/docker.sock || echo "Failed to set docker socket permissions"
      
      echo "Adding vscode user to docker group..."
      sudo usermod -aG docker vscode || echo "Failed to add vscode user to docker group"
      
      echo "Refreshing group membership..."
      newgrp docker || echo "Failed to refresh group membership"
    else
      echo "Warning: sudo not available. Manual permission setup may be required."
      chmod 666 /var/run/docker.sock || echo "Failed to set docker socket permissions without sudo"
    fi
    
    # Verify permissions
    ls -l /var/run/docker.sock
    groups vscode
  else
    echo "Warning: Docker socket not found at /var/run/docker.sock"
  fi
else
  echo "Warning: Docker CLI not found in container"
fi

# Continue with Kubernetes setup
echo "Starting Kubernetes setup..."
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_SCRIPT="${ROOT_DIR}/scripts/setup-kubernetes.sh"

if [[ ! -f "${SETUP_SCRIPT}" ]]; then
  echo "Warning: ${SETUP_SCRIPT} does not exist. Skipping Kubernetes setup."
else
  echo "Found setup script at ${SETUP_SCRIPT}"
  chmod +x "${SETUP_SCRIPT}"
  "${SETUP_SCRIPT}" --validate-only || echo "Warning: Kubernetes validation failed"
fi

# If docker is present and the host socket is mounted, set up docker permissions
if command -v docker >/dev/null 2>&1; then
  if [ -S /var/run/docker.sock ]; then
    echo "Docker CLI found and socket present. Setting up permissions..."
    
    # Ensure docker socket has correct permissions
    if command -v sudo >/dev/null 2>&1; then
      sudo chmod 666 /var/run/docker.sock || true
      # Add vscode user to docker group
      sudo usermod -aG docker vscode || true
      # Refresh group membership
      newgrp docker || true
    else
      echo "Note: sudo not available. If you see permission errors when using docker,"
      echo "try running: chmod 666 /var/run/docker.sock"
    fi
  else
    echo "Docker CLI is installed inside the container, but /var/run/docker.sock is not present."
    echo "To use the host Docker daemon, reopen the dev container with the Docker socket mounted."
  fi
else
  echo "Docker CLI not found inside the container. The image may not have the Docker client installed."
fi
