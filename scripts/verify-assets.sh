#!/usr/bin/env bash
# Re-verify every model shipped in the plugin: each TLA+ pattern must pass with the fix on
# and fail with the expected exit code with the fix off or in sanity mode; the trace
# validation harness must accept the good log and reject the drifted one; the
# proof-simplify refinement must hold; the Lean patterns must build with a clean trust audit.
#
#   scripts/verify-assets.sh [--tla-only | --lean-only]
#
# Needs: Java 11+ (or PROOF_SKILLS_TOOLS with a portable JRE), tla2tools.jar via setup_tla.sh,
# and elan/lake on PATH for the Lean part.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SK="$ROOT/plugins/proof-skills/skills"
TLC="$SK/tlaplus-model/scripts/tlc.sh"
P="$SK/tlaplus-model/assets/patterns"
MODE="${1:-all}"
FAIL=0; N=0

expect() { # dir module cfg expected_rc [ENV=VAL]
  local dir=$1 mod=$2 cfg=$3 want=$4 envs=${5:-}
  N=$((N+1))
  local got
  (cd "$dir" && env $envs "$TLC" "$mod.tla" --config "$cfg.cfg" --out "$(mktemp -d)" >/dev/null 2>&1); got=$?
  if [ "$got" = "$want" ]; then printf '  ok    %-22s %-14s exit %s\n' "$mod" "$cfg" "$got"
  else printf '  FAIL  %-22s %-14s exit %s (want %s)\n' "$mod" "$cfg" "$got" "$want"; FAIL=1; fi
}

if [ "$MODE" != "--lean-only" ]; then
  echo "== TLA+ patterns"
  for m in LostUpdate CacheAside IdempotentRetry JobLease DagScheduler; do
    expect "$P/$m" "$m" MC 0; expect "$P/$m" "$m" MC_bug 12; expect "$P/$m" "$m" MC_sanity 12
  done
  for m in BatchPipeline OrderStateMachine; do       # bug is liveness / action property
    expect "$P/$m" "$m" MC 0; expect "$P/$m" "$m" MC_bug 13; expect "$P/$m" "$m" MC_sanity 12
  done
  echo "== Trace validation"
  expect "$P/CacheAside" TraceCacheAside Trace 0 TRACE=trace-ok.ndjson
  expect "$P/CacheAside" TraceCacheAside Trace 10 TRACE=trace-drift.ndjson
  echo "== proof-simplify refinement"
  D="$SK/proof-simplify/assets/tla"
  expect "$D" CancelOrder MC_current 0; expect "$D" CancelOrder MC_cas_only 0
  expect "$D" CancelOrder MC_lock_only 13; expect "$D" CancelOrderSimple MC_refines 0
  find "$SK" -name '*_TTrace_*.tla' -delete 2>/dev/null
fi

if [ "$MODE" != "--tla-only" ]; then
  echo "== Lean patterns"
  N=$((N+1))
  if (cd "$SK/lean-model/assets/lean-patterns" && "$SK/lean-model/scripts/check_trust.sh" . | tail -1); then
    echo "  ok    lean-patterns build + trust audit"
  else echo "  FAIL  lean-patterns"; FAIL=1; fi
fi

echo "== $N checks, $([ $FAIL = 0 ] && echo 'all passed' || echo 'FAILURES')"
exit $FAIL
