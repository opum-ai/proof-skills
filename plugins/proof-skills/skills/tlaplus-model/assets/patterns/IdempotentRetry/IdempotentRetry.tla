-------------------------- MODULE IdempotentRetry --------------------------
(* Pattern: at-least-once delivery + a dedup table.                         *)
(* Code shape:  if not seen(id): charge(); mark_seen(id)                     *)
(* Two deliveries of the same request are handled concurrently (retry after *)
(* a client timeout, or a broker redelivery). ClaimFirst = TRUE models the  *)
(* fix: INSERT ... ON CONFLICT DO NOTHING on the dedup key BEFORE the side  *)
(* effect, so the check and the claim are one atomic step.                   *)
EXTENDS Naturals, FiniteSets

CONSTANTS Deliveries,  \* copies of ONE logical request, e.g. {d1, d2}
          ClaimFirst
VARIABLES seen, applied, pc
vars == <<seen, applied, pc>>

TypeOK ==
    /\ seen \in BOOLEAN
    /\ applied \in 0..Cardinality(Deliveries)
    /\ pc \in [Deliveries -> {"recv", "apply", "record", "skip", "done"}]

Init == seen = FALSE /\ applied = 0 /\ pc = [d \in Deliveries |-> "recv"]

\* src: app/payments.py:52-53 (if await dedup.exists(req.id): return)
Check(d) ==
    /\ pc[d] = "recv"
    /\ IF seen
         THEN pc' = [pc EXCEPT ![d] = "skip"] /\ UNCHANGED seen
         ELSE /\ pc' = [pc EXCEPT ![d] = "apply"]
              /\ seen' = (IF ClaimFirst THEN TRUE ELSE seen)
    /\ UNCHANGED applied

\* src: app/payments.py:54 (await gateway.charge(req))
Apply(d) ==
    /\ pc[d] = "apply"
    /\ applied' = applied + 1
    /\ pc' = [pc EXCEPT ![d] = "record"]
    /\ UNCHANGED seen

\* src: app/payments.py:55 (await dedup.put(req.id))
Record(d) ==
    /\ pc[d] = "record"
    /\ seen' = TRUE
    /\ pc' = [pc EXCEPT ![d] = "done"]
    /\ UNCHANGED applied

Step == \E d \in Deliveries : Check(d) \/ Apply(d) \/ Record(d)
Terminated == (\A d \in Deliveries : pc[d] \in {"done", "skip"}) /\ UNCHANGED vars
Next == Step \/ Terminated
Spec == Init /\ [][Next]_vars /\ WF_vars(Step)

----------------------------------------------------------------------------
AtMostOnce == applied <= 1
EventuallyApplied == <>(applied = 1)          \* liveness: the request is not lost

\* Sanity (must FAIL): some delivery really takes the dedup (skip) path.
NobodySkips == \A d \in Deliveries : pc[d] # "skip"
=============================================================================
