import ProofPatterns.Explore
import ProofPatterns.Idempotency

/-!
# RedundantGuard: using a proven invariant to delete defensive code

This is the worked example for the `proof-simplify` skill.

The *current* handler (`StepDefensive`) re-checks `k ∉ applied` just before applying the
side effect, as a "belt and braces" guard on top of the claim-first fix. The invariant
proven in `Idempotency` already implies that guard in every reachable state, so:

1. `guard_implied`: the guard is always true when a resume is enabled.
2. `reach_iff`: the defensive and simplified handlers reach **exactly** the same states,
   so every property proven about one holds for the other. Deleting the guard changes nothing.

The recipe generalizes. To delete code guarded by `G` in action `A`, prove
`Reach Step init s → (A enabled at s) → G s`, then prove the reachable-state sets are equal.
-/
namespace ProofPatterns.RedundantGuard
open Explore ProofPatterns.Idempotency

/-- Current code: the resume step also checks `k ∉ applied` (the guard we want to delete).
    src: app/consumer.py:88 (`if k in applied: return  # just in case`) -/
inductive StepDefensive : S → S → Prop
  | dispatch : s.inbox = k :: rest → k ∉ s.seen →
      StepDefensive s { s with inbox := rest, seen := k :: s.seen, tasks := s.tasks ++ [.awaiting k] }
  | dedup : s.inbox = k :: rest → k ∈ s.seen → StepDefensive s { s with inbox := rest }
  | resume : s.tasks[i]? = some (.awaiting k) → k ∉ s.applied →        -- the defensive guard
      StepDefensive s { s with tasks := s.tasks.set i .fin, applied := k :: s.applied }
  | retry (k : Nat) : StepDefensive s { s with inbox := s.inbox ++ [k] }

/-- Every defensive step is a simplified step (drop the extra hypothesis). -/
theorem defensive_sub (h : StepDefensive s t) : Step s t := by
  cases h with
  | dispatch h1 h2 => exact .dispatch h1 h2
  | dedup h1 h2 => exact .dedup h1 h2
  | resume h1 _ => exact .resume h1
  | retry k => exact .retry k

theorem reach_inv (h : Reach Step { inbox := xs } s) : Inv s :=
  Reach.inv Inv inv_init (fun _ _ hi hs => inv_step hi hs) h

/-- The guard is implied by the invariant whenever a resume is enabled. -/
theorem guard_implied {i k : Nat} (h : Reach Step { inbox := xs } s)
    (ht : s.tasks[i]? = some (PC.awaiting k)) : k ∉ s.applied :=
  ((reach_inv h).2.2 i k ht).2.1

/-- Same reachable states, with or without the guard. -/
theorem reach_iff : Reach StepDefensive { inbox := xs } s ↔ Reach Step { inbox := xs } s := by
  constructor
  · intro h
    induction h with
    | refl => exact .refl
    | tail _ hs ih => exact .tail ih (defensive_sub hs)
  · intro h
    induction h with
    | refl => exact .refl
    | @tail s t hr hs ih =>
      refine .tail ih ?_
      cases hs with
      | dispatch h1 h2 => exact .dispatch h1 h2
      | dedup h1 h2 => exact .dedup h1 h2
      | resume h1 => exact .resume h1 (guard_implied hr h1)
      | retry k => exact .retry k

end ProofPatterns.RedundantGuard
