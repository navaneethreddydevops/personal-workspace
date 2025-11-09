#!/usr/bin/env bash
# Normalizes docker socket permissions without hanging on sudo prompts.
set -uo pipefail

SOCKET_PATH="${DOCKER_SOCKET_PATH:-/var/run/docker.sock}"

if [[ ! -S "${SOCKET_PATH}" ]]; then
  echo "[fix-docker-permissions] Socket '${SOCKET_PATH}' not found. Skipping."
  exit 0
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  chown root:root "${SOCKET_PATH}" && chmod 666 "${SOCKET_PATH}"
  exit 0
fi

if command -v sudo >/dev/null 2>&1; then
  if sudo -n true >/dev/null 2>&1; then
    sudo chown root:root "${SOCKET_PATH}" && sudo chmod 666 "${SOCKET_PATH}"
  else
    echo "[fix-docker-permissions] sudo requires a password; skipping permission fix."
  fi
else
  echo "[fix-docker-permissions] sudo not available; skipping permission fix."
fi

exit 0
