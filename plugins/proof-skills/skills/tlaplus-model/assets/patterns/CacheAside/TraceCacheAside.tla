-------------------------- MODULE TraceCacheAside --------------------------
(* Trace validation: replay an implementation log (ndjson, one event per    *)
(* line) through the CacheAside spec. TLC accepts the log only if every     *)
(* event matches an enabled action with the logged values. A rejected log   *)
(* means the code did something the spec says is impossible (drift or bug). *)
(* Run:  TRACE=trace-ok.ndjson tlc.sh TraceCacheAside.tla --config Trace.cfg *)
(* Needs CommunityModules-deps.jar (Json, IOUtils) on the classpath.         *)
EXTENDS CacheAside, Naturals, Sequences, Json, IOUtils, TLC

TraceFile == IF "TRACE" \in DOMAIN IOEnv THEN IOEnv.TRACE ELSE "trace-ok.ndjson"
Trace == ndJsonDeserialize(TraceFile)

VARIABLE l            \* index of the next log event to match
TVars == <<vars, l>>
Ev == Trace[l]

\* Each logged event must match one action AND the values it logged.
MatchEvent ==
    \/ Ev.event = "miss"  /\ RMiss(Ev.actor) /\ rval'[Ev.actor] = Ev.val
    \/ Ev.event = "fill"  /\ RFill(Ev.actor) /\ cache' = Ev.cache
    \/ Ev.event = "write" /\ WWrite /\ db' = Ev.val
    \/ Ev.event = "inval" /\ WInval

TraceInit == Init /\ l = 1
TraceNext == l <= Len(Trace) /\ MatchEvent /\ l' = l + 1
TraceSpec == TraceInit /\ [][TraceNext]_TVars

\* Checked once after exploration: some behavior consumed the whole log.
TraceAccepted ==
    LET d == TLCGet("stats").diameter IN
    IF d - 1 = Len(Trace) THEN TRUE
    ELSE Print(<<"Trace rejected at event", d, Trace[d]>>, FALSE)
=============================================================================
