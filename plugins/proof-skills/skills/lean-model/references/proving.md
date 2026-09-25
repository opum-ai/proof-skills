# Proving: tactics, invariant strengthening, and stuck proofs

## Tactic playbook (Lean 4.34 names)

| Goal shape | Try |
|---|---|
| Invariant preserved by a step | `cases hs <;> grind [Inv, helper defs]`, or case-split actors first: `cases hs with \| a t \| b t => cases t <;> grind [...]` |
| Linear arithmetic on Nat/Int | `omega` |
| Decidable finite fact (small enum, small bounded search) | `decide`; for big terms `decide +kernel` (kernel-only, avoids elaborator limits) |
| Boolean or bit-vector fact | `bv_decide` (SAT with a checked LRAT certificate) |
| Rewriting with definitions | `simp [defs]`, `simp_all [defs]`, `simp only [...]` for control |
| List lemmas | `simp` usually knows them; search with `exact?` or `apply?` |
| `do`-notation programs with loops | `mvcgen` (`import Std.Tactic.Do`) with loop invariants |
| "Is this even true?" | `plausible` (random testing), or `#eval` over `Explore.reachable` |
| Unknown lemma name | `exact?`, `apply?`, `grind?` (prints the lemmas it used) |

`aesop` lives in Batteries/Mathlib, not core. Prefer `grind` in dependency-free projects.

## The invariant-strengthening loop

1. Start with `Inv := Safe`.
2. Try `inv_step`. On failure, read the leftover goal for the failing constructor. It shows
   a state satisfying `Inv` whose successor violates it.
3. Ask whether that state is reachable.
   - **Reachable:** you have found a bug. Confirm with `bfs`, then hand it to `formal-verify`.
   - **Unreachable:** you have found a missing invariant. Name the fact that rules the state
     out (for example, "an awaiting task's key is in `seen`" or "the lock holder's pc is
     locked or read"), add it to `Inv`, and go back to step 2.
4. Check each strengthening with `#eval` over reachable states before proving it. If an
   added conjunct is false on some reachable state, it is wrong, and no proof will go through.

This is the same loop as Apalache's inductive invariants and Veil's CTI workflow. Agents are
good at step 3 when they are given the concrete leftover goal.

## Stuck-proof strategies

- **Case-split before automation.** `grind` and `simp_all` struggle when hypotheses are
  buried in `∧` or `∀`. Use `obtain ⟨h1, h2⟩ := h`, split actors (`cases t`) and program
  counters, then call automation.
- **Generalize the accumulator.** For `foldl` or recursion, state a lemma over arbitrary
  accumulators (`Pipeline.foldl_step`), then specialize it.
- **Induct on the right thing.** Use `Reach` (steps) for safety, the list for pure functions,
  and `Relation.TransGen` for graph paths.
- **Shrink the model.** Prove it for 2 actors with `Bool` identifiers first, then generalize
  to `Fin n` or `Nat`.
- **Bounded first.** When the unbounded proof is expensive, ship a bounded theorem
  (`decide +kernel` over `reachable … k`) marked "bounded, depth k" in the report, and keep
  working on the general proof.
- **Keep a `sorry` ledger.** It is fine to `sorry` sub-lemmas while exploring the proof's
  structure. Never report a theorem as proven while `check_trust.sh` shows `sorryAx` in it.
  List the remaining `sorry`s in the report.

## AI provers (optional)

- **lean-lsp-mcp** (`claude mcp add lean-lsp uvx lean-lsp-mcp`) gives an agent goal states,
  diagnostics, multi-tactic attempts, and search (loogle, leansearch). This is the biggest
  productivity gain for agent proof work. Run `lake build` before starting it.
- **Aristotle** (Harmonic): `pip install aristotlelib`, then fills `sorry`s in a project.
  It is a hosted service, so the code leaves the machine. Ask before using it on private code.
- **Open provers** (Goedel-Prover-V2, Kimina, DeepSeek-Prover-V2) are tuned for mathematics
  and weaker on software lemmas.
