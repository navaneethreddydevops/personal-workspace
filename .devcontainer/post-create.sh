#!/usr/bin/env bash
# Remove strict mode to prevent script from failing
set -uo pipefail

CLUSTER_NAME="${KIND_CLUSTER_NAME:-workspace}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
WAIT_SECONDS="${KIND_WAIT_SECONDS:-60}"
DELETE_CLUSTER=false
VALIDATE_ONLY=false

normalize_bool() {
  local value="${1:-false}"
  case "${value,,}" in
    1|true|yes|on) echo "true" ;;
    *) echo "false" ;;
  esac
}

AUTO_CREATE="$(normalize_bool "${KIND_AUTO_CREATE:-true}")"

usage() {
  cat <<'EOF'
Usage: post-create.sh [options]

Options:
  --validate-only     Check required CLIs and exit.
  --delete            Delete the kind cluster instead of creating/updating it.
  --wait <seconds>    Seconds to wait for kind readiness (default 60).
  --auto-create       Force creation of the kind cluster even if KIND_AUTO_CREATE=false.
  --no-auto-create    Skip cluster creation even if KIND_AUTO_CREATE=true.
  -h, --help          Show this help message.
EOF
}

# Ensure ~/.kube exists so kubeconfig writes don't fail
ensure_kubeconfig_dir() {
  local kube_dir
  kube_dir="$(dirname "${KUBECONFIG_PATH}")"
  mkdir -p "${kube_dir}"
}

# Run privileged commands without hanging on sudo password prompts.
run_privileged() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
    return $?
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
      sudo "$@"
    else
      echo "Warning: sudo requires a password for '$*'. Skipping." >&2
      return 1
    fi
  else
    echo "Warning: sudo not available for '$*'. Skipping." >&2
    return 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --validate-only)
        VALIDATE_ONLY=true
        shift
        ;;
      --delete)
        DELETE_CLUSTER=true
        AUTO_CREATE="false"
        shift
        ;;
      --wait)
        WAIT_SECONDS="${2:-}"
        if [[ -z "${WAIT_SECONDS}" ]]; then
          echo "--wait requires an argument" >&2
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
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

ensure_docker_daemon() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "Docker daemon is already running."
    return 0
  fi

  local starter_script="./.devcontainer/start-docker.sh"
  if [[ ! -x "${starter_script}" ]]; then
    echo "Error: ${starter_script} is missing or not executable; cannot start Docker daemon." >&2
    return 1
  fi

  echo "Starting Docker daemon inside the devcontainer..."
  if ! bash "${starter_script}"; then
    echo "Error: Failed to start Docker daemon." >&2
    return 1
  fi
}

validate_tools() {
  local missing=0
  local tools=(docker kind kubectl helm terraform python3)

  for tool in "${tools[@]}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "Missing dependency: ${tool}" >&2
      missing=1
    fi
  done

  return "${missing}"
}

cluster_exists() {
  kind get clusters 2>/dev/null | grep -qw "${CLUSTER_NAME}"
}

export_kind_kubeconfig() {
  if ! cluster_exists; then
    echo "kind cluster \"${CLUSTER_NAME}\" not found; skipping kubeconfig export."
    return 0
  fi

  ensure_kubeconfig_dir

  echo "Exporting kubeconfig for kind cluster \"${CLUSTER_NAME}\"..."
  if ! kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_PATH}"; then
    echo "Warning: kind kubeconfig export failed" >&2
    return 1
  fi
}

create_kind_cluster() {
  if cluster_exists; then
    echo "kind cluster \"${CLUSTER_NAME}\" already exists."
    return 0
  fi

  echo "Creating kind cluster \"${CLUSTER_NAME}\" (wait=${WAIT_SECONDS}s)..."
  if kind create cluster --name "${CLUSTER_NAME}" --wait "${WAIT_SECONDS}s"; then
    echo "Cluster created. KUBECONFIG=${KUBECONFIG_PATH}"
  else
    echo "Warning: kind cluster creation failed" >&2
  fi
}

delete_kind_cluster() {
  if ! cluster_exists; then
    echo "kind cluster \"${CLUSTER_NAME}\" does not exist."
    return 0
  fi

  echo "Deleting kind cluster \"${CLUSTER_NAME}\"..."
  kind delete cluster --name "${CLUSTER_NAME}"
}

main() {
  parse_args "$@"

  echo "Starting post-create setup..."
  ensure_kubeconfig_dir
  ensure_docker_daemon

  echo "Starting Kubernetes setup..."
  if ! validate_tools; then
    echo "Warning: Kubernetes validation failed"
    return 0
  fi

  if [[ "${VALIDATE_ONLY}" == "true" ]]; then
    echo "All required tools are available."
    return 0
  fi

  if [[ "${DELETE_CLUSTER}" == "true" ]]; then
    delete_kind_cluster
    return 0
  fi

  if [[ "${AUTO_CREATE}" == "true" ]]; then
    create_kind_cluster
  else
    echo "KIND_AUTO_CREATE=false; skipping kind cluster creation."
  fi

  export_kind_kubeconfig
}

main "$@"
