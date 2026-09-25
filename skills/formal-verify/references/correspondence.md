# Model ↔ code correspondence

The correspondence map is the contract between the model and the code. Without it:
- a counterexample cannot be explained in code terms,
- a fix cannot be mirrored in the model,
- drift cannot be detected, and
- `proof-simplify` cannot justify deleting anything.

Keep it in `formal/<concern>/CORRESPONDENCE.md` (template: `../assets/CORRESPONDENCE.md`).

## What to record

One row per model element (TLA+ action or variable, Lean function or structure field):

| Model element | Code | Kind | Abstraction | Notes |
|---|---|---|---|---|
| `RMiss(r)` | `src/cache.py:41-48` `get()` miss branch through `await db.get` | action | the DB read is atomic; latency not modeled | |
| `cache` | `src/cache.py:12` `self._store` | variable | one key only | multi-key is symmetric |
| `WInval` | `src/writer.py:88` `cache.delete(k)` | action | the delete cannot fail | failure is out of scope (SCOPE.md) |

Also add a short **Assumptions** list: the facts about the environment the model relies on
("single event loop", "DB is linearizable", "no process crash between L88 and L90").
Every assumption is a place a real bug can hide. `proof-simplify` must not delete code
that only an assumption makes redundant, unless the assumption is enforced elsewhere.

## Granularity rule

One model step = one atomic region in the code:
- **async/await code:** the code between two `await` points (single-threaded event loops
  interleave only there),
- **locked code:** a critical section,
- **lock-free / threaded code without locks:** each shared read or write, each CAS,
- **distributed code:** each message handler, each timer firing, each crash point.
- **SQL:** one statement is atomic only at the isolation level actually in use. Model
  what the database really does:
  - Under READ COMMITTED, `UPDATE … WHERE id = (SELECT … LIMIT 1)` re-checks only the outer
    `WHERE` after a concurrent write. Two workers can then claim the same row, or re-open a
    row that another worker already finished.
  - `SELECT … FOR UPDATE` blocks only writers that also lock the row.

  Either model these semantics, or list them as an assumption and flag them in the report.

If the code splits a region the model treats as atomic, the model hides the race.
MongoDB's Raft conformance effort failed partly because the spec merged a step-down and a
step-up that the code performs separately. When in doubt, split. More interleavings
cost states, not correctness.

## Inline tags

In the model, tag each action with its source so the map can be rebuilt:
- TLA+: `\* src: src/cache.py:41-48`
- Lean: `/-- src: src/cache.py:41-48 -/` docstring on the def

`../scripts/correspondence_check.py` reads these tags and reports tags whose `file` is
missing or whose line range falls past the end of the file (a W6 drift signal).
