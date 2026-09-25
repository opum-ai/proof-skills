---
name: proof-simplify
description: Use verified TLA+ specs and Lean proofs to simplify real code safely — delete defensive checks the invariants make dead, remove locks/transactions/retries that do no work, collapse redundant states and flags, replace complex implementations with simpler ones proven equivalent, and encode invariants in types — re-verifying every change (re-check, refinement, reachable-state equivalence) before touching code. Use this skill whenever the user asks to simplify, clean up, de-risk a refactor, or reduce complexity in code that has (or could get) a formal model; asks "do we still need this lock / check / retry / state"; wants to turn proofs into code improvements; or finishes a formal-verify bug hunt and wants the payoff. If no verified model exists yet, it starts one via formal-verify first.
---

# proof-simplify

A proof tells you what is *always* true of the system. Code written without that knowledge
defends against states that cannot happen: guards that never fail, locks that protect
nothing, retries that never fire, flags that duplicate other state. Each piece costs
reading time, test time, and latency, and each is a place for new bugs.

This skill turns proven facts into deletions. It proves every deletion safe *before* making
it, then re-verifies afterwards.

The standard of evidence: **a simplification is justified only by a property the model
proved, under assumptions the code actually enforces.** Anything less is a guess dressed up
in proof vocabulary.

## Preconditions

You need all four of these; without them there is nothing to justify a deletion. If any is
missing, run `formal-verify` (W1) first:
- a model that passes (TLA+ at stated bounds, or Lean with `check_trust.sh` clean);
- frozen properties (`Properties.tla` / `Properties.lean`);
- the model's sanity checks passed (must-fail invariants fail, bug toggles fail);
- `CORRESPONDENCE.md`, including its **Assumptions** list.

## Workflow

1. **Harvest candidates.** Read the model and the code side by side. Use
   `references/catalog.md` for the eight kinds of candidate and how to spot each:
   - a guard implied by the invariant,
   - redundant synchronization,
   - a dead branch or unreachable state,
   - a dead retry or timeout path,
   - a redundant variable or flag,
   - mergeable (bisimilar) states,
   - an implementation replaceable by a simpler proven-equal one,
   - an invariant that can be encoded in types.

   List each candidate with its code location, the model element it maps to, and the fact
   that would justify it.
2. **Prove each candidate in the model before touching code.** Techniques, from cheapest to
   strongest (`references/equivalence.md`):
   - **Re-check.** Apply the simplification to the model, then re-run *every* frozen property,
     the sanity checks, and the bug toggles, at the same or larger bounds.
   - **Guard implication.** In Lean, prove the guard follows from the invariant in every
     reachable state. In TLA+, check `Enabled_A_without_G => G` as an invariant.
   - **Refinement.** Show the simplified spec implements the current one: TLA+
     `INSTANCE … WITH` checked as a PROPERTY, or a Lean simulation theorem. All safety
     properties then transfer automatically. Liveness must be re-checked.
   - **Reachable-state equivalence** (Lean `reach_iff`). The two versions reach exactly the
     same states. This is the strongest form.
   - **Function equality** (Lean `theorem simple_eq : ∀ x, simple x = current x`). Use it for
     replacing an algorithm.
3. **Audit assumptions.** For each candidate, list which Assumptions from CORRESPONDENCE.md
   the proof relies on, then decide:
   - **Remove** when every assumption is enforced by code or infrastructure you control
     (a type, a DB constraint, a single-writer design).
   - **Downgrade to an assertion** (a debug assert, a metric, or a log-and-continue) when the
     proof holds but an assumption is only conventional. The next person who breaks the
     assumption then gets a signal instead of silent corruption.
   - **Keep** when the code sits on a trust boundary (network input, user input, disk, another
     team's service, a rolling deploy with mixed versions), or when the assumption is outside
     your control. Internal invariants never justify deleting validation of external input.
4. **Apply one simplification at a time.** For each accepted candidate:
   - make the code change,
   - update the model to match it (the simplified model is now the model),
   - update CORRESPONDENCE.md,
   - run the project's tests and the reproduction tests from earlier findings,
   - re-run the model.

   Use one commit per simplification, whose message names the property that justifies it.
5. **Report.** Add `simplifications[]` to `formal/findings.json`, then publish the Artifact
   report (`formal-verify/references/report-artifact.md`, section "Simplifications"). For
   each change it shows:
   - the diff,
   - the justifying property or theorem, and its evidence,
   - the assumptions relied on,
   - the decision (removed / downgraded / kept), and
   - the lines-of-code delta.

   Also include the candidates you rejected, with the reason. They are useful knowledge ("the
   lock looks redundant but protects the cron path, which is not modeled").

## Worked examples (both verified)

- **TLA+: a lock that does nothing.** `assets/tla/CancelOrder.tla` models a cancel handler
  that takes a row lock *and* uses a conditional UPDATE, while the payment webhook never
  takes the lock.
  - `MC_current.cfg` and `MC_cas_only.cfg` pass.
  - `MC_lock_only.cfg` fails (exit 13): the lock alone never prevented `paid → cancelled`.
  - `CancelOrderSimple.tla` removes the lock, and `MC_refines.cfg` proves it refines the
    current spec under a mapping that reconstructs the lock.
  - Mutating the simplified spec to drop the CAS guard makes the check fail, so the
    refinement check has teeth.

  Decision: remove the lock, keep the CAS, and write the model's finding into the code comment.
- **Lean: a defensive guard the invariant makes dead.**
  `lean-model/assets/lean-patterns/ProofPatterns/RedundantGuard.lean`:
  - `guard_implied`: the `k ∉ applied` re-check follows from the idempotency invariant.
  - `reach_iff`: with or without it, exactly the same states are reachable.

  Decision: delete it, citing `applied_nodup`.

Run them:
```bash
T=${CLAUDE_SKILL_DIR}/../tlaplus-model/scripts/tlc.sh
for c in MC_current MC_cas_only MC_lock_only; do $T ${CLAUDE_SKILL_DIR}/assets/tla/CancelOrder.tla --config $c.cfg; done
$T ${CLAUDE_SKILL_DIR}/assets/tla/CancelOrderSimple.tla --config MC_refines.cfg
```

## What not to do

- Don't simplify on the strength of a model that never failed. Sanity checks come first.
- Don't carry a property from a bounded check into an unbounded claim. "Holds for 2 workers"
  does not justify deleting a lock that matters at 3. Either argue that the bound covers
  it (symmetry, or the property is per-pair), prove it in Lean, or re-check at larger bounds.
- Don't merge several simplifications into one unverified leap. Re-verify after each one.
  Two individually safe deletions can be jointly unsafe.
- Don't delete observability (logs, metrics) because a state is "unreachable". Consider
  turning the branch into an alert.
- Don't let a refinement proof stand in for liveness. Refinement preserves safety, so
  re-check liveness separately.

## Reference files

- `references/catalog.md` — the eight candidate kinds: how to spot them, how to justify them in TLA+ and Lean, and the typical code change.
- `references/equivalence.md` — re-check, guard implication, refinement mappings, reachable-state equivalence, and function equality, with verified templates.
