/-!
# Counter: lost update (read-modify-write), and the locked fix

Code shape: `x = counter; counter = x + 1` run by two threads.
* `RacyStep`: no lock. `racy_lost_update` is the counterexample as a kernel-checked proof term.
* `Step`: acquire, read, write-and-release. `no_lost_update` holds for every reachable state
  (an unbounded proof by an inductive invariant), and a non-vacuity witness shows the
  "both done" state really is reachable.
-/
namespace ProofPatterns.Counter

inductive PC | idle | locked | read | done
  deriving DecidableEq, Repr, Hashable

structure Th where
  pc : PC  := .idle
  r  : Nat := 0            -- thread-local register
  deriving DecidableEq, Repr, Hashable

structure S where
  x    : Nat := 0
  lock : Option Bool := none   -- which thread holds the lock
  a    : Th := {}
  b    : Th := {}
  deriving DecidableEq, Repr, Hashable

def S.th (s : S) : Bool → Th | false => s.a | true => s.b
def S.set (s : S) : Bool → Th → S
  | false, t => { s with a := t } | true, t => { s with b := t }

/-- Racy semantics: `x := x + 1` compiled to read; write. Interleaving = ∃ thread. -/
inductive RacyStep : S → S → Prop
  | read  (t : Bool) : (s.th t).pc = .idle →
      RacyStep s (s.set t { pc := .read, r := s.x })
  | write (t : Bool) : (s.th t).pc = .read →
      RacyStep s ({ s.set t { pc := .done, r := (s.th t).r } with x := (s.th t).r + 1 })

/-- Reflexive-transitive closure from an initial state. -/
inductive Reach (step : S → S → Prop) (init : S) : S → Prop
  | init : Reach step init init
  | step : Reach step init s → step s s' → Reach step init s'

/-- Counterexample as a proof term: a lost update is reachable. -/
theorem racy_lost_update :
    ∃ s, Reach RacyStep {} s ∧ s.a.pc = .done ∧ s.b.pc = .done ∧ s.x = 1 :=
  ⟨_, .step (.step (.step (.step .init (.read false rfl)) (.read true rfl))
              (.write false rfl)) (.write true rfl), rfl, rfl, rfl⟩

/-- Executable successor function (for bounded model checking via #eval). -/
def racyNext (s : S) : List S :=
  [false, true].flatMap fun t =>
    match (s.th t).pc with
    | .idle => [s.set t { pc := .read, r := s.x }]
    | .read => [{ s.set t { pc := .done, r := (s.th t).r } with x := (s.th t).r + 1 }]
    | _     => []

/-- Bounded BFS: all states reachable in ≤ k steps (dedup by DecidableEq). -/
def reachK (next : S → List S) : Nat → List S → List S
  | 0,     seen => seen
  | k + 1, seen =>
    let new := (seen.flatMap next).filter (· ∉ seen)
    if new.isEmpty then seen else reachK next k (seen ++ new.eraseDups)

#eval (reachK racyNext 10 [{}]).filter
  (fun s => s.a.pc == .done && s.b.pc == .done && s.x != 2)
-- [{ x := 1, lock := none, a := { pc := done, r := 0 }, b := { pc := done, r := 0 } }]

/-- The same bounded check, discharged by the kernel (`decide +kernel`, no compiler trust). -/
theorem racy_bug_bounded :
    ((reachK racyNext 10 [{}]).any
      fun s => s.a.pc == .done && s.b.pc == .done && s.x != 2) = true := by
  decide +kernel

/-- Fixed semantics: acquire lock; read; write-and-release. -/
inductive Step : S → S → Prop
  | acquire (t : Bool) : (s.th t).pc = .idle → s.lock = none →
      Step s { s.set t { s.th t with pc := .locked } with lock := some t }
  | read (t : Bool) : (s.th t).pc = .locked →
      Step s (s.set t { pc := .read, r := s.x })
  | write (t : Bool) : (s.th t).pc = .read →
      Step s { s.set t { pc := .done, r := (s.th t).r } with
                 x := (s.th t).r + 1, lock := none }

def holding (th : Th) : Bool := th.pc == .locked || th.pc == .read
def doneN (s : S) : Nat := (if s.a.pc = .done then 1 else 0) + (if s.b.pc = .done then 1 else 0)

/-- Inductive invariant: lock ownership is exact, registers are fresh, x counts finishers. -/
def Inv (s : S) : Prop :=
  (holding s.a ↔ s.lock = some false) ∧
  (holding s.b ↔ s.lock = some true) ∧
  (s.a.pc = .read → s.a.r = s.x) ∧
  (s.b.pc = .read → s.b.r = s.x) ∧
  s.x = doneN s

theorem inv_init : Inv {} := by simp [Inv, holding, doneN]

theorem inv_step (h : Inv s) (hs : Step s s') : Inv s' := by
  cases hs with
  | acquire t | read t | write t => cases t <;> grind [Inv, S.th, S.set, holding, doneN]

theorem inv_reach (h : Reach Step {} s) : Inv s := by
  induction h with
  | init => exact inv_init
  | step _ hs ih => exact inv_step ih hs

theorem no_lost_update (h : Reach Step {} s)
    (ha : s.a.pc = .done) (hb : s.b.pc = .done) : s.x = 2 := by
  have := inv_reach h; simp_all [Inv, doneN]

/-- Non-vacuity: the good terminal state is actually reachable. -/
example : ∃ s, Reach Step {} s ∧ s.a.pc = .done ∧ s.b.pc = .done :=
  ⟨_, .step (.step (.step (.step (.step (.step .init
      (.acquire false rfl rfl)) (.read false rfl)) (.write false rfl))
      (.acquire true rfl rfl)) (.read true rfl)) (.write true rfl), rfl, rfl⟩

#print axioms no_lost_update
#print axioms racy_bug_bounded
end ProofPatterns.Counter
