---
# yaml-language-server: $schema=../../.lore/schemas/reference.schema.json
type: Reference
title: TLA+ pattern catalog
summary: "The seven shipped TLA+ patterns plus the trace-validation and proof-simplify models, with the bug each finds, the fix toggle, and the verified TLC results."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.736Z
---

# TLA+ pattern catalog

Files are in `skills/tlaplus-model/assets/patterns/<Name>/`. The
agent-facing guide is `tlaplus-model/references/patterns.md`. Results were re-verified with
`scripts/verify-assets.sh` on TLC 2026.09 (tla2tools v1.8.0 release jar).

## Details

| Pattern | Bug class | Fix toggle | MC.cfg | MC_bug.cfg | MC_sanity.cfg |
|---|---|---|---|---|---|
| LostUpdate | read-modify-write, check-then-act, locks | `UseLock` | 0 (13 states, + liveness) | 12 NoLostUpdate | 12 |
| CacheAside | async fill vs. invalidate, stale cache | `UseLease` | 0 (85 states) | 12 NoStaleAtRest | 12 |
| IdempotentRetry | at-least-once delivery, dedup after side effect | `ClaimFirst` | 0 (+ liveness) | 12 AtMostOnce | 12 |
| JobLease | lease expiry, stale holder, fencing | `UseFencing` | 0 (+ liveness) | 12 SingleCommit | 12 |
| BatchPipeline | end-of-stream tail loss, backpressure | `FlushOnEos` | 0 (+ liveness) | **13** AllDelivered | 12 |
| DagScheduler | dispatch before dependencies finish; all 25 DAGs on 3 nodes | `ReadyWhenDone` | 0 (+ liveness) | 12 DepsRespected | 12 |
| OrderStateMachine | illegal transitions from read-decide-write | `UseCAS` | 0 | **13** ValidTransitions (action property) | 12 |

Extra models:

| Model | Purpose | Result |
|---|---|---|
| `CacheAside/TraceCacheAside.tla` | trace validation (ndjson replay) | trace-ok: 0; trace-drift: 10 (postcondition false) |
| `proof-simplify/assets/tla/CancelOrder.tla` | lock + CAS in the current code | current 0; CAS-only 0; lock-only 13 |
| `proof-simplify/assets/tla/CancelOrderSimple.tla` | lock removed; refinement of the current code | 0 (RefinesCurrent + ValidTransitions); a mutation without CAS gives 13 |

Two lessons from building these:
1. The BatchPipeline bug breaks no safety property. Only liveness catches it.
2. TLC reports action-property violations as exit 13, alongside liveness.

See also [Lean pattern catalog](lean-pattern-catalog.md) and
[ADR 0003](../adr/0003-three-config-sanity-pattern-for-every-model.md).
