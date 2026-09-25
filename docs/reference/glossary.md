---
# yaml-language-server: $schema=../../.lore/schemas/reference.schema.json
type: Reference
title: Glossary
summary: "Terms used across the skills and docs — action, invariant, liveness, fairness, refinement, CTI, correspondence map, sanity config, trust base, and more."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.996Z
---

# Glossary

## Details

| Term | Meaning here |
|---|---|
| Action | One atomic step of the model; maps to one atomic region of code (an await-free block, a locked section, one SQL statement, one handler) |
| Action property | A property constraining every step, e.g. `[][status' # status => <<status, status'>> \in Allowed]_vars`; TLC exit 13 when violated |
| Bounds | The constants a check ran at (actors, values, retries, depth). Every "holds" claim states them |
| Bug toggle | A constant (`UseLock`, `ClaimFirst`, …) that turns the fix off; the bug config must fail |
| CAS | Compare-and-set; in SQL, `UPDATE … WHERE col = expected` |
| Correspondence map | `CORRESPONDENCE.md`: model element → `file:line`, the abstraction, and the assumptions |
| CTI | Counterexample to induction: a state satisfying the candidate invariant whose successor breaks it. Either a bug (if reachable) or a missing conjunct (if not) |
| Drift | The code and the model no longer describe the same behavior |
| Fairness | `WF`/`SF` assumptions that an enabled action eventually runs; needed for liveness, and only for what the runtime guarantees |
| Fencing token | A monotonically increasing claim number checked at commit, so stale holders cannot write |
| Frozen property | A property in `Properties.tla`/`Properties.lean` that the agent may not weaken without the user's approval |
| Inductive invariant | `Inv init` and `Inv s ∧ step s s' → Inv s'`; implies `Inv` for all reachable states, with no bound |
| Liveness | "Something good eventually happens" (`<>`, `~>`) |
| Model-based testing | Driving the real code with behaviors generated from the model |
| Non-vacuity witness | A proven path to an interesting state, showing a safety theorem is not trivially true |
| Quiescent | A predicate for "at rest"; coherence properties are often guarded by it |
| Refinement | Every behavior of spec A (under a mapping) is a behavior of spec B; safety properties of B then hold for A |
| Sanity config | `MC_sanity.cfg`: an invariant that must be violated, proving reachability |
| Trace validation | Replaying implementation logs through the spec; a rejected log means drift or a bug |
| Trust base | What a result relies on: TLC version and bounds; Lean toolchain and axioms (`propext`, `Classical.choice`, `Quot.sound` only), with 0 `sorry` |
