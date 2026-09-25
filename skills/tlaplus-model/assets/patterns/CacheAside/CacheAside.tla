---------------------------- MODULE CacheAside ----------------------------
(* Pattern: async/await event loop, cache-aside fill racing an invalidation. *)
(* Each action is one await-free block: interleaving happens only at awaits. *)
(* UseLease = TRUE models memcache-style leases: invalidation bumps a         *)
(* generation and a fill is dropped if its lease is stale.                   *)
EXTENDS Integers

CONSTANTS Readers, UseLease
None == -1
VARIABLES db, cache, gen, rpc, rval, rtok, wpc
vars == <<db, cache, gen, rpc, rval, rtok, wpc>>

TypeOK ==
    /\ db \in 0..1 /\ cache \in {None, 0, 1} /\ gen \in 0..1
    /\ rpc \in [Readers -> {"idle", "fill", "done"}]
    /\ wpc \in {"idle", "inval", "done"}

Init ==
    /\ db = 0 /\ cache = None /\ gen = 0 /\ wpc = "idle"
    /\ rpc = [r \in Readers |-> "idle"]
    /\ rval = [r \in Readers |-> 0]
    /\ rtok = [r \in Readers |-> 0]

\* src: app/cache.py:41-44 (miss: v = await db.get(k))
RMiss(r) ==
    /\ rpc[r] = "idle" /\ cache = None
    /\ rval' = [rval EXCEPT ![r] = db]
    /\ rtok' = [rtok EXCEPT ![r] = gen]
    /\ rpc' = [rpc EXCEPT ![r] = "fill"]
    /\ UNCHANGED <<db, cache, gen, wpc>>

\* src: app/cache.py:45 (await cache.set(k, v))
RFill(r) ==
    /\ rpc[r] = "fill"
    /\ cache' = (IF UseLease /\ rtok[r] # gen THEN cache ELSE rval[r])
    /\ rpc' = [rpc EXCEPT ![r] = "done"]
    /\ UNCHANGED <<db, gen, rval, rtok, wpc>>

\* src: app/writer.py:30 (await db.put(k, v))
WWrite ==
    /\ wpc = "idle" /\ db' = db + 1 /\ wpc' = "inval"
    /\ UNCHANGED <<cache, gen, rpc, rval, rtok>>

\* src: app/writer.py:31 (await cache.delete(k))
WInval ==
    /\ wpc = "inval" /\ cache' = None /\ gen' = gen + 1 /\ wpc' = "done"
    /\ UNCHANGED <<db, rpc, rval, rtok>>

Next == WWrite \/ WInval \/ \E r \in Readers : RMiss(r) \/ RFill(r)
Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
\* Coherence only has to hold at rest: mid-flight staleness is expected.
Quiescent == wpc \in {"idle", "done"} /\ \A r \in Readers : rpc[r] # "fill"
NoStaleAtRest == (Quiescent /\ cache # None) => cache = db

\* Sanity (must FAIL): a fill after the write is reachable.
NeverFilledAfterWrite == ~(wpc = "done" /\ cache # None)
=============================================================================
