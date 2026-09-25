# Workflows W1–W8

Each workflow lists: when to use it, entry criteria, steps, exit criteria, and hand-offs.
W1 is the backbone; the others reuse its steps by number (W1.1 … W1.8, see SKILL.md).

## Contents
- W1 Bug hunt
- W2 Change review (PR / diff)
- W3 Design verification (no code yet)
- W4 Proof-guided simplification
- W5 Regression guard (CI)
- W6 Drift check
- W7 Escalate TLA+ → Lean
- W8 Explain a trace
- Chaining workflows

---

## W1 Bug hunt

**Use when** the user asks to find bugs, races, or unsafe behavior in existing code.

**Entry:** a repository and a named area, or enough context to pick one.
If the user gives no area, do a 10-minute triage pass: grep for shared mutable state
(locks, `async`/`await`, goroutines, channels, threads, queues, caches, retries, `setTimeout`,
DB transactions, `SELECT … FOR UPDATE`, compare-and-swap, event emitters, webhook handlers,
schedulers, graph/DAG code). Propose the top three concerns with a one-line risk each and
let the user pick, or pick the highest-risk one if they said "just go".

**Steps:** W1.1–W1.8 in SKILL.md.

**Exit:** every finding is *confirmed* (reproduced + fixed or fix proposed), *suspected*
(counterexample, no reproduction yet — say why), or *refuted* (model error found and fixed).
Report published. Follow-ups offered: W4, W5.

**Budget guidance:** a first model should check in minutes, not hours. If TLC runs over
~10 minutes at the smallest meaningful bounds, the model is too detailed — abstract more
before scaling up. Stop and report partial results if a concern is not converging after
several modeling rounds; say what blocked it.

---

## W2 Change review

**Use when** the user asks whether a PR, branch, or diff introduces races or breaks
invariants.

1. Read the diff. List the shared state it touches and the call paths that reach that state.
2. If a spec for the area already exists (look in `formal/`, `specs/`, `tla/`, `proofs/`),
   update it to the new code (mirror the diff in the model, update CORRESPONDENCE.md) and
   re-run it. That is the cheapest and strongest review.
3. If no spec exists, model *only* the changed protocol plus the minimum context needed
   for the properties (W1.1–W1.5 with a tight scope).
4. Also model the pre-change code when a finding appears, and check the property there.
   "New in this PR" versus "pre-existing" changes what the reviewer should do.
5. Report per finding: introduced / pre-existing / fixed-by-this-PR.

**Exit:** a review verdict with evidence; optional inline PR comments if the user asks.

---

## W3 Design verification

**Use when** there is a design doc, RFC, ADR, or whiteboard protocol, and no code yet
(or the user wants to validate an idea before rewriting).

1. Extract actors, messages, state, and failure assumptions (crash? message loss?
   duplication? reordering? clock skew?) from the doc. List the assumptions explicitly and
   confirm them with the user. Wrong failure assumptions are the most common design-spec
   mistake.
2. Write the spec at design granularity (tlaplus-model; PlusCal or Quint is fine if the
   team reads pseudocode more easily).
3. Check safety, then liveness under explicitly stated fairness.
4. Iterate the *design* with the user on counterexamples. Each iteration: counterexample →
   design change → re-check.
5. Output: the spec as the executable design, a list of invariants the implementation must
   preserve, and a test plan derived from the spec (for example, model-based tests via
   `quint run --mbt`, or one test per interesting trace).

**Exit:** a design that passes checks at stated bounds, plus a hand-off package for
implementers. Recommend W5 once code exists.

---

## W4 Proof-guided simplification

**Use when** a model has passed (W1/W3 output, or an existing spec/proof), and the user
wants to remove complexity, or asks "do we still need this lock/check/retry?".

Hand off to the `proof-simplify` skill. It needs the passing model, its frozen properties,
and CORRESPONDENCE.md. If any of these are missing, run W1 first. Otherwise there is
nothing to justify a deletion.

---

## W5 Regression guard

**Use when** a spec exists and the user wants it enforced going forward.

1. Split configs into a fast CI config (smallest bounds that still catch every past bug,
   under ~2 minutes) and a nightly/deep config.
2. Add every confirmed bug's trace as a regression. In TLA+: the fixed spec must pass. Also
   keep a "bug mode" config (constant `BugFixEnabled = FALSE`) that must *fail*. This proves
   the check still has teeth. In Lean: keep the theorem, and keep a `#guard`/`decide` test for
   the concrete bad input.
3. Add the code-level reproduction tests to the normal test suite.
4. Add the CI job (`references/ci-and-drift.md` has GitHub Actions templates).
5. Add a CODEOWNERS or PR-template nudge: changes to files in CORRESPONDENCE.md require
   the spec to be updated or explicitly waived.

---

## W6 Drift check

**Use when** code changed since the spec was written, or before trusting an old spec.

1. Read CORRESPONDENCE.md. For each row, check the referenced `file:line` still exists and
   still does what the row says (`git log -L` or `git diff <spec-commit>..HEAD -- <files>`).
2. Classify each row: *unchanged*, *moved* (update the pointer), *changed semantics*
   (update the model), *deleted* (remove from model or flag).
3. Look for new code paths that touch the modeled state but have no row (grep the state's
   identifiers). These are the dangerous drifts.
4. Update the model, re-run, and report drift items alongside any new findings.
5. Where it is feasible, add trace validation or model-based testing
   (`tlaplus-model/references/trace-validation.md`). It detects drift continuously
   instead of by audit.

---

## W7 Escalate TLA+ → Lean

**Use when** TLC passed at small bounds and the user needs the property for all sizes, or
the core of the protocol is an algorithm whose correctness TLC can only sample.

1. Keep the TLA+ spec as the interleaving model. Identify the property that needs to be
   unbounded (for example, "the dispatcher never starts a task before its predecessors" for
   any DAG).
2. In `lean-model`, encode the same state and step relation, and state the invariant.
   Prove it by induction over steps. First use `decide` on small instances to check the
   invariant is true before trying to prove it.
3. When the proof gets stuck, the missing lemma often shows a real edge case. Bring it
   back to TLA+ as a new invariant and check it there quickly.
4. Report both: TLC results (bounded, all interleavings) and Lean theorems (unbounded,
   trust base printed with `#print axioms`).

The reverse direction also works: a Lean-verified algorithm that is then used
concurrently goes to TLA+ with the algorithm as one atomic action.

---

## W8 Explain a trace

**Use when** the user pastes TLC/Apalache/Quint output or a Lean counterexample and wants
to understand it.

1. Parse it (`tlaplus-model/scripts/parse_tlc_trace.py` for TLC text or JSON output).
2. For each step, show the action and the variables that *changed*. Map each action to
   code through CORRESPONDENCE.md if one exists.
3. Tell the story in the user's domain terms ("worker A claims job 1, lease expires, worker B
   claims job 1, both commit"). Name the step where the invariant becomes false and the
   earliest step where the run was already doomed.
4. Say whether this is a real bug, a model artifact (over-abstraction, missing guard,
   missing fairness), or a property that is too strong (for example, it should only hold at
   quiescence).
5. For more than a few steps, publish a small Artifact with the trace as a
   sequence diagram (report-artifact.md, "trace-only report").

---

## Chaining workflows

Typical chains:
- **W1 → W4 → W5**: find and fix bugs, simplify using what was proven, lock it in CI.
- **W3 → implement → W6 → W5**: verify the design, build it, confirm code matches the spec, guard it.
- **W2 → W1**: a PR review that finds a pre-existing bug becomes a full hunt on that concern.
- **W1 (TLA+) → W7 (Lean) → W4**: bounded check, unbounded proof, then simplify with confidence.

At the end of any workflow, name the next useful workflow in one line and let the user choose.
