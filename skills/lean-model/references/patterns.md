# Lean pattern catalog

All files are in `../assets/lean-patterns/ProofPatterns/`. The project builds with
`lake build` on Lean 4.34.0 + plausible v4.34.0. `check_trust.sh` reports 24 theorems,
0 `sorry`, standard axioms only.

To reuse a pattern, copy the file into your project (from `new_project.sh`), rename the
namespace, and replace the state and steps with your code's.

## Explore.lean: shared machinery
- `Reach step init s` is reachability.
- `Reach.inv Inv h0 hstep` is safety by induction.
- `StepOf next` is the relation induced by an executable successor function.
- `validPath next s path = true` together with `validPath_reach` gives reachability of the path's
  last state. `decide` computes `validPath`, so a counterexample becomes a theorem.
- `bfs next bad init` returns the shortest labeled path to a bad state. `reachable next init`
  returns every reachable state within the fuel bound.

## Counter.lean: interleavings and the lost update
**Shape:** two threads, each with a `pc` and a local register. `RacyStep` has `read` and `write`
constructors, parameterized by thread.
**Bug:** `racy_lost_update` gives an explicit 4-step proof term reaching `x = 1` with both threads done.
**Fix:** `Step` with acquire, read, and write-and-release.
**Proof:** `Inv` states:
- lock ownership matches the holding threads,
- a thread's register is fresh while it holds the lock, and
- `x` equals the number of finished threads.

Then `cases hs … <;> cases t <;> grind [...]`.
**Non-vacuity:** an explicit 6-step path to "both done".
**Bounded version:** `decide +kernel` over `reachK`, relying only on `propext`.

## Idempotency.lean: async check-then-act, retries
**Shape:** inbox (with duplicates), a `seen` set, an `applied` log, and a list of tasks, each
`awaiting k` or `fin`. The event loop dispatches, and tasks resume in any order.
**Bug:** checking `seen` before the await and marking it after. `bfs` finds
`dispatch, dispatch, resume, resume`, and `buggy_double_apply` is that trace as a theorem.
**Fix:** claim `seen` synchronously when dispatching.
**Proof:** `Inv` includes "an awaiting task's key is already in `seen`". This is the
strengthening that `grind` needs; without it, the `dispatch` case fails and prints the
counterexample to induction.
**Adapt:** use the same shape for webhook handlers, message consumers, request dedup, and
"create if not exists".

## Queue.lean: channels
`Inv: recvd ++ chan = sent` gives no loss, reordering, or duplication, and `recvd_prefix` follows.
**Extend:**
- a `drop` constructor, after which the invariant becomes `recvd <+ sent` (sublist);
- a `dup` constructor, after which the consumer must be idempotent (combine with Idempotency);
- several consumers, each with its own program counter.

## Pipeline.lean: dataflow transformations
**Bug:** `batchBuggy` loses the trailing partial batch. `plausible` finds it (the example is
commented out so the build stays green), and `decide` confirms it on `[0]`.
**Proof technique:** generalize the fold with an accumulator lemma (`foldl_step`), then
specialize it. When induction on the stated goal fails, generalizing the accumulator is
nearly always the fix.
**Adapt:** use this for any `fold`/`reduce`, windowing, chunking, dedup-by-key, merge, or join
stage. The standard properties are "flatten equals the input", "a permutation of the input",
and "a sublist of the input".

## Graph.lean: certificate checking
Rather than proving a production algorithm correct, prove a tiny checker correct:
`checkRank g rank = true` implies acyclicity and that every path increases in rank. Run the
checker on production output (in tests, or even at runtime). The same idea works for:
- a claimed shortest path (check the triangle inequality on every edge),
- a claimed matching,
- a claimed spanning tree, and
- a claimed schedule.

`reachable` gives executable reachability with fuel.

## StateMachine.lean: lifecycles
- `allowed` is the transition table. Facts about the table are checked by `decide` over
  `Status.all`.
- `last` records the last status change, so the action property "every change is an allowed
  edge" becomes a state invariant.
- **Bug:** a read, decide, then write cancel, found by `bfs` as `cancelRead, pay, cancelWrite`.
- **Fix:** a compare-and-set guard (`s.status = .pending` at write time).
- `transitions_allowed` holds for every reachable state.

## DagScheduler.lean: every graph
- `preds : Nat → List Nat` is an arbitrary dependency function; no acyclicity is needed for
  this safety property.
- `deps_respected`: every running task's predecessors are done, for every graph, every task
  count, and every interleaving.
- The buggy readiness rule (predecessors *started*) is refuted on the graph 1 → 2.
- Liveness (every task eventually runs, which needs acyclicity and fairness) stays in TLA+
  (`DagScheduler.tla`).

## RedundantGuard.lean: deleting code with a proof (used by proof-simplify)
The current handler re-checks `k ∉ applied` before the side effect.
- `guard_implied`: the invariant already implies that check in every reachable state.
- `reach_iff`: the defensive and simplified handlers reach exactly the same states.

Together these justify deleting the check. The recipe: prove the guard follows from the
invariant, then prove equality of the reachable-state sets.

## Replay.lean: differential-testing driver
`lake exe replay < trace.jsonl` reads events and prints the model's outputs. See differential-testing.md.
