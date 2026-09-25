import Plausible

/-!
# Pipeline: a batching stage in a dataflow

`batchBuggy` never flushes the trailing partial batch. `plausible` finds a counterexample
in milliseconds (`xs := [0]`). `batch` is the fix, and `batch_lossless` proves that
flattening its output gives back the input, for every input and every batch size.

This is the Lean analogue of TLA+'s liveness-only bug: a sequential pure function that
loses data. It is proven here without modeling interleavings at all.
-/
namespace ProofPatterns.Pipeline

def batchBuggy (n : Nat) (xs : List Nat) : List (List Nat) :=
  let (out, _buf) := xs.foldl (init := ([], [])) fun (out, buf) x =>
    if buf.length + 1 = n then (out ++ [buf ++ [x]], []) else (out, buf ++ [x])
  out                          -- BUG: trailing partial batch never flushed

/- `plausible` refutes the lossless claim for the buggy version. Uncomment to see
   "Found a counter-example! xs := [0]". It is kept commented so the build stays green. -/
-- example : ∀ xs : List Nat, (batchBuggy 3 xs).flatten = xs := by plausible

/-- Bounded refutation that does stay in the build: the kernel confirms the bug on `[0]`. -/
example : (batchBuggy 3 [0]).flatten ≠ [0] := by decide

def step (n : Nat) : List (List Nat) × List Nat → Nat → List (List Nat) × List Nat
  | (out, buf), x => if buf.length + 1 = n then (out ++ [buf ++ [x]], []) else (out, buf ++ [x])

def batch (n : Nat) (xs : List Nat) : List (List Nat) :=
  let (out, buf) := xs.foldl (step n) ([], [])
  if buf.isEmpty then out else out ++ [buf]

/-- Generalized loop invariant: the classic move when induction on the original goal fails. -/
theorem foldl_step (n : Nat) : ∀ (xs : List Nat) (out : List (List Nat)) (buf : List Nat),
    (xs.foldl (step n) (out, buf)).1.flatten ++ (xs.foldl (step n) (out, buf)).2
      = out.flatten ++ buf ++ xs
  | [], out, buf => by simp
  | x :: xs, out, buf => by
    simp only [List.foldl_cons, step]
    split <;> simp [foldl_step n xs]

theorem batch_lossless (n : Nat) (xs : List Nat) : (batch n xs).flatten = xs := by
  have := foldl_step n xs [] []
  simp only [batch]; split <;> simp_all

end ProofPatterns.Pipeline
