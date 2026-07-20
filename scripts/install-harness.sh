#!/usr/bin/env bash
# Install Harness CLIs:
#   - hc     : new unified CLI (v1)
#   - harness: legacy v0 CLI (gitops-cluster, pipelines, etc.)
#
# Usage:
#   ./scripts/install-harness.sh
#   HARNESS_CLI_VERSION=1.3.34 HARNESS_V0_VERSION=0.0.25-Preview \
#     INSTALL_DIR="$HOME/.local/bin" ./scripts/install-harness.sh
#
# Skip one side:
#   INSTALL_HC=0 ./scripts/install-harness.sh     # v0 only
#   INSTALL_V0=0 ./scripts/install-harness.sh     # hc only

set -euo pipefail

HC_VERSION="${HARNESS_CLI_VERSION:-1.3.34}"
V0_VERSION="${HARNESS_V0_VERSION:-0.0.25-Preview}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
REPO="harness/harness-cli"
KEEP_ARCHIVE="${KEEP_ARCHIVE:-0}"
INSTALL_HC="${INSTALL_HC:-1}"
INSTALL_V0="${INSTALL_V0:-1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()  { printf '%b\n' "${GREEN}==>${NC} $*" >&2; }
warn() { printf '%b\n' "${YELLOW}warn:${NC} $*" >&2; }
die()  { printf '%b\n' "${RED}error:${NC} $*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not found in PATH"
}

detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
    Darwin|Linux) ;;
    *) die "unsupported OS: $OS (expected Darwin or Linux)" ;;
  esac

  case "$ARCH" in
    arm64|aarch64|x86_64|amd64) ;;
    *) die "unsupported architecture: $ARCH" ;;
  esac
}

# hc assets: hc_1.3.34_mac-os_arm64.tar.gz
hc_asset_name() {
  local os_label arch_label
  case "$OS" in
    Darwin) os_label="mac-os" ;;
    Linux)  os_label="linux" ;;
  esac
  case "$ARCH" in
    arm64|aarch64) arch_label="arm64" ;;
    x86_64|amd64)  arch_label="x86_64" ;;
  esac
  echo "hc_${HC_VERSION}_${os_label}_${arch_label}.tar.gz"
}

# v0 assets: harness-v0.0.25-Preview-darwin-amd64.tar.gz
# Only darwin-amd64 / linux-amd64 are published (Apple Silicon uses amd64 via Rosetta).
v0_asset_name() {
  local os_label="linux" arch_label="amd64"
  case "$OS" in
    Darwin) os_label="darwin" ;;
    Linux)  os_label="linux" ;;
  esac
  case "$ARCH" in
    arm64|aarch64)
      if [[ "$OS" == "Darwin" ]]; then
        warn "v0 CLI has no darwin-arm64 build; installing darwin-amd64 (requires Rosetta)"
        arch_label="amd64"
      else
        die "v0 CLI has no linux-arm64 build; set INSTALL_V0=0 or run on amd64"
      fi
      ;;
    x86_64|amd64) arch_label="amd64" ;;
  esac
  echo "harness-v${V0_VERSION}-${os_label}-${arch_label}.tar.gz"
}

ensure_install_dir() {
  mkdir -p "$INSTALL_DIR"
}

download_extract() {
  local url="$1" dest_dir="$2" archive_name="$3"
  curl -fL --progress-bar -o "${dest_dir}/${archive_name}" "$url" \
    || die "download failed: ${url}
Check https://github.com/${REPO}/releases for available assets."
  tar -xzf "${dest_dir}/${archive_name}" -C "$dest_dir"
  if [[ "$KEEP_ARCHIVE" == "1" ]]; then
    cp "${dest_dir}/${archive_name}" "./${archive_name}"
    log "Kept archive at ./${archive_name}"
  fi
}

install_hc() {
  local tmp asset url
  asset="$(hc_asset_name)"
  url="https://github.com/${REPO}/releases/download/v${HC_VERSION}/${asset}"
  tmp="$(mktemp -d)"
  HARNESS_CLI_TMP="$tmp"
  trap 'rm -rf "${HARNESS_CLI_TMP:-}"' EXIT

  log "Downloading hc (v1) ${HC_VERSION} (${asset})..."
  download_extract "$url" "$tmp" "$asset"

  if [[ ! -f "${tmp}/hc" ]]; then
    die "hc archive did not contain 'hc' (contents: $(ls -1 "$tmp"))"
  fi

  chmod +x "${tmp}/hc"
  # Remove any previous mistaken harness->hc symlink before installing real binaries.
  if [[ -L "${INSTALL_DIR}/harness" ]]; then
    log "Removing old symlink ${INSTALL_DIR}/harness"
    rm -f "${INSTALL_DIR}/harness"
  fi
  install -m 0755 "${tmp}/hc" "${INSTALL_DIR}/hc"
  log "Installed ${INSTALL_DIR}/hc"
}

install_v0() {
  local tmp asset url
  asset="$(v0_asset_name)"
  url="https://github.com/${REPO}/releases/download/v${V0_VERSION}/${asset}"
  tmp="$(mktemp -d)"
  HARNESS_CLI_TMP="$tmp"
  trap 'rm -rf "${HARNESS_CLI_TMP:-}"' EXIT

  log "Downloading harness (v0) ${V0_VERSION} (${asset})..."
  download_extract "$url" "$tmp" "$asset"

  if [[ ! -f "${tmp}/harness" ]]; then
    die "v0 archive did not contain 'harness' (contents: $(ls -1 "$tmp"))"
  fi

  chmod +x "${tmp}/harness"
  if [[ -L "${INSTALL_DIR}/harness" ]]; then
    log "Removing old symlink ${INSTALL_DIR}/harness"
    rm -f "${INSTALL_DIR}/harness"
  fi
  install -m 0755 "${tmp}/harness" "${INSTALL_DIR}/harness"
  log "Installed ${INSTALL_DIR}/harness"
}

path_contains_dir() {
  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) return 0 ;;
    *) return 1 ;;
  esac
}

shell_rc_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/zsh}")"
  case "$shell_name" in
    zsh)  echo "${HOME}/.zshrc" ;;
    bash)
      if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "${HOME}/.bash_profile"
      else
        echo "${HOME}/.bashrc"
      fi
      ;;
    *)    echo "${HOME}/.profile" ;;
  esac
}

ensure_path() {
  export PATH="${INSTALL_DIR}:${PATH}"

  if path_contains_dir; then
    log "PATH already includes ${INSTALL_DIR} for this session"
  else
    warn "${INSTALL_DIR} was prepended for this session only"
  fi

  local rc export_line
  rc="$(shell_rc_file)"
  export_line="export PATH=\"${INSTALL_DIR}:\$PATH\""

  if [[ -f "$rc" ]] && grep -Fqs "${INSTALL_DIR}" "$rc"; then
    log "PATH already configured in ${rc}"
    return
  fi

  printf '\n# Harness CLI (hc + harness)\n%s\n' "$export_line" >> "$rc"
  log "Added ${INSTALL_DIR} to PATH in ${rc}"
  warn "Run: source ${rc}   (or open a new terminal)"
}

verify() {
  if [[ "$INSTALL_HC" == "1" ]]; then
    command -v hc >/dev/null 2>&1 || die "hc not found on PATH (try: export PATH=\"${INSTALL_DIR}:\$PATH\")"
    log "hc version: $(hc version 2>/dev/null || echo unknown)"
  fi
  if [[ "$INSTALL_V0" == "1" ]]; then
    command -v harness >/dev/null 2>&1 || die "harness not found on PATH (try: export PATH=\"${INSTALL_DIR}:\$PATH\")"
    if [[ -L "$(command -v harness)" ]]; then
      die "$(command -v harness) is still a symlink; expected the real v0 binary"
    fi
    log "harness version: $(harness --version 2>/dev/null || harness version 2>/dev/null || echo unknown)"
  fi

  cat <<EOF

Installed CLIs:
  hc       — new CLI (auth, artifacts, registries, iacm)
  harness  — legacy v0 CLI (gitops-cluster, pipelines, connectors, …)

Examples:
  hc auth login
  harness login
  harness gitops-cluster --help

EOF
}

main() {
  need curl
  need tar
  need install

  detect_platform
  ensure_install_dir

  if [[ "$INSTALL_HC" != "1" && "$INSTALL_V0" != "1" ]]; then
    die "nothing to install (both INSTALL_HC and INSTALL_V0 are disabled)"
  fi

  # Always drop a stale harness->hc symlink first.
  if [[ -L "${INSTALL_DIR}/harness" ]]; then
    log "Removing old symlink ${INSTALL_DIR}/harness"
    rm -f "${INSTALL_DIR}/harness"
  fi

  if [[ "$INSTALL_HC" == "1" ]]; then
    install_hc
  fi
  if [[ "$INSTALL_V0" == "1" ]]; then
    install_v0
  fi

  ensure_path
  verify
}

main "$@"
