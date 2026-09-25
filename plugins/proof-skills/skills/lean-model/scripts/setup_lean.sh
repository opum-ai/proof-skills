#!/usr/bin/env bash
# Install elan (the Lean toolchain manager) without sudo.
#
#   setup_lean.sh [--elan-home DIR] [--toolchain leanprover/lean4:v4.34.0]
#
# Default ELAN_HOME is ~/.elan (elan's own default). Projects pin their exact toolchain
# in `lean-toolchain`; elan downloads it on first `lake build`.
set -euo pipefail
TOOLCHAIN="leanprover/lean4:v4.34.0"
while [ $# -gt 0 ]; do
  case "$1" in
    --elan-home) export ELAN_HOME="$2"; shift ;;
    --toolchain) TOOLCHAIN="$2"; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
if command -v elan >/dev/null 2>&1; then
  echo "elan already installed: $(elan --version)"
else
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --no-modify-path --default-toolchain "$TOOLCHAIN"
fi
EH="${ELAN_HOME:-$HOME/.elan}"
echo "Add to PATH:  export PATH=\"$EH/bin:\$PATH\""
"$EH/bin/elan" toolchain install "$TOOLCHAIN" >/dev/null 2>&1 || true
"$EH/bin/lean" --version || true
