# Choosing the tool

Pick based on what can go wrong and what kind of evidence the user needs.

| Bug class / need | First choice | Why |
|---|---|---|
| Races, lost updates, check-then-act, TOCTOU | TLA+ (TLC) | Exhaustive interleavings at small bounds; shortest counterexample via BFS |
| Deadlock, lock ordering, starvation | TLA+ (TLC) | Deadlock detection is built in; liveness with explicit fairness |
| Message loss/duplication/reordering, retries, idempotency | TLA+ (TLC) | Network nondeterminism is natural to model |
| Distributed protocol (leases, leader election, 2PC, replication) | TLA+; Apalache for inductive invariants | Industry-standard practice (AWS, Azure, MongoDB, Datadog) |
| Liveness ("eventually drains", "no request waits forever") | TLA+ (TLC) | Apalache/Quint temporal support is limited |
| Big integer/data domains, long bounded traces | Apalache or Quint `verify` | SMT handles large domains that TLC must enumerate |
| Team reads pseudocode, not math | PlusCal or Quint | Same checkers, more familiar syntax |
| Pure function / algorithm correctness (parser, merge, diff, scheduler ordering) | Lean 4 | Theorems over all inputs; `decide` on small instances |
| Graph properties (reachability, acyclicity, topological order) for *all* graphs | Lean 4 | Induction over graphs; TLA+ can brute-force every graph ≤ 4 nodes first |
| State machine with a finite transition table | Either — TLA+ for concurrency, Lean for exhaustive `decide` over the table | |
| "Holds for every N", certified result | Lean 4 (after TLA+ at small N) | TLC is bounded; Lean proofs are not |
| Reference implementation for differential testing | Lean 4 (`#eval`, compiled model) | Executable spec; compare outputs with the real code |
| Unbounded safety of a protocol | Apalache inductive invariant, or Lean | Induction: `Init ⇒ Inv` and `Inv ∧ Next ⇒ Inv'` |

## Combining them

The strongest pattern splits by concern: **TLA+ for the protocol, Lean for the algorithm inside it.**
Model the algorithm as one atomic action in TLA+ (for example, `Schedule == ready' = TopoReady(dag, done)`),
and prove that operator's correctness in Lean. The TLA+ checks catch interleaving bugs
around the algorithm; the Lean proof covers the algorithm itself for all inputs.

## When formal methods are the wrong tool

Say so rather than forcing a model:
- The bug class is performance, resource leaks, or UI behavior → profiling, load tests.
- The logic is simple and sequential → property-based testing (Hypothesis, fast-check,
  proptest, QuickCheck) is cheaper and runs on real code.
- The system is deterministic and simulatable → deterministic simulation testing (DST,
  FoundationDB/TigerBeetle style) exercises real code; a spec can still guide it.
- The concern is one race in one function and a stress test with a barrier reproduces it
  in 20 lines → write the test first; model only if the fix is subtle.

A model is worth it when interleavings or input space are too large for a human to
enumerate, the cost of a bug is high, or the fix needs to be *proven* rather than *tested*.

## Bounds cheat sheet (TLC)

Start tiny, then grow one dimension at a time:
- Processes/workers: 2, then 3. Many real races need only 2.
- Values/keys: 2. Jobs/messages: 2–3. Retries/crashes: 0 → 1 → 2.
- Queue/channel capacity: 1–2 (capacity 1 often shows backpressure bugs).
- Graph nodes: 3 exhaustively (512 graphs), 4 if fast (65,536 graphs).
The published evidence (Specula, 2026): median counterexample 9 steps, p90 18. Deep
traces are rare, so small bounds find most bugs.
