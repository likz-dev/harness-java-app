#!/usr/bin/env bash
# Local Minikube cluster for demos.
#
# Usage:
#   ./scripts/minikube-demo.sh start   # create/start cluster + demo addons
#   ./scripts/minikube-demo.sh status  # show cluster + node health
#   ./scripts/minikube-demo.sh stop    # stop (keeps state)
#   ./scripts/minikube-demo.sh reset   # delete and recreate
#   ./scripts/minikube-demo.sh delete  # tear down completely
#
# Env overrides:
#   PROFILE=demo CPUS=4 MEMORY=4g DISK_SIZE=40g DRIVER=docker

set -euo pipefail

PROFILE="${PROFILE:-demo}"
CPUS="${CPUS:-4}"
MEMORY="${MEMORY:-4g}"
DISK_SIZE="${DISK_SIZE:-40g}"
DRIVER="${DRIVER:-docker}"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-stable}"

# Demo addons enabled on start
ADDONS=(ingress metrics-server dashboard)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()  { printf '%b\n' "${GREEN}==>${NC} $*"; }
warn() { printf '%b\n' "${YELLOW}warn:${NC} $*"; }
die()  { printf '%b\n' "${RED}error:${NC} $*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not found in PATH"
}

check_prereqs() {
  need minikube
  need kubectl
  need docker

  if ! docker info >/dev/null 2>&1; then
    die "Docker is not running. Start Docker Desktop (or your Docker daemon) and retry."
  fi
}

cluster_exists() {
  minikube profile list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$PROFILE"
}

start_cluster() {
  check_prereqs

  if cluster_exists; then
    log "Starting existing profile '${PROFILE}'..."
    minikube start -p "$PROFILE"
  else
    log "Creating Minikube profile '${PROFILE}' (${CPUS} CPU, ${MEMORY} memory, driver=${DRIVER})..."
    minikube start \
      -p "$PROFILE" \
      --driver="$DRIVER" \
      --cpus="$CPUS" \
      --memory="$MEMORY" \
      --disk-size="$DISK_SIZE" \
      --kubernetes-version="$KUBERNETES_VERSION" \
      --extra-config=apiserver.service-node-port-range=1-65535
  fi

  log "Waiting for node Ready..."
  kubectl --context="$PROFILE" wait --for=condition=Ready node --all --timeout=180s

  for addon in "${ADDONS[@]}"; do
    log "Enabling addon: ${addon}"
    minikube addons enable "$addon" -p "$PROFILE" >/dev/null
  done

  # Point kubectl at this profile by default for the shell that sources nothing —
  # minikube already updates kubeconfig; remind the operator.
  minikube update-context -p "$PROFILE" >/dev/null 2>&1 || true

  log "Cluster ready."
  print_status
  cat <<EOF

Useful next steps:
  kubectl --context=${PROFILE} get nodes
  kubectl --context=${PROFILE} get pods -A
  minikube dashboard -p ${PROFILE}          # Kubernetes dashboard
  minikube service list -p ${PROFILE}       # exposed services
  minikube tunnel -p ${PROFILE}             # LoadBalancer services (needs sudo)

EOF
}

print_status() {
  check_prereqs
  echo
  minikube status -p "$PROFILE" || true
  echo
  if kubectl --context="$PROFILE" get nodes >/dev/null 2>&1; then
    kubectl --context="$PROFILE" get nodes -o wide
    echo
    kubectl --context="$PROFILE" get pods -A --field-selector=status.phase!=Succeeded 2>/dev/null \
      | head -40 || true
  else
    warn "kubectl cannot reach profile '${PROFILE}' (is it running?)"
  fi
}

stop_cluster() {
  check_prereqs
  log "Stopping profile '${PROFILE}'..."
  minikube stop -p "$PROFILE"
}

delete_cluster() {
  check_prereqs
  log "Deleting profile '${PROFILE}'..."
  minikube delete -p "$PROFILE"
}

reset_cluster() {
  delete_cluster
  start_cluster
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  start    Create (if needed) and start the demo cluster
  status   Show cluster and node status
  stop     Stop the cluster (state preserved)
  reset    Delete and recreate the cluster
  delete   Delete the cluster entirely

Environment:
  PROFILE=${PROFILE}
  CPUS=${CPUS}
  MEMORY=${MEMORY}
  DISK_SIZE=${DISK_SIZE}
  DRIVER=${DRIVER}
  KUBERNETES_VERSION=${KUBERNETES_VERSION}
EOF
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    start)  start_cluster ;;
    status) print_status ;;
    stop)   stop_cluster ;;
    reset)  reset_cluster ;;
    delete) delete_cluster ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command: $cmd (try --help)" ;;
  esac
}

main "$@"
