---
# yaml-language-server: $schema=../../.lore/schemas/reference.schema.json
type: Reference
title: Lean pattern catalog
summary: "The shipped Lean 4 patterns (Explore, Counter, Idempotency, Queue, Pipeline, Graph, StateMachine, DagScheduler, RedundantGuard, Replay) with headline theorems and the verified trust audit."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.824Z
---

# Lean pattern catalog

Files are in `plugins/proof-skills/skills/lean-model/assets/lean-patterns/`. The agent-facing
guide is `lean-model/references/patterns.md`. Built on Lean 4.34.0 with plausible v4.34.0.
`check_trust.sh` reports 24 theorems, 0 with trust problems (standard axioms only, no
`sorry`, no `native_decide`).

## Details

| File | Models | Counterexample (buggy variant) | Headline theorem (fixed variant) |
|---|---|---|---|
| Explore | Reach, BFS, trace → theorem | — | `Reach.inv`, `validPath_reach` |
| Counter | two-thread increment | `racy_lost_update` (proof term); `racy_bug_bounded` (`decide +kernel`) | `no_lost_update` |
| Idempotency | async dedup across `await`, retries | `bfs` → dispatch, dispatch, resume, resume; `buggy_double_apply` | `applied_nodup` |
| Queue | FIFO channel | — | `recvd_prefix` |
| Pipeline | batching stage | plausible `xs := [0]`; `decide` on `[0]` | `batch_lossless` |
| Graph | topological order certificate | `checkRank` false on a cycle | `acyclic_of_check`, `path_increases` |
| StateMachine | order lifecycle + concurrent cancel | `bfs` → cancelRead, pay, cancelWrite | `transitions_allowed` |
| DagScheduler | dispatch for every dependency function | `bfs` → dispatch 1, dispatch 2 | `deps_respected` |
| RedundantGuard | deleting a defensive check | — | `guard_implied`, `reach_iff` |
| Replay (exe) | differential-testing driver | — | `lake exe replay < trace.jsonl` |

The template (`new_project.sh`) produces `Explore` + `System` + `Properties` with a
`next_sound` bridge, and builds and audits cleanly out of the box.

See also [TLA+ pattern catalog](tla-pattern-catalog.md).
