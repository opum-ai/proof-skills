# Counterexample → failing test → fix

A counterexample is a *claim* about the code. Reproduce it before believing it. The best
published pipeline (Specula, 2026) reproduced 98.5% of reported bugs with timing-controlled
tests and had zero false positives *because* it required reproduction.

## 1. Minimize the trace

- TLC BFS already returns a shortest trace. With simulation or DFS, re-run BFS at
  the depth where it failed, or shrink the constants (fewer workers or keys).
- Drop stuttering and irrelevant actors: which steps change variables the violated
  property reads?
- Write the story in domain terms, one line per step, with the CORRESPONDENCE.md code location.

## 2. Force the interleaving in real code

Pick the lightest control that makes the schedule deterministic:

| Runtime | Technique |
|---|---|
| Python asyncio | `asyncio.Event` gates inside mocks/fakes at the modeled `await` points; run with a single loop; `pytest-asyncio` |
| Python threads | `threading.Barrier`/`Event` injected via a hook or monkeypatch at the modeled step |
| JS/TS (Node) | Deferred promises (`let release; const gate = new Promise(r => release = r)`) inside fakes; `vi.useFakeTimers()`/`jest.useFakeTimers()` for timers |
| Go | Channels as gates in fakes; `-race` flag; `testing/synctest` (Go 1.24+) for deterministic time |
| Java/Kotlin | `CountDownLatch`/`CyclicBarrier` in fakes; `jcstress` for memory-model races; Lincheck for linearizability |
| Rust | `loom` for exhaustive thread interleavings of small tests; `tokio::time::pause()`; `shuttle` for randomized schedules |
| C/C++ | Barriers via test hooks; ThreadSanitizer; `rr` to record and replay |
| Distributed / services | Fault-injecting fakes (drop/duplicate/reorder/delay), controllable clocks, Testcontainers + toxiproxy; one test per trace |
| DB transactions | Two connections, explicit `BEGIN`, interleave statements by hand in the test at the chosen isolation level |

Put the gate at the *exact* boundary that the model treats as the action boundary. If
the code gives no seam there, add a minimal test hook, or use a fake of the dependency the
code awaits on.

The test asserts the *property* that the model violated (for example, "cache equals DB at rest"),
not incidental details. Name it after the finding: `test_F1_stale_cache_after_concurrent_invalidate`.

## 3. Verdicts

- **Confirmed:** the test fails on current code for the reason in the trace.
- **Suspected:** the test cannot be forced yet (no seam, needs infrastructure). Say why, and
  give the trace. Do not count it as a bug in summaries.
- **Refuted:** the code prevents the trace (the model missed a guard or merged steps wrongly).
  Fix the model, update CORRESPONDENCE.md, and re-check. Record this as a model fix, not a finding.

## 4. Fix

1. Choose the fix by mechanism, not by symptom:
   - make a region atomic (lock, transaction, CAS),
   - add a version or fencing token,
   - reorder the write and the side effect (for example, record the dedup key *before* the side effect),
   - make the operation idempotent,
   - invalidate after the write, or delay-delete, or use versioned fills.
2. Mirror the fix in the model. Re-run all properties, not only the one that failed. Fixes often
   break liveness (a lock added for safety can deadlock).
3. **Mutation-check:** revert the fix in the model only (for example, behind a `BugFixEnabled`
   constant) and confirm the property fails again. This proves the property guards the bug.
4. The failing test now passes. Keep it.
5. One finding per commit/PR when possible. The PR description gives the trace story,
   the property, the test, and the model evidence.
