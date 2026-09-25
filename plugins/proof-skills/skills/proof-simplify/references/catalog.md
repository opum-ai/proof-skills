# Simplification catalog

For each kind: the signal in the model, the justification to produce, the typical code
change, and when to stop short of deleting.

## 1. Guard implied by the invariant

**Signal:** an action has a guard `G` (an `if` check, an `assert`, an early return) that
also follows from the proven invariant whenever the action is otherwise enabled.
**Justify:**
- **Lean:** `theorem guard_implied : Reach Step init s → EnabledWithoutG s → G s`, then
  `reach_iff` (see `RedundantGuard.lean`).
- **TLA+:** add the invariant `EnabledWithoutG => G` and check it. Then remove `G` from the
  action and re-check everything.

**Code change:** delete the check, or downgrade it to a debug assertion.
**Stop short when** the check validates input from outside the modeled system.

## 2. Redundant synchronization

**Signal:** a lock, a transaction, `SELECT … FOR UPDATE`, a mutex, a `synchronized` block, or
a serializing queue, where either:
- removing it from the model keeps every property true, or
- the other parties never take it, so it protects nothing (as in `CancelOrder.tla`).

**Justify:** re-check with the lock removed. Better, prove the lock-free spec refines the
locked one (a mapping that reconstructs the lock variable).
**Code change:** remove the lock and the lock-ordering constraints it forced. This often also
removes deadlock risk and latency.
**Stop short when:**
- unmodeled callers might rely on the lock (other endpoints, cron jobs, admin tools). Grep
  for every acquirer before deleting.
- the model makes some step atomic that the code does not.

## 3. Dead branch or unreachable state

**Signal:**
- **TLC:** `-coverage` shows an action or disjunct with 0 distinct states, or an invariant
  `pc # "state_x"` holds.
- **Lean:** `bfs` never reaches it, and `Reach → ¬ inStateX` proves it.

**Justify:** show that the state or branch is unreachable, with the sanity check that it
*would* be reached if the upstream guard were removed. That check shows the
unreachability is structural, not vacuous.
**Code change:** delete the branch, or replace it with an explicit panic or alert.
**Stop short when** the branch handles an environment fault the model left out (disk full,
partial writes, clock jumps). Unreachable in the model is not unreachable in production.

## 4. Dead retry, timeout, or recovery path

**Signal:** a retry loop, a timeout handler, or a recovery job whose trigger condition can
never arise under the modeled failure assumptions. Or: removing it keeps both safety and
liveness.
**Justify:** re-check both safety **and liveness** with the path removed. Retries usually
exist for liveness.
**Code change:** delete it, or simplify it (for example, a fixed backoff instead of a
state-machine retry).
**Stop short when** the failure model (CORRESPONDENCE Assumptions) is narrower than
reality. A retry that is dead under "no network faults" is alive in production.

## 5. Redundant variable or flag

**Signal:** a variable that no guard or property reads, or one that is always a function of
other state (TLA+: `flag = (status = "done")` holds as an invariant; Lean: the same, proven).
**Justify:** prove the functional dependency, then remove the variable from the model and
re-check.
**Code change:** delete the field and derive it where needed (a computed property or a view).
This removes a whole class of "flags out of sync" bugs.
**Stop short when** the field is persisted and read by other services or old versions.
Plan a migration instead.

## 6. Mergeable states

**Signal:** two states (a `pc` value, a status enum value) with the same enabled actions
and successors that are equivalent up to the merge (bisimilar). Or: a property never
distinguishes them and nothing observable does either.
**Justify:** define the merged model, and prove refinement *both ways*: the merged model
refines the original, and the original refines it under the collapse mapping.
**Code change:** collapse the enum values and delete the transitions between them.
**Stop short when** external APIs or stored data expose the distinction.

## 7. Simpler equivalent implementation

**Signal:** a hand-optimized or convoluted function (a manual cache, a bespoke loop, a
duplicated special case) where a straightforward version would do.
**Justify:**
- **Lean:** `theorem simple_eq : ∀ x, simple x = current x`. Use `plausible` first to check
  it is true.
- Or, for algorithms: prove the simple version against the spec and keep the fast one as a
  checked variant (a certificate checker, as in `Graph.lean`).

**Code change:** replace it, or keep the fast version behind the simple one as a
differential-test oracle (`lean-model/references/differential-testing.md`).
**Stop short when** the performance characteristics matter and were not modeled. Benchmark first.

## 8. Encode the invariant in types

**Signal:** the invariant says "exactly one of these holds", or "field X is set iff status is
Y" (for example, `claimed_by` is non-null iff status = `claimed`).
**Justify:** the invariant itself (already proven).
**Code change:** make illegal states unrepresentable. Replace booleans and nullable fields
with a sum type or enum carrying its data (`Claimed { by, lease }`), non-empty collections,
or newtypes with smart constructors. Many runtime checks then disappear at compile time.
**Stop short when** a serialization boundary would need a migration. Do it in the domain
layer first.

---

## Candidate record (for findings.json `simplifications[]`)

```json
{
  "id": "S1",
  "change": "Remove row lock in cancel handler",
  "code": "api/orders_controller.rb:39",
  "justification": "CancelOrderSimple refines CancelOrder (RefinesCurrent); ValidTransitions holds with CAS only; lock-only config violates it",
  "relies_on_assumptions": ["A2: all status writers use conditional UPDATE"],
  "reverified": "passes",
  "loc_delta": -6,
  "status": "applied"
}
```
