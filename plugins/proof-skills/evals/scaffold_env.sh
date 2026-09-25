#!/usr/bin/env bash
# Make your toolchains usable inside a `claude plugin eval` run. Sourced by bug-hunt scaffolds.
#
# Each run gets a throwaway $HOME, and its Bash sandbox cannot read your real home, so
# symlinks into it do not work. This script finds each tool's real install. If it lives
# under your real home, the script clones it into the run's $HOME (copy-on-write via `cp -c`
# on APFS, so it is near-instant and uses no extra disk). It then writes shell profiles that
# put the clones first on PATH. Tools outside your home (Homebrew, /usr) are used as-is.
set -euo pipefail
REAL_HOME="$(eval echo "~$(id -un)")"
TOOLS="$HOME/.eval-tools"
mkdir -p "$TOOLS" "$HOME/.cache"
clone() { [ -e "$2" ] || cp -cR "$1" "$2" 2>/dev/null || cp -R "$1" "$2"; }
under_home() { case "$1" in "$REAL_HOME"/*) return 0 ;; *) return 1 ;; esac; }
real() { HOME="$REAL_HOME" "$@" 2>/dev/null || true; }  # resolve with your real env (pyenv, nvm)

PATHS=()
# TLA+ tools and portable JRE (setup_tla.sh), and elan with its Lean toolchains.
[ -d "$REAL_HOME/.cache/proof-skills" ] && clone "$REAL_HOME/.cache/proof-skills" "$HOME/.cache/proof-skills"
[ -d "$REAL_HOME/.elan" ] && clone "$REAL_HOME/.elan" "$HOME/.elan" && PATHS+=("$HOME/.elan/bin")
# Python: the interpreter prefix (keeps its site-packages, e.g. pytest).
py_prefix="$(real python3 -c 'import sys; print(sys.prefix)')"
EXTRA=""
if [ -n "$py_prefix" ] && under_home "$py_prefix"; then
  clone "$py_prefix" "$TOOLS/python"; PATHS+=("$TOOLS/python/bin")
  # pyenv builds link libpython by absolute path; let dyld find the clone's copy instead.
  EXTRA="export DYLD_LIBRARY_PATH=\"$TOOLS/python/lib\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}\"; "
fi
# User site-packages (pip install --user, e.g. pytest) resolve from $HOME, so mirror them.
user_site="$(real python3 -m site --user-site)"
if [ -n "$user_site" ] && [ -d "$user_site" ] && under_home "$user_site"; then
  mkdir -p "$(dirname "$HOME/${user_site#"$REAL_HOME"/}")"; clone "$user_site" "$HOME/${user_site#"$REAL_HOME"/}"
fi
# Not fixable here: on macOS /usr/bin/git is an xcrun shim that the sandbox blocks, so git
# does not work inside the run. The agent can still read and edit files.
# Node: the install prefix (bin/node, lib/node_modules).
node_bin="$(command -v node || true)"
if [ -n "$node_bin" ] && under_home "$node_bin"; then clone "$(dirname "$(dirname "$node_bin")")" "$TOOLS/node"; PATHS+=("$TOOLS/node/bin"); fi
# Rust via rustup in your home.
if [ -d "$REAL_HOME/.cargo/bin" ] && under_home "$(command -v cargo || echo none)"; then
  clone "$REAL_HOME/.cargo" "$HOME/.cargo"; [ -d "$REAL_HOME/.rustup" ] && clone "$REAL_HOME/.rustup" "$HOME/.rustup"
  PATHS+=("$HOME/.cargo/bin")
fi

line="${EXTRA}export PATH=\"$(IFS=:; echo "${PATHS[*]:-}")\${PATH:+:\$PATH}\"; export ELAN_HOME=\"\$HOME/.elan\""
for f in .zshenv .zshrc .bashrc .bash_profile .profile; do echo "$line" >> "$HOME/$f"; done
[ -e "$HOME/.cache/proof-skills/tla2tools.jar" ] || {
  echo "missing TLA+ tools: run plugins/proof-skills/skills/tlaplus-model/scripts/setup_tla.sh --with-jre first" >&2; exit 1; }
