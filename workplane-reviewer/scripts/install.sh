#!/usr/bin/env bash
set -euo pipefail

# Workplane CLI installer — downloads the latest compiled binary for the current platform.
# Works with both public and private repos (uses gh CLI if available for auth).
# Usage: bash scripts/install.sh [--install-dir /path]

REPO="work-plane/workplane"
TAG="cli-latest"
INSTALL_DIR="${HOME}/.local/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
  linux)  PLATFORM="linux" ;;
  darwin) PLATFORM="darwin" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64)  ARCH_SUFFIX="x64" ;;
  aarch64|arm64) ARCH_SUFFIX="arm64" ;;
  *)             echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

BINARY_NAME="workplane-${PLATFORM}-${ARCH_SUFFIX}"

mkdir -p "$INSTALL_DIR"

echo "Downloading workplane CLI (${PLATFORM}-${ARCH_SUFFIX})..."

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  # Use gh CLI for authenticated download (works with private repos)
  gh release download "$TAG" --repo "$REPO" --pattern "$BINARY_NAME" --dir "$INSTALL_DIR" --clobber
  mv "${INSTALL_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/workplane"
else
  # Fall back to curl for public repos
  URL="https://github.com/${REPO}/releases/download/${TAG}/${BINARY_NAME}"
  curl -fsSL "$URL" -o "${INSTALL_DIR}/workplane"
fi

chmod +x "${INSTALL_DIR}/workplane"
echo "Installed to ${INSTALL_DIR}/workplane"

# Verify
if command -v workplane &>/dev/null; then
  echo "Version: $(workplane --version 2>/dev/null || echo 'installed')"
else
  echo "NOTE: ${INSTALL_DIR} is not in your PATH. Add it:"
  echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
fi
