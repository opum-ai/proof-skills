import ProofPatterns.Explore

/-!
# DagScheduler: dependency-respecting dispatch for *every* graph

TLA+ (`DagScheduler.tla`) checks all DAGs on 3–4 nodes. This proof covers every
dependency function, every number of tasks, and every interleaving of dispatch and finish.

* `nextBuggy` (ready = predecessors *started*) plus `bfs` finds a violation on a 2-node graph.
* `Step` (ready = predecessors *finished*) preserves `Inv`: a running task's predecessors
  are all done.

The graph does not even need to be acyclic for the safety property. Acyclicity is needed for
*progress* (liveness), which stays in the TLA+ model.
-/
namespace ProofPatterns.DagScheduler
open Explore

structure S where
  running : List Nat := []
  done    : List Nat := []
  deriving DecidableEq, Repr

inductive Step (preds : Nat → List Nat) : S → S → Prop
  | dispatch (t : Nat) : t ∉ s.running → t ∉ s.done → (∀ p ∈ preds t, p ∈ s.done) →
      Step preds s { s with running := t :: s.running }
  | finish (t : Nat) : t ∈ s.running →
      Step preds s { running := s.running.erase t, done := t :: s.done }

def Inv (preds : Nat → List Nat) (s : S) : Prop := ∀ t ∈ s.running, ∀ p ∈ preds t, p ∈ s.done

theorem inv_step (h : Inv preds s) (hs : Step preds s s') : Inv preds s' := by
  cases hs with
  | dispatch t _ _ hp =>
    intro u hu p hpu
    simp only [List.mem_cons] at hu
    rcases hu with rfl | hu
    · exact hp p hpu
    · exact h u hu p hpu
  | finish t _ =>
    intro u hu p hpu
    exact List.mem_cons_of_mem _ (h u (List.mem_of_mem_erase hu) p hpu)

theorem deps_respected (h : Reach (Step preds) {} s) : Inv preds s :=
  Reach.inv (Inv preds) (by simp [Inv]) (fun _ _ hi hs => inv_step hi hs) h

/-- Buggy readiness: every predecessor has *started* (running or done). -/
def nextBuggy (tasks : List Nat) (preds : Nat → List Nat) (s : S) : List (String × S) :=
  (tasks.filter fun t => t ∉ s.running && t ∉ s.done &&
      (preds t).all fun p => p ∈ s.running || p ∈ s.done).map
    (fun t => (s!"dispatch {t}", { s with running := t :: s.running })) ++
  s.running.map fun t => (s!"finish {t}", { running := s.running.erase t, done := t :: s.done })

def violates (preds : Nat → List Nat) (s : S) : Bool :=
  s.running.any fun t => (preds t).any fun p => p ∉ s.done

/-- Graph 1 → 2: task 2 is dispatched while 1 is still running. -/
def preds12 : Nat → List Nat | 2 => [1] | _ => []

#eval (bfs (nextBuggy [1, 2] preds12) (violates preds12) {}).map (·.map (·.1))
-- some ["dispatch 1", "dispatch 2"]

end ProofPatterns.DagScheduler
