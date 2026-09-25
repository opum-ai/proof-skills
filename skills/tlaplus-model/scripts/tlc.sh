#!/usr/bin/env bash
# Parse (SANY) then model-check (TLC) a spec, save the log and trace, summarize the result.
#
#   tlc.sh Spec.tla [--config MC.cfg] [--out DIR] [--sany-only] [--pcal] [-- extra TLC args]
#
#   --config F   TLC config (default: <Spec>.cfg next to the spec)
#   --out DIR    where tlc.log, cex.json, trace.md go (default: <spec dir>/.tlc-out/<cfg name>)
#   --sany-only  parse and level-check only (fast inner loop while writing)
#   --pcal       translate PlusCal first (pcal.trans -nocfg)
#   after --     passed to TLC verbatim, e.g. -- -simulate num=100000 -depth 60
#
# Exit code is TLC's: 0 ok, 10 assumption/postcondition false, 11 deadlock, 12 invariant,
# 13 temporal or action property, 14 assert/eval error, 150 parse/semantic error.
# 2 = usage/tooling error.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${PROOF_SKILLS_TOOLS:-$HOME/.cache/proof-skills}"

SPEC=""; CFG=""; OUT=""; SANY_ONLY=0; PCAL=0; EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CFG="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --sany-only) SANY_ONLY=1 ;;
    --pcal) PCAL=1 ;;
    --) shift; EXTRA=("$@"); break ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) SPEC="$1" ;;
  esac
  shift
done
[ -n "$SPEC" ] && [ -f "$SPEC" ] || { echo "usage: tlc.sh Spec.tla [--config MC.cfg] ..." >&2; exit 2; }

JAVA="$(command -v java 2>/dev/null || true)"
if ! "${JAVA:-false}" -version >/dev/null 2>&1; then
  JAVA="$(find "$TOOLS/jre" -type f -path '*/bin/java' 2>/dev/null | head -1)"
fi
[ -x "${JAVA:-}" ] || { echo "no Java found; run $HERE/setup_tla.sh --with-jre" >&2; exit 2; }
JAR="${TLA2TOOLS:-$TOOLS/tla2tools.jar}"
[ -f "$JAR" ] || { echo "tla2tools.jar not found at $JAR; run $HERE/setup_tla.sh" >&2; exit 2; }
CP="$JAR"; [ -f "$TOOLS/CommunityModules-deps.jar" ] && CP="$CP:$TOOLS/CommunityModules-deps.jar"

SPEC_DIR="$(cd "$(dirname "$SPEC")" && pwd)"; SPEC_FILE="$(basename "$SPEC")"; MOD="${SPEC_FILE%.tla}"
cd "$SPEC_DIR"

if [ "$PCAL" = 1 ]; then
  "$JAVA" -cp "$CP" pcal.trans -nocfg "$SPEC_FILE" || exit 150
fi

"$JAVA" -cp "$CP" tla2sany.SANY "$SPEC_FILE" > .sany.log 2>&1
if [ $? -ne 0 ]; then
  grep -v '^Parsing file\|^Semantic processing' .sany.log; rm -f .sany.log
  echo "RESULT: parse/semantic error (SANY)"; exit 150
fi
rm -f .sany.log
if [ "$SANY_ONLY" = 1 ]; then echo "RESULT: SANY ok"; exit 0; fi

CFG="${CFG:-$MOD.cfg}"
[ -f "$CFG" ] || { echo "config not found: $CFG" >&2; exit 2; }
CFG_NAME="$(basename "$CFG" .cfg)"
OUT="${OUT:-$SPEC_DIR/.tlc-out/$CFG_NAME}"; mkdir -p "$OUT"
rm -f "$OUT/cex.json" "$OUT/trace.md"

"$JAVA" -XX:+UseParallelGC -cp "$CP" tlc2.TLC -workers auto -config "$CFG" \
  -metadir "$OUT/states" -dumpTrace json "$OUT/cex.json" ${EXTRA[@]+"${EXTRA[@]}"} "$SPEC_FILE" > "$OUT/tlc.log" 2>&1
RC=$?
rm -rf "$OUT/states"
rm -f "${MOD}"_TTrace_* 2>/dev/null   # trace-explorer .tla/.bin files TLC leaves behind

case $RC in
  0) MSG="no violation" ;; 10) MSG="ASSUME or POSTCONDITION false (trace rejected?)" ;; 11) MSG="deadlock" ;;
  12) MSG="invariant violated" ;; 13) MSG="temporal/action property violated" ;;
  14) MSG="evaluation/assert error" ;; 150|151|152|153) MSG="parse/config error" ;; *) MSG="TLC error (see log)" ;;
esac
grep -E '^Error:|violated|states generated|depth of the complete|Finished in|Warning:' "$OUT/tlc.log" | grep -v '^Error: The behavior up to' | head -20
echo "RESULT: exit $RC — $MSG"
echo "LOG:    $OUT/tlc.log"
if [ -s "$OUT/cex.json" ] || grep -q '^State 1:' "$OUT/tlc.log"; then
  SRC="$OUT/cex.json"; [ -s "$SRC" ] || SRC="$OUT/tlc.log"
  python3 "$HERE/parse_tlc_trace.py" "$SRC" --spec "$SPEC_DIR/$SPEC_FILE" > "$OUT/trace.md" 2>/dev/null \
    && echo "TRACE:  $OUT/trace.md" && cat "$OUT/trace.md"
fi
exit $RC
