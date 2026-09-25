---
name: lean-model
description: "Use this skill to prove or refute properties of real software in Lean 4. The target is the user's own code, not textbook math. It covers state machines, concurrency and interleavings, async handlers, retries and idempotency, queues, batching pipelines, and graph algorithms such as topological order, acyclicity and DAG scheduling. Trigger it when the user wants a guarantee for every input or size (\"holds for all N\"), beyond what TLC, tests or a model checker showed. Also trigger it for invariant proofs by induction, a concrete counterexample trace, an executable reference model for differential testing, or setting up a Lean/lake project to model code. Also use it to audit a Lean development's trust base: sorry, axioms, native_decide. Do NOT use it for pure mathematics such as analysis, algebra or Mathlib coursework and homework. Do NOT use it to translate code into Lean syntax, or for other provers like Dafny, Coq or Isabelle. Pairs with formal-verify for bug hunts and tlaplus-model for protocol exploration."
---

# lean-model

Lean gives three things at once, all from one language:
- an **executable model** that runs as a bounded model checker and a differential-testing oracle,
- **theorems** that cover every input, size, and interleaving, and
- a **kernel** that checks the proofs, so the only thing to trust is the statements.

Agents are now good at the proof engineering. The human-level decisions are what to model
and which statements to believe. This skill is organized around those decisions.

For a full bug hunt (scoping, the correspondence map, reproduction in real code, the fix, and
the Artifact report), follow `formal-verify` and use this skill for the model.

## Setup

```bash
S=${CLAUDE_SKILL_DIR}/scripts
$S/setup_lean.sh                               # elan (no sudo); projects pin their own toolchain
$S/new_project.sh formal/<concern>/lean JobLease   # template: Explore + System + Properties
cd formal/<concern>/lean && lake build
$S/check_trust.sh .                            # sorry/axiom/native_decide audit; --json for findings
```

The template has no Mathlib, only core Lean plus optional `plausible`. Software models rarely
need Mathlib: core has `List`, `Array`, `Std.HashMap`, `omega`, `grind`, `decide`,
`bv_decide`, `simp`, and `Relation.TransGen`. Mathlib adds about 8 GB of build cache.
See `references/setup.md`. `lake env lean F.lean` does **not** build dependencies, so run
`lake build` first.

## The loop: model, then refute, then prove

1. **State and steps.** Write the component's state as a `structure S` deriving `DecidableEq`
   and `Repr`. Keep only what the properties read. Write the steps as an `inductive Step : S → S → Prop`:
   - one constructor per atomic region of the code (between `await`s, a locked section,
     one SQL statement, one handler);
   - a per-actor program counter wherever the code can yield;
   - retries, duplicates, and crashes as their own constructors.

   Tag each constructor's docstring `src: path:lines`.
2. **Executable twin.** Write `next : S → List (String × S)` with action labels, and prove
   `next_sound` (every executable move is a `Step`) so the twins cannot drift apart. The
   template includes this.
3. **Refute first. It is cheaper than proving.**
   - `#eval Explore.bfs next bad init` returns the shortest labeled trace to a bad state.
   - `Explore.validPath_reach … (by decide)` turns that trace into a kernel-checked theorem
     that the bug is reachable.
   - `decide +kernel` runs exhaustive bounded checks and trusts only `propext`.
   - `plausible` does property-based testing of pure functions.

   Most bugs appear here, in seconds. Hand real ones to `formal-verify` for reproduction.
4. **State the property and freeze it** in `Properties.lean`, citing its source. Also write a
   **non-vacuity witness**: a path, checked by `decide`, to a state where the interesting
   thing happens. A safety theorem over a model where nothing can happen is worthless.
5. **Prove by an inductive invariant.**
   - Prove `inv_init`, then `inv_step` (`cases hs <;> grind [Inv, …]`), then lift the result
     with `Explore.Reach.inv`.
   - When `grind` or `simp_all` fails on one constructor, the leftover goal is a
     counterexample to induction: a state that satisfies `Inv` but is unreachable, whose
     successor breaks `Inv`. Add the missing fact to `Inv` and repeat. This loop is the heart
     of the method, and the missing fact is often a real edge case worth checking in the code.
   - Details and stuck-proof tactics: `references/proving.md`.
6. **Audit trust.**
   - `check_trust.sh` must report 0 problems for any theorem called "proven".
   - Standard axioms (`propext`, `Classical.choice`, `Quot.sound`) are fine.
   - `sorryAx` is not a proof.
   - `native_decide` trusts the compiler: allow it only with `--allow-native`, and disclose it.
7. **Connect to the code.** Mirror fixes in the model and re-prove. Use `lake exe replay`
   (the differential-testing driver in `assets/lean-patterns/Replay.lean`) to compare model
   outputs with production traces (`references/differential-testing.md`).

## Patterns: all compile on Lean 4.34.0, with 0 sorry

`assets/lean-patterns/ProofPatterns/`, one file per pattern. `references/patterns.md`
explains each one.

| File | Shows | Headline results |
|---|---|---|
| `Explore.lean` | Reach, invariant induction, BFS with traces, trace → theorem | `Reach.inv`, `validPath_reach` |
| `Counter.lean` | lost update vs. mutex; interleavings as a step relation | `racy_lost_update` (bug as proof term), `no_lost_update` |
| `Idempotency.lean` | async check-then-act across `await`; retries | `buggy_double_apply`, `applied_nodup` |
| `Queue.lean` | FIFO: no loss, reordering, or duplication | `recvd_prefix` |
| `Pipeline.lean` | batching stage drops its tail; generalized fold lemma | `batch_lossless` |
| `Graph.lean` | acyclicity and topological order by certificate checking | `acyclic_of_check` |
| `StateMachine.lean` | transition table + read-decide-write race; CAS fix | `transitions_allowed` |
| `DagScheduler.lean` | dependency-respecting dispatch for every graph | `deps_respected` |
| `RedundantGuard.lean` | proving a defensive check is dead, then deleting it | `guard_implied`, `reach_iff` |

## When to use Lean vs. TLA+

Use Lean for:
- algorithmic cores,
- data transformations,
- graph properties for *all* graphs,
- unbounded "for every N" safety,
- certificate checkers, and
- executable reference models.

Use TLA+ for:
- quick exhaustive interleaving search,
- liveness and fairness (Lean has no mature temporal-logic library), and
- protocol exploration.

Combined: TLA+ finds the trace fast; Lean proves the fixed invariant for every size. Keep TLC
traces as `decide` regression examples in Lean. See `formal-verify/references/choosing-tools.md`.

## Rules that keep proofs honest

- The model is the claim. Review theorem *statements* as carefully as code, and never edit
  a frozen statement to make a proof go through. Report it instead.
- Do not make read-modify-write atomic in the model unless the code makes it atomic. That
  single abstraction hides most concurrency bugs.
- `partial def` cannot be unfolded in proofs. Use fuel (as `Explore.bfs` does) or
  well-founded recursion for anything you reason about.
- A name like `id` can silently resolve to a builtin. Inside `match`/`∀`, write `PC.awaiting`
  rather than `.awaiting` when the expected type is unknown.
- Destructure invariant conjunctions (`obtain ⟨h1, h2, h3⟩ := h`) and case-split on actor
  and program counter before calling `grind` or `simp_all`.

## Reference files

- `references/patterns.md` — each pattern: the code shape, the bug, the proof strategy, and how to adapt it.
- `references/proving.md` — the tactic playbook, the invariant-strengthening loop, stuck-proof strategies, AI provers.
- `references/pitfalls.md` — vacuity, trust base, drift, over-abstraction, spec gaming.
- `references/differential-testing.md` — executable models against production: replay, random inputs, CI.
- `references/setup.md` — elan, lake, toolchain pinning, Mathlib trade-offs, lean-lsp-mcp for agents.
