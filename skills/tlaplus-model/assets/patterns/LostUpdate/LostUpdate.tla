---------------------------- MODULE LostUpdate ----------------------------
(* Pattern: check-then-act / read-modify-write on shared memory.            *)
(* Code shape:  x = counter; counter = x + 1   run by several threads.       *)
(* UseLock = FALSE reproduces the lost update; TRUE models the mutex fix.    *)
EXTENDS Naturals, FiniteSets

CONSTANTS Threads,  \* set of model values, e.g. {t1, t2}
          UseLock   \* BOOLEAN: the fix under test

NoOwner == "none"
VARIABLES counter, tmp, pc, lock
vars == <<counter, tmp, pc, lock>>

TypeOK ==
    /\ counter \in 0..Cardinality(Threads)
    /\ tmp \in [Threads -> 0..Cardinality(Threads)]
    /\ pc \in [Threads -> {"start", "read", "write", "done"}]
    /\ lock \in Threads \cup {NoOwner}

Init ==
    /\ counter = 0
    /\ tmp = [t \in Threads |-> 0]
    /\ pc = [t \in Threads |-> "start"]
    /\ lock = NoOwner

\* src: app/counter.py:10 (with lock:)
Acquire(t) ==
    /\ pc[t] = "start"
    /\ UseLock => lock = NoOwner
    /\ lock' = (IF UseLock THEN t ELSE lock)
    /\ pc' = [pc EXCEPT ![t] = "read"]
    /\ UNCHANGED <<counter, tmp>>

\* src: app/counter.py:11 (x = self.counter)
Read(t) ==
    /\ pc[t] = "read"
    /\ tmp' = [tmp EXCEPT ![t] = counter]
    /\ pc' = [pc EXCEPT ![t] = "write"]
    /\ UNCHANGED <<counter, lock>>

\* src: app/counter.py:12 (self.counter = x + 1; lock released at block end)
Write(t) ==
    /\ pc[t] = "write"
    /\ counter' = tmp[t] + 1
    /\ pc' = [pc EXCEPT ![t] = "done"]
    /\ lock' = (IF UseLock THEN NoOwner ELSE lock)
    /\ UNCHANGED tmp

Step == \E t \in Threads : Acquire(t) \/ Read(t) \/ Write(t)

\* Explicit termination so TLC's deadlock check stays on for real stuck states.
Terminated == (\A t \in Threads : pc[t] = "done") /\ UNCHANGED vars

Next == Step \/ Terminated
Spec == Init /\ [][Next]_vars /\ WF_vars(Step)

----------------------------------------------------------------------------
NoLostUpdate == (\A t \in Threads : pc[t] = "done") => counter = Cardinality(Threads)
MutEx == UseLock => \A a, b \in Threads :
            (a # b) => ~(pc[a] \in {"read", "write"} /\ pc[b] \in {"read", "write"})
AllFinish == <>(\A t \in Threads : pc[t] = "done")

\* Sanity (must FAIL): proves the all-done state is reachable, so NoLostUpdate is not vacuous.
NeverAllDone == ~(\A t \in Threads : pc[t] = "done")
=============================================================================
