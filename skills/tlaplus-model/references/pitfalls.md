# Pitfalls and how to catch them

## A spec that cannot fail

| Symptom | Check |
|---|---|
| Invariant holds, but the interesting states are unreachable | Sanity invariant that must fail (`NeverAllDone`, `NoWriteHappens`) |
| `P => Q` holds because `P` never happens | Check `~P` as an invariant; it must fail |
| An action never fires (a guard is contradictory) | `-coverage 1`; actions with 0 distinct states |
| The fix "works" but the property never guarded the bug | Bug toggle: with the fix off, the property must fail |
| Liveness holds trivially | TLC warns on trivially true liveness; also check the `<>` target is reachable |

## Modeling errors

- **Under-modeling atomicity.** Merging two code steps into one action removes the interleaving
  between them. That is often exactly the bug. MongoDB's Raft conformance effort failed partly
  because the spec made step-down plus step-up atomic when the code does not. Split by default.
- **Over-modeling.** Byte-level data, full retry schedules, and real clocks blow up the state
  space without adding bugs. Abstract to what the properties read.
- **Unbounded growth.** Counters, logs, and sequences that grow forever make TLC run forever.
  Bound them with constants (`MaxClaims`), or with a `CONSTRAINT` (for example
  `TLCGet("level") < 30`), and state the bound in the report. Constraints also change what
  liveness means.
- **Missing `UNCHANGED`.** An unmentioned variable can take any value, so the model is wrong
  silently. `TypeOK` usually catches it.
- **Mixed types.** Comparing a string to an integer is a TLC error. Use a sentinel of the
  same type (`None == -1` with `EXTENDS Integers`), or model values.
- **`IF/THEN/ELSE` and `CASE` swallow the conjuncts that follow them.** Parenthesize.
- **Too-strong properties.** Coherence and consistency often only hold at rest. Guard them
  with `Quiescent`, or state them as `[]<>` or `~>`.

## Liveness traps

- Without fairness, every `<>` and `~>` property fails by stuttering. That counterexample is
  meaningless; add fairness.
- Too much fairness hides starvation. Put fairness only on what the real scheduler or runtime
  guarantees. Use `SF` for actions that are enabled only intermittently (for example, lock
  acquisition contended by others).
- Never put fairness on environment faults. "The network eventually stops dropping" is an
  assumption; if you need it, state it as one.
- **Symmetry plus liveness is unsound.** Use separate configs.
- `-deadlock` hides stuck states. Model termination explicitly.

## Agent-specific failure modes

Published evaluations (Hillel Wayne 2025; the Specula ablation 2026; arXiv 2606.05792) find
that LLMs are good at TLA+ syntax, `UNCHANGED` bookkeeping, and explaining long traces.
They are poor at:
- **proposing properties.** They pick trivial ones, or ones that restate the implementation.
  Harvest properties from requirements, docs, and bug history instead, cite a source for
  each, and freeze them.
- **"fixing" the spec instead of the code.** For example, assuming the race cannot happen,
  weakening a guard, or adding a constraint that excludes the trace. Diff every change to
  `CONSTRAINT`, fairness, and `Properties.tla`, and report it.
- **trusting unvalidated specs.** Across 30 models, at most 26.6% of generated specs parsed
  and 8.6% were semantically right. Treat every new spec as a hypothesis until the sanity
  checks, the bug toggle, and (ideally) trace validation pass.

The fix is always evidence from outside the model: reproduction in code, trace validation,
or the sanity and toggle checks above.
