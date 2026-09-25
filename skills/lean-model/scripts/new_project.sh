#!/usr/bin/env bash
# Scaffold a Lean 4 model project from the skill's template.
#
#   new_project.sh DIR PkgName [--no-plausible]
#
# Creates DIR/{lakefile.toml, lean-toolchain, PkgName.lean, PkgName/{Explore,System,Properties}.lean}.
# PkgName must be UpperCamelCase (it becomes the Lean namespace). Then: cd DIR && lake build
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$HERE/../assets/template"
DIR="${1:?usage: new_project.sh DIR PkgName}"; PKG="${2:?usage: new_project.sh DIR PkgName}"
[[ "$PKG" =~ ^[A-Z][A-Za-z0-9]*$ ]] || { echo "PkgName must be UpperCamelCase" >&2; exit 2; }
[ -e "$DIR/lakefile.toml" ] && { echo "$DIR already has a lakefile.toml" >&2; exit 2; }
lower="$(echo "$PKG" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$DIR/$PKG"
for f in lakefile.toml lean-toolchain __PKG__.lean __PKG__/Explore.lean __PKG__/System.lean __PKG__/Properties.lean; do
  out="$DIR/${f//__PKG__/$PKG}"
  sed -e "s/__PKG__/$PKG/g" -e "s/__pkg__/$lower/g" "$T/$f" > "$out"
done
if [ "${3:-}" = "--no-plausible" ]; then
  awk '/^# Property-based testing/{skip=1} !skip' "$DIR/lakefile.toml" > "$DIR/lakefile.toml.tmp" && mv "$DIR/lakefile.toml.tmp" "$DIR/lakefile.toml"
fi
printf '.lake/\n' > "$DIR/.gitignore"
echo "Created $DIR ($PKG). Next: cd $DIR && lake build"
