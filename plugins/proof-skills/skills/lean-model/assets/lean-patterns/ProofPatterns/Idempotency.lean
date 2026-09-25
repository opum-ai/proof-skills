import ProofPatterns.Explore

/-!
# Idempotency: at-least-once delivery into an async event loop

Handler code shape (buggy): `if k ∉ seen then (await persist(k); seen.add(k); apply(k))`.
Tasks interleave only at `await`. A retried message can pass the check twice before either
copy marks it as seen.

* `nextBuggy` plus `Explore.bfs` finds the double-apply trace, and `buggy_double_apply`
  turns that trace into a kernel-checked reachability theorem.
* The fix marks `seen` synchronously *before* the await (claim first). `Step` models it and
  `inv_step` proves the invariant for every reachable state. The conjunct `k ∈ s.seen` in
  `Inv` is the strengthening that `grind` needs. Without it the proof fails, and the failure
  is a counterexample to induction.
-/
namespace ProofPatterns.Idempotency
open Explore

inductive PC | ready | awaiting (k : Nat) | fin
  deriving DecidableEq, Repr

structure S where
  inbox   : List Nat := []   -- message ids; retries and duplicates allowed
  seen    : List Nat := []
  applied : List Nat := []   -- log of side effects
  tasks   : List PC  := []   -- spawned handler tasks
  deriving DecidableEq, Repr

/-- Buggy handler: check before the await, mark after it. Labeled successor function. -/
def nextBuggy (s : S) : List (String × S) :=
  (match s.inbox with
   | k :: rest =>
       if k ∈ s.seen then [("dedup", { s with inbox := rest })]
       else [("dispatch", { s with inbox := rest, tasks := s.tasks ++ [.awaiting k] })]
   | [] => []) ++
  (List.range s.tasks.length).filterMap fun i =>
    match s.tasks[i]? with
    | some (PC.awaiting k) =>
        some ("resume", { s with tasks := s.tasks.set i .fin, seen := k :: s.seen,
                                 applied := k :: s.applied })
    | _ => none

def doubleApplied (s : S) : Bool := !s.applied.Nodup

-- Message 7 delivered twice: shortest trace to a double side effect.
#eval (bfs nextBuggy doubleApplied { inbox := [7, 7] }).map (·.map (·.1))
-- some ["dispatch", "dispatch", "resume", "resume"]

/-- The trace as a theorem: a double apply is reachable (checked by the kernel). -/
theorem buggy_double_apply :
    Reach (StepOf nextBuggy) { inbox := [7, 7] }
      (lastState { inbox := [7, 7] }
        [("dispatch", { inbox := [7], tasks := [.awaiting 7] }),
         ("dispatch", { inbox := [], tasks := [.awaiting 7, .awaiting 7] }),
         ("resume",   { tasks := [.fin, .awaiting 7], seen := [7], applied := [7] }),
         ("resume",   { tasks := [.fin, .fin], seen := [7, 7], applied := [7, 7] })]) :=
  validPath_reach nextBuggy _ _ _ .refl (by decide)

/-- Fixed handler: claim `seen` before the await. -/
inductive Step : S → S → Prop
  | dispatch : s.inbox = k :: rest → k ∉ s.seen →
      Step s { s with inbox := rest, seen := k :: s.seen, tasks := s.tasks ++ [.awaiting k] }
  | dedup : s.inbox = k :: rest → k ∈ s.seen → Step s { s with inbox := rest }
  | resume : s.tasks[i]? = some (.awaiting k) →
      Step s { s with tasks := s.tasks.set i .fin, applied := k :: s.applied }
  | retry (k : Nat) : Step s { s with inbox := s.inbox ++ [k] }   -- at-least-once producer

def Inv (s : S) : Prop :=
  s.applied.Nodup ∧ (∀ k, k ∈ s.applied → k ∈ s.seen) ∧
  (∀ (i k : Nat), s.tasks[i]? = some (PC.awaiting k) →
     k ∈ s.seen ∧ k ∉ s.applied ∧                  -- `k ∈ s.seen` is the strengthening
     ∀ j : Nat, s.tasks[j]? = some (PC.awaiting k) → i = j)

theorem inv_step (h : Inv s) (hs : Step s s') : Inv s' := by
  cases hs <;> grind [Inv]

theorem inv_init : Inv ({ inbox := xs } : S) := by simp [Inv]

/-- Exactly-once side effects for any inbox, any number of retries, any interleaving. -/
theorem applied_nodup (h : Reach Step { inbox := xs } s) : s.applied.Nodup :=
  (Reach.inv Inv inv_init (fun _ _ hi hs => inv_step hi hs) h).1

end ProofPatterns.Idempotency
