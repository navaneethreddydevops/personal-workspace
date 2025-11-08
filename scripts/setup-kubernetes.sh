#!/usr/bin/env bash
# Utility script to bootstrap a local kind-based Kubernetes cluster inside the devcontainer.

set -euo pipefail

CLUSTER_NAME="${KIND_CLUSTER_NAME:-workspace}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
WAIT_SECONDS=60
DELETE_CLUSTER=false
VALIDATE_ONLY=false

usage() {
  cat <<'EOF'
Usage: setup-kubernetes.sh [options]

Options:
  --delete            Delete the kind cluster instead of creating/updating it.
  --wait <seconds>    Seconds to wait for the cluster to become ready (default 60).
  --validate-only     Only verify that required tools are installed.
  -h, --help          Show this help message.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --delete)
        DELETE_CLUSTER=true
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
      --validate-only)
        VALIDATE_ONLY=true
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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

validate_tools() {
  require_cmd docker
  require_cmd kind
  require_cmd kubectl
  require_cmd helm
  require_cmd terraform
  require_cmd python3
}

cluster_exists() {
  kind get clusters 2>/dev/null | grep -qw "${CLUSTER_NAME}"
}

create_cluster() {
  if cluster_exists; then
    echo "kind cluster \"${CLUSTER_NAME}\" already exists."
    return 0
  fi

  echo "Creating kind cluster \"${CLUSTER_NAME}\"..."
  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --wait "${WAIT_SECONDS}s"

  echo "Cluster created. KUBECONFIG=${KUBECONFIG_PATH}"
}

delete_cluster() {
  if ! cluster_exists; then
    echo "kind cluster \"${CLUSTER_NAME}\" does not exist."
    return 0
  fi

  echo "Deleting kind cluster \"${CLUSTER_NAME}\"..."
  kind delete cluster --name "${CLUSTER_NAME}"
}

main() {
  parse_args "$@"
  validate_tools

  if [[ "${VALIDATE_ONLY}" == "true" ]]; then
    echo "All required tools are available."
    exit 0
  fi

  if [[ "${DELETE_CLUSTER}" == "true" ]]; then
    delete_cluster
  else
    create_cluster
  fi
}

main "$@"
