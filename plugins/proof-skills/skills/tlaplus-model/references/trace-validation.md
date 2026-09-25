# Trace validation: replay real executions through the spec

Model checking asks "can the *model* go wrong?" Trace validation asks "did the *code* do
something the model forbids?" It is the strongest defense against spec drift. In the
Specula ablation (2026, 5 systems) the full pipeline with runtime trace feedback found 62
bugs; an agent that knew TLA+ but had no runtime feedback found 3.

Published use: Microsoft CCF (NSDI 2025, run in CI), etcd raft (`Traceetcdraft.tla`), and
the Cirstea/Kuppe/Loillier/Merz method (SEFM 2024). OmniLink (2026) extends it to
unmodified concurrent code by solving for an event order.

## Working example

`../assets/patterns/CacheAside/TraceCacheAside.tla`, with `Trace.cfg` and two logs:

```bash
cd assets/patterns/CacheAside
TRACE=trace-ok.ndjson    ../../../scripts/tlc.sh TraceCacheAside.tla --config Trace.cfg  # exit 0: accepted
TRACE=trace-drift.ndjson ../../../scripts/tlc.sh TraceCacheAside.tla --config Trace.cfg  # exit 10: rejected
```

`trace-drift.ndjson` logs a fill of value 1 after a miss that read 0. The spec says a fill
writes what the miss read, so TLC rejects it. That is either a code bug or a spec that
no longer matches the code. Both matter.

## Recipe

1. **Instrument the code.** At each point that corresponds to a spec action (the `src:`
   locations), emit one JSON line: `{"event": "<action>", "actor": "<id>", ...logged values}`.
   Log only the values the spec can check. Use the test or staging build, behind a flag.
2. **Order events.**
   - Single process: log order is fine.
   - Multi-threaded: take a global sequence number from an atomic counter at the linearization point.
   - Distributed: use a logical clock, or (as in etcd/CCF) log per node and merge by causal order.
3. **Write the trace spec:** `EXTENDS Spec, Json, IOUtils, TLC`, plus:
   - a variable `l` (the log index),
   - `TraceNext == l <= Len(Trace) /\ MatchEvent /\ l' = l + 1`,
   - `MatchEvent`, which pairs each event kind with its action *and* constrains primed
     variables to the logged values (`cache' = Ev.cache`),
   - `POSTCONDITION TraceAccepted`, which checks the search reached depth `Len(Trace) + 1`.
4. **Partial logs.** When the code cannot log some variable, leave it unconstrained; TLC
   searches over the possibilities. When some actions are not logged at all, allow
   `TraceNext` to take unlogged spec actions between logged events (bounded by a small
   stutter budget).
5. **Run it in CI** on logs from integration tests and chaos tests. A rejected trace is a
   finding: reproduce it, then decide whether it is a code bug or spec drift.

Classpath: `Json` and `IOUtils` come from `CommunityModules-deps.jar`. `setup_tla.sh`
installs it and `tlc.sh` adds it automatically.

## Model-based testing (the reverse direction)

Generate behaviors from the spec and drive the implementation with them:
- **Quint:** `quint run --mbt --out-itf=trace.itf.json --n-traces=50 spec.qnt`, then a small
  driver replays the ITF JSON against the code. `quint-connect` does this for Rust.
- **TLC:** `-simulate num=1000 -depth 40` with `-dumpTrace json`, or a `-generateSpecTE`
  trace, feeding a driver.
- MongoDB's experience: tests generated from the spec reached 100% branch coverage of the
  modeled code, against 21% for handwritten tests and 92% for AFL.
