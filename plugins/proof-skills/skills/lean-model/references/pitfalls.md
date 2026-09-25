# Pitfalls

## Vacuous results
- **Contradictory guards or an unsatisfiable `init`** make every safety theorem trivially true.
  Always prove a non-vacuity witness: a `validPath … = true` by `decide`, reaching a state
  where the interesting action happened (both threads done, a message delivered, a task run).
- **An implication whose premise never holds.** `P s → Q s` where no reachable `s` satisfies `P`.
  Witness a reachable `P`-state.
- **A statement weaker than it looks.** `∀ s, Reach Step init s → True`, or a postcondition
  that restates the precondition. Read every frozen statement aloud in plain English, in the
  report.

## Trust base
- `check_trust.sh` must pass before any claim of "proven". It checks:
  - a source scan for `sorry`, `admit`, and `axiom`;
  - a per-theorem axiom audit over the compiled environment;
  - a `native_decide` gate.
- **`native_decide` adds an auxiliary axiom and trusts the compiler.** Prefer `decide +kernel`.
  Allow native only when the kernel cannot handle the size, and say so in the report.
- **`@[implemented_by]`, `@[extern]`, and `unsafe`** mean the runtime behavior is not what the
  kernel checked. They are fine in the replay executable, but never in definitions that theorems mention.
- **`partial def`** is opaque to proofs. Theorems about it are theorems about nothing.
- **The runtime is also trusted.** A proof about the model says nothing about the Lean
  compiler or runtime executing `Replay`. Kiran Gopinathan's verified-zlib work found a bug
  in the Lean runtime itself.

## Model/code drift
- The model is a separate artifact, so it drifts. The defenses are:
  - `src:` tags plus `formal-verify/scripts/correspondence_check.py`;
  - `next_sound` (the executable and relational twins agree);
  - differential testing against production (`differential-testing.md`);
  - the W6 drift workflow on every change to mapped files.
- AWS Cedar keeps its Lean models about 10× smaller than the Rust code (the evaluator is
  897 lines of Lean against 13,664 of Rust) and differentially tests them nightly with
  millions of inputs. Small models are what make proofs and drift reviews affordable.

## Over-abstraction
- Atomic read-modify-write where the code has an `await` or a lock gap in the middle.
- Omitting retries, duplicates, or crashes that the environment can produce. Add them as
  constructors; the proof then shows the code tolerates them (or does not).
- Modeling "the queue" as a set when the code relies on order, or as a list when the broker
  reorders.

## Spec gaming (agents)
- Weakening a statement, adding a hypothesis that excludes the bug, or turning a
  postcondition into `True`. Freeze statements in `Properties.lean`; any change needs the
  user's OK and a line in `formal/findings.json`.
- "Proving" the buggy model correct by strengthening the step guard until the bad path is
  impossible. That is modeling a fix that is not in the code. Mark it as a *proposed fix*,
  not a result.

## Performance
- List-based BFS explodes quickly. Keep configurations to 2–3 actors and 2 messages. For
  larger searches, switch to `Std.HashSet` under `#eval`, or move the search to TLC.
- `decide` on big structures can hit kernel limits. Use `decide +kernel`, or shrink the instance.
