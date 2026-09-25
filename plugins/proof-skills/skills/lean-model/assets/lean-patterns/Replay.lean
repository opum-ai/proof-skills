import Lean.Data.Json
open Lean

/-!
# Replay: differential testing driver

Reads JSON Lines events from stdin, applies them to an executable model, and prints the
model's output for each event. Diff this output against the production system's log for
the same events:

    lake exe replay < trace.jsonl > model.out
    diff model.out prod.out

This example models a FIFO queue. Replace `Q` and `apply` with your model's state and step.
-/

structure Q where
  chan : List Nat := []
  deriving ToJson

def apply (q : Q) (ev : Json) : Except String (Q × Json) := do
  match ← ev.getObjValAs? String "op" with
  | "send" => let m ← ev.getObjValAs? Nat "m"; pure ({ chan := q.chan ++ [m] }, Json.null)
  | "recv" => match q.chan with
    | m :: rest => pure ({ chan := rest }, toJson m)
    | []        => pure (q, Json.null)
  | op => throw s!"unknown op {op}"

def main : IO UInt32 := do
  let stdin ← IO.getStdin
  let mut q : Q := {}
  repeat
    let line ← stdin.getLine
    if line.isEmpty then break
    match Json.parse line >>= apply q with
    | .ok (q', out) => q := q'; IO.println out.compress
    | .error e => IO.eprintln e; return 1
  return 0
