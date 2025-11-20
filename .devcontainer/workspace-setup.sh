#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SOCKET_PATH="${DOCKER_SOCKET_PATH:-/var/run/docker.sock}"
LOG_FILE="${DOCKER_DAEMON_LOG:-/tmp/dockerd.log}"

log() {
  echo "[${SCRIPT_NAME}] $*"
}

normalize_bool() {
  local value="${1:-false}"
  # Bash 3 (macOS default) lacks ${var,,}; use tr for portability.
  local normalized
  normalized="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"
  case "${normalized}" in
    1|true|yes|on) echo "true" ;;
    *) echo "false" ;;
  esac
}

CLUSTER_NAME="${K3D_CLUSTER_NAME:-workspace}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
DEFAULT_WAIT="${K3D_WAIT_SECONDS:-60}"
DEFAULT_AUTO_CREATE="$(normalize_bool "${K3D_AUTO_CREATE:-true}")"

WAIT_SECONDS="${DEFAULT_WAIT}"
AUTO_CREATE="${DEFAULT_AUTO_CREATE}"
VALIDATE_ONLY=false
DELETE_CLUSTER=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  init             Normalize Docker socket permissions before the container builds.
  post-create      Validate tooling, ensure Docker/k3d (k3s), and optionally create a cluster.
  post-start       Ensure the Docker daemon stays running after Codespace start.
  delete           Delete the configured k3d cluster.
  validate         Verify CLI dependencies only.
  help             Show this help message.

Options (post-create/delete/validate):
  --wait <seconds>        Override k3d wait time (default ${DEFAULT_WAIT}).
  --auto-create           Force cluster creation even if K3D_AUTO_CREATE=false.
  --no-auto-create        Skip cluster creation even if K3D_AUTO_CREATE=true.
  --validate-only         Only validate dependencies.
  --delete                Delete the cluster instead of creating it.
  -h, --help              Show this message.
EOF
}

reset_cluster_flags() {
  WAIT_SECONDS="${DEFAULT_WAIT}"
  AUTO_CREATE="${DEFAULT_AUTO_CREATE}"
  VALIDATE_ONLY=false
  DELETE_CLUSTER=false
}

parse_cluster_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --wait)
        WAIT_SECONDS="${2:-}"
        if [[ -z "${WAIT_SECONDS}" ]]; then
          echo "--wait requires a value" >&2
          exit 1
        fi
        shift 2
        ;;
      --auto-create)
        AUTO_CREATE="true"
        shift
        ;;
      --no-auto-create)
        AUTO_CREATE="false"
        shift
        ;;
      --validate-only)
        VALIDATE_ONLY=true
        shift
        ;;
      --delete)
        DELETE_CLUSTER=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

fix_docker_permissions() {
  if [[ ! -S "${SOCKET_PATH}" ]]; then
    log "Docker socket ${SOCKET_PATH} not found; skipping permission fix."
    return 0
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    chown root:root "${SOCKET_PATH}"
    chmod 666 "${SOCKET_PATH}"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
      sudo chown root:root "${SOCKET_PATH}"
      sudo chmod 666 "${SOCKET_PATH}"
    else
      log "sudo requires a password; skipping docker socket permission fix."
    fi
  else
    log "sudo not available; skipping docker socket permission fix."
  fi
}

docker_cli_available() {
  command -v docker >/dev/null 2>&1
}

docker_daemon_running() {
  docker info >/dev/null 2>&1
}

start_docker_daemon() {
  local start_cmd=(dockerd "--host=unix://${SOCKET_PATH}")
  log "Launching Docker daemon (socket: ${SOCKET_PATH})"

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
      sudo nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
      return
    fi
    log "sudo unavailable for dockerd startup; falling back to non-sudo execution."
  else
    log "sudo not installed; attempting non-sudo dockerd start."
  fi

  nohup "${start_cmd[@]}" > "${LOG_FILE}" 2>&1 &
}

wait_for_docker() {
  local retries=30
  local delay=1
  for ((i=1; i<=retries; i++)); do
    if docker_daemon_running; then
      log "Docker daemon is ready."
      return 0
    fi
    sleep "${delay}"
  done
  log "Docker daemon failed to start after ${retries} seconds; check ${LOG_FILE}."
  return 1
}

ensure_docker_daemon() {
  if ! docker_cli_available; then
    log "Docker CLI not installed; skipping daemon start."
    return 0
  fi

  if docker_daemon_running; then
    log "Docker daemon already running."
    return 0
  fi

  mkdir -p "$(dirname "${LOG_FILE}")"
  : > "${LOG_FILE}"

  start_docker_daemon
  wait_for_docker
}

ensure_kubeconfig_dir() {
  mkdir -p "$(dirname "${KUBECONFIG_PATH}")"
}

validate_tools() {
  local missing=0
  local tools=(docker k3d kubectl helm terraform python3)

  for tool in "${tools[@]}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      log "Missing dependency: ${tool}"
      missing=1
    fi
  done

  return "${missing}"
}

k3d_cluster_exists() {
  k3d cluster list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qw "${CLUSTER_NAME}"
}

create_k3d_cluster() {
  if k3d_cluster_exists; then
    log "k3d cluster '${CLUSTER_NAME}' already exists."
    return 0
  fi

  log "Creating k3d (k3s) cluster '${CLUSTER_NAME}' (wait=${WAIT_SECONDS}s)"
  if k3d cluster create "${CLUSTER_NAME}" --kubeconfig-update-default --kubeconfig-switch-context --wait --timeout "${WAIT_SECONDS}s"; then
    log "Cluster created. KUBECONFIG=${KUBECONFIG_PATH}"
  else
    log "k3d cluster creation failed"
  fi
}

delete_k3d_cluster() {
  if ! k3d_cluster_exists; then
    log "k3d cluster '${CLUSTER_NAME}' does not exist."
    return 0
  fi

  log "Deleting k3d cluster '${CLUSTER_NAME}'"
  if ! k3d cluster delete "${CLUSTER_NAME}"; then
    log "k3d cluster deletion failed"
  fi
}

export_k3d_kubeconfig() {
  if ! k3d_cluster_exists; then
    log "Cluster '${CLUSTER_NAME}' not found; skipping kubeconfig export."
    return 0
  fi

  ensure_kubeconfig_dir
  log "Exporting kubeconfig to ${KUBECONFIG_PATH}"
  if ! k3d kubeconfig get "${CLUSTER_NAME}" > "${KUBECONFIG_PATH}"; then
    log "k3d kubeconfig export failed"
  fi
}

run_cluster_flow() {
  fix_docker_permissions
  ensure_kubeconfig_dir
  ensure_docker_daemon

  if ! validate_tools; then
    log "Validation failed; skipping cluster automation."
    return 0
  fi

  if [[ "${VALIDATE_ONLY}" == "true" ]]; then
    log "All required tools are available."
    return 0
  fi

  if [[ "${DELETE_CLUSTER}" == "true" ]]; then
    delete_k3d_cluster
    return 0
  fi

  if [[ "${AUTO_CREATE}" == "true" ]]; then
    create_k3d_cluster
  else
    log "K3D_AUTO_CREATE=false; skipping cluster creation."
  fi

  export_k3d_kubeconfig
}

run_init() {
  fix_docker_permissions
}

run_post_start() {
  fix_docker_permissions
  ensure_docker_daemon
}

run_post_create() {
  reset_cluster_flags
  parse_cluster_flags "$@"
  run_cluster_flow
}

run_delete() {
  reset_cluster_flags
  DELETE_CLUSTER=true
  parse_cluster_flags "$@"
  run_cluster_flow
}

run_validate() {
  reset_cluster_flags
  VALIDATE_ONLY=true
  parse_cluster_flags "$@"
  run_cluster_flow
}

COMMAND="post-create"
if [[ $# -gt 0 ]]; then
  COMMAND="$1"
  shift
fi

case "${COMMAND}" in
  init)
    if [[ $# -gt 0 ]]; then
      usage
      exit 1
    fi
    run_init
    ;;
  post-create)
    run_post_create "$@"
    ;;
  post-start)
    if [[ $# -gt 0 ]]; then
      usage
      exit 1
    fi
    run_post_start
    ;;
  delete)
    run_delete "$@"
    ;;
  validate)
    run_validate "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: ${COMMAND}" >&2
    usage
    exit 1
    ;;
esac
