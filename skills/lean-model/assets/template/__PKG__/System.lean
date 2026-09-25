import __PKG__.Explore

/-!
# System model: <concern>

Scope: see ../SCOPE.md. Correspondence: see ../CORRESPONDENCE.md.
Atomicity rule: one `Step` constructor per atomic region of the code
(an await-free block, a locked section, one SQL statement, one message handler).
-/
namespace __PKG__
open Explore

/-- State of the modeled component. Keep only what the properties read.
    src: path/to/file.ext:lines -/
structure S where
  -- field : Type := default   -- src: path:line
  deriving DecidableEq, Repr

def init : S := {}

/-- The step relation used in proofs. One constructor per atomic action.
    src: tag each constructor's docstring with its code location. -/
inductive Step : S → S → Prop

/-- Executable twin of `Step` (labels = action names), for `bfs` / `reachable` / `#eval`.
    Keep it in lockstep with `Step`; `next_sound` below enforces one direction. -/
def next (_s : S) : List (String × S) := []

/-- Every executable transition is a `Step`. Proving this keeps the two twins honest. -/
theorem next_sound : ∀ {s t : S} {l : String}, (l, t) ∈ next s → Step s t := by
  intro s t l h; simp [next] at h

end __PKG__
