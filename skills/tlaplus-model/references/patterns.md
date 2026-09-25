# TLA+ pattern catalog

Every pattern in `../assets/patterns/<Name>/` has been run through TLC 2026.09 (tla2tools
v1.8.0+) with these results:

| Pattern | `MC.cfg` (fix on) | `MC_bug.cfg` (fix off) | `MC_sanity.cfg` |
|---|---|---|---|
| LostUpdate | pass, 13 states | exit 12: NoLostUpdate | exit 12 (reachability) |
| CacheAside | pass, 85 states | exit 12: NoStaleAtRest | exit 12 |
| IdempotentRetry | pass, 13 states, + liveness | exit 12: AtMostOnce | exit 12 |
| JobLease | pass, 25 states, + liveness | exit 12: SingleCommit | exit 12 |
| BatchPipeline | pass, 25 states, + liveness | **exit 13**: AllDelivered (liveness-only bug) | exit 12 |
| DagScheduler | pass, all 25 DAGs on 3 nodes | exit 12: DepsRespected | exit 12 |
| OrderStateMachine | pass | **exit 13**: ValidTransitions (action property) | exit 12 |

Copy a directory into `formal/<concern>/tla/`, rename the module (file name = module name),
replace the `src:` tags with real code locations, and adapt it. Keep the three-config
structure. It is what proves the final model can still fail.

---

## LostUpdate — read-modify-write and check-then-act

**Finds:** increments that are lost, "check balance then debit", "if not exists then insert",
and any code that reads shared state, computes, then writes it back.
**Shape:** per-thread `pc` with `start → read → write → done`, and a thread-local `tmp`.
**Fix toggle:** `UseLock`. The same skeleton covers:
- **CAS loops:** a `Write` guard `counter = tmp[t]`, plus a retry path back to `read`.
- **DB isolation:** model each SQL statement as an action. Under READ COMMITTED, a
  `SELECT` followed by an `UPDATE` is two actions.
- **Lock ordering / deadlock:** two locks and two threads that acquire them in opposite
  orders. Leave deadlock checking on; TLC reports exit 11 with the cycle.

## CacheAside — async/await interleaving

**Finds:**
- stale caches after concurrent fill and invalidate,
- read-your-writes violations,
- "delete then set" races, and
- double-checked initialization in async code.

**Shape:** each action is one await-free block. Readers: `RMiss` (read DB) then `RFill`
(write cache). Writer: `WWrite` (DB) then `WInval` (cache).
**Property:** `NoStaleAtRest`, guarded by `Quiescent`. Coherence may lapse mid-flight;
that alone is not the bug.
**Fix toggle:** `UseLease`, with memcache-style lease tokens (the invalidation bumps a
generation, and a stale fill is dropped). Other fixes to model the same way:
- a versioned value with compare-and-set on the fill,
- delayed double delete,
- write-through with a version check.

**Also here:** `TraceCacheAside.tla`, a trace-validation harness (see trace-validation.md).

## IdempotentRetry — at-least-once delivery

**Finds:** duplicate side effects from client retries, broker redelivery, webhook replays, or
two workers handling the same message. The core issue is "check the dedup table, do the side
effect, then write the dedup entry" across awaits.
**Shape:** `Deliveries` = copies of one logical request, handled concurrently.
**Fix toggle:** `ClaimFirst` claims the key atomically *before* the side effect
(`INSERT … ON CONFLICT DO NOTHING`, `SETNX`, a conditional put).
**Extend:** add a `Crash(d)` action between claim and apply to see the price of claim-first:
at-most-once, which becomes a lost request. Then model the real remedies:
- an outbox,
- a transactional claim plus effect, or
- a status column (`claimed → applied`) with recovery.

## JobLease — leases, expiry, fencing

**Finds:**
- double execution when a lease expires under a slow or paused holder,
- split-brain leaders, and
- stale writers after failover.

**Shape:** `Expire` is an environment action (time passes or the process pauses) that can
fire at any moment. `Claim` requires `owner = None \/ expired`.
**Fix toggle:** `UseFencing`. The commit is a compare-and-set on the claim token, and
stale holders abort.
**Liveness:** `(owner # None) ~> jobDone`, under weak fairness on `Commit` and `Abort` only
(never on `Expire`).
**Extend:** add lease renewal (`Renew(w)`), and more workers or claims (`MaxClaims`).

## BatchPipeline — dataflow and streams

**Finds:**
- the last partial batch lost at end-of-stream,
- items lost or duplicated across stages,
- reordering,
- unbounded buffering (backpressure bugs), and
- stalls.

**Shape:** a producer feeds a bounded queue, a batcher reads it, and a sink receives
batches. `Flat` flattens the output.
**Properties:**
- `Backpressure` (queue ≤ Cap),
- `NoLossDupReorder` (everything seen so far is a prefix of the input), and
- `AllDelivered` (liveness).

**Lesson:** the end-of-stream bug violates *no* safety property. Only liveness catches it,
as exit 13. Always pair "nothing bad" with "something good eventually".
**Extend:**
- more stages,
- fan-out / fan-in (then check the output is a permutation of the input),
- a retrying sink (then check for duplicates), and
- cancellation.

## DagScheduler — graphs, checked across all small graphs

**Finds:**
- tasks dispatched before their dependencies finish,
- tasks run twice,
- a stuck scheduler when a worker fails, and
- cycle-detection bugs.

**Shape:** `Init` picks *any* acyclic edge set on `Nodes`, so one run checks every DAG
(25 on 3 nodes; 543 on 4). `Reach` and `Acyclic` are recursive operators you can reuse
for any graph property.
**Fix toggle:** `ReadyWhenDone`. The bug is readiness computed from "started" rather than
"finished".
**Extend:**
- task failure with retries,
- cancellation propagating downstream,
- dynamic edge insertion (check `Acyclic(E)` as an invariant to catch check-then-insert
  races on the graph itself), and
- a mark phase for GC/reachability (`marked \subseteq Reach(E, roots)` during the run, with
  equality at the end).

## OrderStateMachine — persisted lifecycles

**Finds:** illegal transitions (for example `paid → cancelled`) from handlers that read the
status, decide, then write.
**Shape:** a status enum, an `Allowed` edge set, and concurrent handlers.
**Property:** an action property, `[][status' # status => <<status, status'>> \in Allowed]_vars`.
TLC reports it with exit 13.
**Fix toggle:** `UseCAS` (`UPDATE … WHERE status = 'pending'`).
**Extend:** several entities (a function from ids to status), timers (auto-expire pending),
and outbound side effects per transition (email, refund) with at-least-once delivery.

---

## Building a new model from scratch

1. List the actors and their per-actor program counters (one value per atomic region).
2. List the shared variables with small domains. Write `TypeOK` first.
3. Write one action per atomic region, with a `src:` tag and every variable either primed or `UNCHANGED`.
4. Write the environment actions: crash, timeout, drop, duplicate, reorder, pause.
5. Write the invariants and action properties, then liveness with justified fairness.
6. Write the sanity invariant and a bug toggle.
7. Write three configs. Run SANY, then TLC at the smallest bounds.
