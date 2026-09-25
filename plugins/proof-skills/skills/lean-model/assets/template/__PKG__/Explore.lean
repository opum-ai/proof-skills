/-!
# Explore: shared machinery for transition-system models

* `Reach step init s`: `s` is reachable from `init` via the step relation.
* `Reach.inv`: the induction principle for safety proofs (`Inv init`, and `Inv` is preserved).
* `bfs`: a bounded explorer over an *executable* successor function that returns a
  labeled counterexample path, like TLC's shortest trace.
* `validPath` and `validPath_reach`: a kernel-checkable bridge. If `bfs` finds a path, then
  `validPath … = true` by `decide` proves the bad state is reachable under `StepOf next`.
  The counterexample becomes a theorem, not just a printout.
-/
namespace __PKG__.Explore

/-- Reflexive-transitive closure of `step` from `init`. -/
inductive Reach {S : Type} (step : S → S → Prop) (init : S) : S → Prop
  | refl : Reach step init init
  | tail : Reach step init s → step s s' → Reach step init s'

/-- Safety by induction: an invariant that holds initially and is preserved holds everywhere. -/
theorem Reach.inv {S : Type} {step : S → S → Prop} {init : S} (Inv : S → Prop)
    (h0 : Inv init) (hstep : ∀ s s', Inv s → step s s' → Inv s') :
    ∀ {s}, Reach step init s → Inv s := by
  intro s h
  induction h with
  | refl => exact h0
  | tail _ hs ih => exact hstep _ _ ih hs

/-- The step relation induced by an executable, labeled successor function. -/
def StepOf {S : Type} (next : S → List (String × S)) (s t : S) : Prop :=
  ∃ l, (l, t) ∈ next s

/-- Check that consecutive states in `path` are connected by `next`. -/
def validPath {S : Type} [DecidableEq S] (next : S → List (String × S)) :
    S → List (String × S) → Bool
  | _, [] => true
  | s, (l, t) :: rest => (next s).contains (l, t) && validPath next t rest

/-- Last state of a path (or the start state if the path is empty). -/
def lastState {S : Type} (s : S) : List (String × S) → S
  | [] => s
  | (_, t) :: rest => lastState t rest

theorem validPath_reach {S : Type} [DecidableEq S] (next : S → List (String × S))
    (init : S) : ∀ (s : S) (path : List (String × S)),
      Reach (StepOf next) init s → validPath next s path = true →
      Reach (StepOf next) init (lastState s path)
  | _, [], h, _ => h
  | s, (l, t) :: rest, h, hv => by
    simp only [validPath, Bool.and_eq_true, List.contains_iff_mem] at hv
    exact validPath_reach next init t rest (.tail h ⟨l, hv.1⟩) hv.2

/-- Bounded BFS. Returns the labeled path from `init` to the first state satisfying `bad`
    (shortest in steps), or `none` if none is found within `fuel` expansions. -/
def bfs {S : Type} [DecidableEq S] (next : S → List (String × S)) (bad : S → Bool)
    (init : S) (fuel : Nat := 100000) : Option (List (String × S)) :=
  go fuel [(init, [])] [init]
where
  go : Nat → List (S × List (String × S)) → List S → Option (List (String × S))
    | 0, _, _ => none
    | _, [], _ => none
    | f + 1, (s, rpath) :: rest, seen =>
      if bad s then some rpath.reverse
      else
        let succs := (next s).filter (fun p => p.2 ∉ seen)
        go f (rest ++ succs.map (fun p => (p.2, p :: rpath))) (seen ++ succs.map (·.2))

/-- All states reachable within `fuel` expansions (for exhaustive bounded checks). -/
def reachable {S : Type} [DecidableEq S] (next : S → List (String × S)) (init : S)
    (fuel : Nat := 100000) : List S :=
  go fuel [init] [init]
where
  go : Nat → List S → List S → List S
    | 0, _, seen => seen
    | _, [], seen => seen
    | f + 1, s :: rest, seen =>
      let succs := ((next s).map (·.2)).filter (· ∉ seen)
      go f (rest ++ succs) (seen ++ succs)

end __PKG__.Explore
