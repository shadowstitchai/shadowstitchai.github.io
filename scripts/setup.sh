#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$ROOT/bin"
OSSUTIL_VERSION="2.2.1"

detect_platform() {
  local os arch
  case "$(uname -s)" in
    Darwin)
      os="mac"
      case "$(uname -m)" in
        arm64) arch="arm64" ;;
        *) arch="amd64" ;;
      esac
      ;;
    Linux)
      os="linux"
      case "$(uname -m)" in
        aarch64|arm64) arch="arm64" ;;
        *) arch="amd64" ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $(uname -s). Install ossutil manually and add it to PATH." >&2
      exit 1
      ;;
  esac
  echo "${os}-${arch}"
}

install_ossutil() {
  if [[ -x "$BIN_DIR/ossutil" ]]; then
    echo "ossutil already installed: $($BIN_DIR/ossutil version 2>/dev/null || echo ok)"
    return
  fi

  local platform archive url tmpdir
  platform="$(detect_platform)"
  archive="ossutil-${OSSUTIL_VERSION}-${platform}.zip"
  url="https://gosspublic.alicdn.com/ossutil/v2/${OSSUTIL_VERSION}/${archive}"

  echo "Downloading ossutil ${OSSUTIL_VERSION} (${platform})..."
  tmpdir="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmpdir/$archive"
  unzip -q "$tmpdir/$archive" -d "$tmpdir"

  mkdir -p "$BIN_DIR"
  cp "$tmpdir/ossutil-${OSSUTIL_VERSION}-${platform}/ossutil" "$BIN_DIR/ossutil"
  chmod +x "$BIN_DIR/ossutil"
  rm -rf "$tmpdir"

  echo "Installed ossutil to $BIN_DIR/ossutil"
  "$BIN_DIR/ossutil" version
}

echo "==> Installing ossutil"
install_ossutil

echo "==> Installing Ruby gems"
cd "$ROOT"
bundle install --path vendor/bundle

if [[ ! -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  echo ""
  echo "Created .env from .env.example — edit it with your OSS credentials before deploying."
fi

echo ""
echo "Setup complete. Next: edit .env, then run ./scripts/deploy-oss.sh"
