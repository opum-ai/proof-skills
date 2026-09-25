#!/usr/bin/env bash
# Audit a Lake project's trust base: build it, then list every theorem under a namespace
# prefix with the axioms it depends on. Fails on sorry, on non-standard axioms, and
# (unless --allow-native) on native_decide.
#
#   check_trust.sh [PROJECT_DIR] [--module Root] [--prefix Ns] [--allow-native] [--json]
#
#   --module  root module to import (default: first [[lean_lib]] name in lakefile.toml)
#   --prefix  namespace prefix of theorems to audit (default: same as --module)
#   --json    print {theorem: [axioms]} as JSON (for formal/findings.json trust_base.lean.axioms)
#
# Standard axioms (accepted): propext, Classical.choice, Quot.sound.
# Exit: 0 clean, 1 trust problem found, 2 build/usage error.
set -uo pipefail
DIR="."; MOD=""; PREFIX=""; ALLOW_NATIVE=0; JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --module) MOD="$2"; shift ;;
    --prefix) PREFIX="$2"; shift ;;
    --allow-native) ALLOW_NATIVE=1 ;;
    --json) JSON=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) DIR="$1" ;;
  esac
  shift
done
cd "$DIR" || exit 2
if [ -z "$MOD" ]; then
  MOD=$(awk '/^\[\[lean_lib\]\]/{f=1;next} f&&/^name *=/{gsub(/.*= *"|".*/,"");print;exit}' lakefile.toml 2>/dev/null)
fi
[ -n "$MOD" ] || { echo "cannot determine root module; pass --module" >&2; exit 2; }
PREFIX="${PREFIX:-$MOD}"

PROBLEMS=0
# 1. Source scan: things that weaken or bypass the kernel.
SRC=$(find . -name '*.lean' -not -path './.lake/*' 2>/dev/null)
scan() { # pattern label
  local hits; hits=$(grep -nE "$1" $SRC 2>/dev/null | grep -vE '^\S+:[0-9]+:\s*--' || true)
  if [ -n "$hits" ]; then echo "$2:"; echo "$hits" | sed 's/^/  /'; return 0; fi; return 1
}
[ "$JSON" = 1 ] || echo "== source scan"
if scan '(^|[^A-Za-z_])(sorry|admit)([^A-Za-z_]|$)' "sorry/admit" >&2; then PROBLEMS=1; fi
if scan '^\s*axiom\s' "user axioms" >&2; then PROBLEMS=1; fi
scan '@\[implemented_by|^\s*unsafe\s|@\[extern' "implemented_by/unsafe/extern (review: runtime code not checked by kernel)" >&2 || true
if scan 'native_decide' "native_decide (trusts the compiler)" >&2 && [ "$ALLOW_NATIVE" = 0 ]; then PROBLEMS=1; fi

# 2. Build.
[ "$JSON" = 1 ] || echo "== lake build"
if ! lake build >/tmp/check_trust_build.$$ 2>&1; then
  grep -E 'error' /tmp/check_trust_build.$$ | head -20 >&2; rm -f /tmp/check_trust_build.$$
  echo "build failed" >&2; exit 2
fi
rm -f /tmp/check_trust_build.$$

# 3. Axiom audit over the compiled environment.
AUDIT=$(mktemp -t audit.XXXXXX).lean
cat > "$AUDIT" <<EOF
import Lean
import $MOD
open Lean Elab Command in
#eval show CommandElabM Unit from do
  let env ← getEnv
  let pre := "$PREFIX".toName
  let mut rows : Array String := #[]
  for (n, ci) in env.constants.toList do
    if pre.isPrefixOf n && !n.isInternal then
      if let .thmInfo _ := ci then
        let axs ← liftCoreM <| Lean.collectAxioms n
        rows := rows.push s!"{n}\t{",".intercalate (axs.toList.map toString)}"
  for r in rows.qsort (· < ·) do IO.println r
EOF
OUT=$(lake env lean "$AUDIT" 2>&1); RC=$?; rm -f "$AUDIT"
[ $RC -eq 0 ] || { echo "$OUT" >&2; echo "axiom audit failed" >&2; exit 2; }

STD="propext Classical.choice Quot.sound"
TOTAL=0; BAD=0; JSON_ROWS=""
while IFS=$'\t' read -r thm axs; do
  [ -n "$thm" ] || continue
  case "${thm##*.}" in   # skip compiler-generated lemmas (equations, injectivity, sizeOf)
    eq_[0-9]*|eq_def|sizeOf_spec|inj|injEq|brecOn|ofNat_ctorIdx|ctorIdx|congr_simp) continue ;;
  esac
  TOTAL=$((TOTAL+1)); flag=""
  for a in ${axs//,/ }; do
    case " $STD " in *" $a "*) ;; *)
      if [ "$a" = sorryAx ]; then flag="SORRY"
      elif [[ "$a" == *native_decide* ]]; then [ "$ALLOW_NATIVE" = 1 ] || flag="${flag:-NATIVE}"
      else flag="${flag:-AXIOM:$a}"; fi ;;
    esac
  done
  [ -n "$flag" ] && BAD=$((BAD+1))
  if [ "$JSON" = 1 ]; then
    list=$(printf '%s' "$axs" | awk -F, '{for(i=1;i<=NF;i++) if($i!="") printf "%s\"%s\"", (i>1?",":""), $i}')
    JSON_ROWS="$JSON_ROWS${JSON_ROWS:+,}\"$thm\":[$list]"
  else
    printf '  %-6s %s  [%s]\n' "${flag:-ok}" "$thm" "$axs"
  fi
done <<< "$OUT"

if [ "$JSON" = 1 ]; then echo "{${JSON_ROWS}}"
else echo "== $TOTAL theorems under $PREFIX, $BAD with trust problems"; fi
[ $BAD -gt 0 ] && PROBLEMS=1
exit $PROBLEMS
