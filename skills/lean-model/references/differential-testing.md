# Differential testing: executable Lean models against production code

A proof covers the model. Differential testing checks that the model *is* the code, by
running both on the same inputs and comparing outputs. AWS Cedar calls this
verification-guided development: prove properties of a small Lean model, then test the
production Rust against it on millions of generated inputs every night.

## 1. Build the oracle

`../assets/lean-patterns/Replay.lean` is a working driver. It reads JSON Lines events from
stdin, steps the model, and prints one output per event:

```bash
lake build replay
printf '{"op":"send","m":1}\n{"op":"send","m":2}\n{"op":"recv"}\n' | lake exe replay
# null
# null
# 1
```

Replace `Q` and `apply` with the model's state and executable step. The step must be the
same `next`/`step` function the theorems are about (or one proven equal to it). Otherwise
you are testing a third artifact.

## 2. Generate inputs

- **From production:** record real event sequences (requests, messages, operations) in the
  same JSONL format.
- **Random:** a property-based generator in the *production* language (Hypothesis,
  fast-check, proptest, QuickCheck) emits sequences. Both systems consume the same file.
- **From the model:** `Explore.reachable` enumerates short sequences exhaustively, which is
  good for edge cases.

## 3. Compare

```bash
lake exe replay < cases.jsonl > model.out
prod-harness < cases.jsonl > prod.out      # thin wrapper over the real code
diff -u model.out prod.out
```

A difference is either a code bug or a model bug. Shrink it to the smallest failing
sequence (delta debugging, or the generator's shrinker), then decide which one is wrong
with the property statement in hand.

## 4. Put it in CI

Run a small fixed corpus on every PR and a large random corpus nightly. Keep every past
mismatch as a regression case.

## For concurrent code

Differential testing covers sequential semantics well. For interleavings, replay a recorded
*schedule*: log `(actor, action)` pairs from the running system (as in trace validation,
`tlaplus-model/references/trace-validation.md`), then check the sequence with
`Explore.validPath next init path` under `#eval`. A `false` means the code took a
transition the model does not allow.
