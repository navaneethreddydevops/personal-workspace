#!/usr/bin/env bash
set -euo pipefail

SOCKET_PATH="${DOCKER_SOCKET_PATH:-/var/run/docker.sock}"
LOG_FILE="${DOCKER_DAEMON_LOG:-/tmp/dockerd.log}"

docker_cli_available() {
  command -v docker >/dev/null 2>&1
}

daemon_running() {
  docker info >/dev/null 2>&1
}

start_daemon() {
  local start_cmd=(dockerd "--host=unix://${SOCKET_PATH}")

  echo "[start-docker] Launching Docker daemon (socket: ${SOCKET_PATH})"

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
      sudo nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
      return
    fi
    echo "[start-docker] sudo is unavailable (missing privileges or password required); falling back to non-sudo startup."
  else
    echo "[start-docker] sudo not available; attempting to start dockerd without it."
  fi

  nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
}

wait_for_daemon() {
  local retries=30
  local delay=1

  for ((i=1; i<=retries; i++)); do
    if daemon_running; then
      echo "[start-docker] Docker daemon is ready."
      return 0
    fi
    sleep "${delay}"
  done
  echo "[start-docker] Docker daemon failed to start. Check ${LOG_FILE} for details." >&2
  return 1
}

main() {
  if ! docker_cli_available; then
    echo "[start-docker] Docker CLI is not installed; skipping daemon startup." >&2
    return 0
  fi

  if daemon_running; then
    echo "[start-docker] Docker daemon already running."
    return 0
  fi

  mkdir -p "$(dirname "${LOG_FILE}")"
  : > "${LOG_FILE}"

  start_daemon
  wait_for_daemon
}

main "$@"
