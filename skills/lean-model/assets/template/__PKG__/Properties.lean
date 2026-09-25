import __PKG__.System

/-!
# Properties (frozen)

Each property cites where the requirement came from. Do not weaken a statement here
without the user's explicit approval; record any change in formal/findings.json.
-/
namespace __PKG__
open Explore

/-- Source: <README.md:40 / issue #123 / API contract>. Plain English: <...>. -/
def Safe (_s : S) : Prop := True

instance : DecidablePred Safe := fun _ => inferInstanceAs (Decidable True)

/-- Inductive invariant: `Safe` plus whatever strengthening the proof needs. -/
def Inv (s : S) : Prop := Safe s

theorem inv_init : Inv init := by simp [Inv, Safe]

theorem inv_step (_h : Inv s) (hs : Step s s') : Inv s' := by
  cases hs

theorem safe_of_reach (h : Reach Step init s) : Safe s :=
  Reach.inv Inv inv_init (fun _ _ hi hs => inv_step hi hs) h

/-! ## Bounded checks: run these first, before trying to prove anything -/

-- Shortest path to a state violating `Safe` (none = no violation within the bound).
#eval (bfs next (fun s => !decide (Safe s)) init).map (·.map (·.1))

-- Non-vacuity: replace with a path to an interesting "good" state and prove it by `decide`.
-- example : validPath next init [("action", { ... })] = true := by decide

end __PKG__
