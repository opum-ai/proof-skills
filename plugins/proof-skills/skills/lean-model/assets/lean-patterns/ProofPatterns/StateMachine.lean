import ProofPatterns.Explore

/-!
# StateMachine: a persisted lifecycle with concurrent handlers

Order status is `pending → paid → shipped` or `pending → cancelled`. The cancel handler
reads, decides, then writes. A payment webhook landing in between gives `paid → cancelled`.

* `allowed` is the transition table. `decide` checks table facts exhaustively.
* `nextBuggy` plus `bfs` finds the illegal transition. `Step` (with a compare-and-set
  cancel) provably makes every status change an allowed edge.
-/
namespace ProofPatterns.StateMachine
open Explore

inductive Status | pending | paid | shipped | cancelled
  deriving DecidableEq, Repr

def allowed : Status → Status → Bool
  | .pending, .paid | .pending, .cancelled | .paid, .shipped => true
  | _, _ => false

def Status.all : List Status := [.pending, .paid, .shipped, .cancelled]

/-- Table facts, checked over every state by `decide`: terminal states have no exits. -/
example : Status.all.all (fun s => !allowed .shipped s && !allowed .cancelled s) = true := by decide

inductive CPC | start | decide (read : Status) | done
  deriving DecidableEq, Repr

structure S where
  status : Status := .pending
  cancel : CPC := .start
  last   : Option (Status × Status) := none   -- last status change, for the action property
  deriving DecidableEq, Repr

def setStatus (s : S) (t : Status) : S := { s with status := t, last := some (s.status, t) }

/-- Buggy: the cancel write does not re-check the status (read-decide-write race). -/
def nextBuggy (s : S) : List (String × S) :=
  (if s.status = .pending then [("pay", setStatus s .paid)] else []) ++
  (if s.status = .paid then [("ship", setStatus s .shipped)] else []) ++
  (match s.cancel with
   | .start => [("cancelRead", { s with cancel := .decide s.status })]
   | .decide .pending => [("cancelWrite", { setStatus s .cancelled with cancel := .done })]
   | .decide _ => [("cancelSkip", { s with cancel := .done })]
   | .done => [])

def illegal (s : S) : Bool := match s.last with
  | some (a, b) => !allowed a b
  | none => false

#eval (bfs nextBuggy illegal {}).map (·.map (·.1))
-- some ["cancelRead", "pay", "cancelWrite"]

/-- Fixed: cancel is `UPDATE … SET status='cancelled' WHERE status='pending'` (atomic CAS). -/
inductive Step : S → S → Prop
  | pay : s.status = .pending → Step s (setStatus s .paid)
  | ship : s.status = .paid → Step s (setStatus s .shipped)
  | cancelRead : s.cancel = .start → Step s { s with cancel := .decide s.status }
  | cancelWrite : s.cancel = .decide .pending → s.status = .pending →
      Step s { setStatus s .cancelled with cancel := .done }
  | cancelSkip : s.cancel = .decide r → (r ≠ .pending ∨ s.status ≠ .pending) →
      Step s { s with cancel := .done }

def Inv (s : S) : Prop := ∀ a b, s.last = some (a, b) → allowed a b = true

theorem inv_step (h : Inv s) (hs : Step s s') : Inv s' := by
  cases hs <;> simp_all [Inv, setStatus, allowed]

/-- Every status change in every reachable state follows the transition table. -/
theorem transitions_allowed (h : Reach Step {} s) : Inv s :=
  Reach.inv Inv (by simp [Inv]) (fun _ _ hi hs => inv_step hi hs) h

end ProofPatterns.StateMachine
