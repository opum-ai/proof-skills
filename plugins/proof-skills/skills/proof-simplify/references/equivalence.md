# Showing a simplification is safe

Techniques in increasing strength. Use the strongest that is affordable, and say in the
report which one you used.

| Technique | Proves | Preserves | Cost |
|---|---|---|---|
| Re-check | the simplified model satisfies the frozen properties at the checked bounds | exactly the checked properties | minutes |
| Guard implication | a removed guard was always true where it mattered | everything (combined with reachable-state equivalence) | a lemma |
| Refinement (simplified ⊑ current) | every simplified behavior is a current behavior | all safety properties of the current model | a mapping, plus TLC or a simulation proof |
| Reachable-state equivalence | both versions reach exactly the same states | all state invariants of either | an induction proof |
| Function equality | same output for every input | everything observable through the function | a proof |

## Re-check (TLA+ or Lean)

Re-run every config (safety, liveness, sanity, and bug toggles) on the simplified model. The
bug toggles matter here: they show the properties still have teeth after the change.

## Refinement in TLA+

The simplified spec instantiates the current spec with a **refinement mapping** that
reconstructs any variable the simplification removed. The mapping is then checked as a
property:

```tla
Current == INSTANCE CancelOrder WITH
             UseLock <- TRUE, UseCAS <- TRUE,
             lock <- (IF cpc = "decide" THEN "cancel" ELSE "free")
RefinesCurrent == Current!Spec
\* MC_refines.cfg:  SPECIFICATION Spec   PROPERTIES RefinesCurrent ValidTransitions
```

Variables with the same names are substituted implicitly. Verified in
`../assets/tla/CancelOrderSimple.tla`: it passes, and removing the CAS guard from the
simplified spec makes it fail.

Notes:
- A simplified step may correspond to a *stuttering* step of the current spec (a variable
  that no longer changes). `[][Next]_vars` allows this.
- One simplified step corresponding to *several* current steps (merging actions) does not
  fit a plain refinement. Re-check the properties directly instead, or add an auxiliary
  variable.
- Refinement preserves safety only. Re-check liveness on the simplified spec with its own
  fairness.

## Refinement or simulation in Lean

```lean
-- abs maps simplified states to current states
theorem init_ok : abs init' = init := ...
theorem sim : Step' s t → Step (abs s) (abs t) ∨ abs s = abs t := ...
-- Every property proven via Reach Step transfers:
theorem reach_abs : Reach Step' init' s → Reach Step init (abs s) := ...
theorem safe' (h : Reach Step' init' s) : Safe (abs s) := safe_of_reach (reach_abs h)
```

## Reachable-state equivalence in Lean

This is the pattern of `lean-model/assets/lean-patterns/ProofPatterns/RedundantGuard.lean`:
1. `defensive_sub`: every step of the guarded (current) relation is a step of the simplified one.
2. `guard_implied`: the invariant (proven for the simplified relation) implies the guard.
3. `reach_iff` has two directions:
   - (→) follows from `defensive_sub`;
   - (←) is induction on `Reach`, using `guard_implied` to supply the guard at each step.

## Function equality in Lean

```lean
theorem simple_eq : ∀ xs, simple xs = current xs := by
  intro xs; induction xs <;> simp_all [simple, current]
-- First check the claim is true:  example : ∀ xs : List Nat, simple xs = current xs := by plausible
```
When a direct induction fails, generalize the accumulator (`Pipeline.foldl_step`), or prove
both functions equal to a common specification.
