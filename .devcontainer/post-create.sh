#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_SCRIPT="${ROOT_DIR}/scripts/setup-kubernetes.sh"

if [[ ! -f "${SETUP_SCRIPT}" ]]; then
  echo "Expected ${SETUP_SCRIPT} to exist. Please add scripts/setup-kubernetes.sh" >&2
  exit 1
fi

chmod +x "${SETUP_SCRIPT}"

"${SETUP_SCRIPT}" --validate-only

# If docker is present and the host socket is mounted, add the vscode user to the docker group
if command -v docker >/dev/null 2>&1; then
  if [ -S /var/run/docker.sock ]; then
    echo "Docker CLI found and socket present. Ensuring 'vscode' is in the docker group..."
    if [ "$(id -u)" -eq 0 ]; then
      # running as root inside container
      usermod -aG docker vscode || true
    elif command -v sudo >/dev/null 2>&1; then
      sudo usermod -aG docker vscode || true
    else
      echo "Note: cannot add 'vscode' to 'docker' group (not running as root and sudo not available)."
      echo "If you see permission errors when using docker, reopen the container with the Docker socket mounted and run as root: 'sudo usermod -aG docker vscode'"
    fi
  else
    echo "Docker CLI is installed inside the container, but /var/run/docker.sock is not present."
    echo "To use the host Docker daemon, reopen the dev container with the Docker socket mounted."
  fi
else
  echo "Docker CLI not found inside the container. The image may not have the Docker client installed."
fi
