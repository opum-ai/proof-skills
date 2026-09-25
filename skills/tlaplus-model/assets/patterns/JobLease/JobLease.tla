------------------------------ MODULE JobLease ------------------------------
(* Pattern: lease-based job claiming with expiry (GC pause, slow worker).   *)
(* Code shape: worker claims a job row with a lease, works, then commits.    *)
(* A lease can expire while its holder still runs; another worker reclaims. *)
(* UseFencing = TRUE models the fix: commit is a compare-and-set on the      *)
(* claim token (UPDATE ... WHERE token = :mine), stale holders abort.       *)
EXTENDS Naturals, FiniteSets

CONSTANTS Workers, UseFencing, MaxClaims
None == "none"
VARIABLES owner, token, expired, jobDone, wpc, wtok, commits
vars == <<owner, token, expired, jobDone, wpc, wtok, commits>>

TypeOK ==
    /\ owner \in Workers \cup {None}
    /\ token \in 0..MaxClaims
    /\ expired \in BOOLEAN /\ jobDone \in BOOLEAN
    /\ wpc \in [Workers -> {"idle", "working", "done", "aborted"}]
    /\ wtok \in [Workers -> 0..MaxClaims]
    /\ commits \subseteq Workers

Init ==
    /\ owner = None /\ token = 0 /\ expired = FALSE /\ jobDone = FALSE
    /\ wpc = [w \in Workers |-> "idle"] /\ wtok = [w \in Workers |-> 0]
    /\ commits = {}

\* src: worker/claim.go:40-58 (UPDATE jobs SET owner=$1, lease_until=now()+ttl, token=token+1 ...)
Claim(w) ==
    /\ wpc[w] = "idle" /\ ~jobDone /\ token < MaxClaims
    /\ owner = None \/ expired
    /\ owner' = w /\ token' = token + 1 /\ expired' = FALSE
    /\ wtok' = [wtok EXCEPT ![w] = token + 1]
    /\ wpc' = [wpc EXCEPT ![w] = "working"]
    /\ UNCHANGED <<jobDone, commits>>

\* Environment: time passes / holder pauses. Not a code location.
Expire ==
    /\ owner # None /\ ~expired /\ ~jobDone
    /\ expired' = TRUE
    /\ UNCHANGED <<owner, token, jobDone, wpc, wtok, commits>>

\* src: worker/run.go:88-97 (tx.Exec("UPDATE jobs SET done=true ..."))
Commit(w) ==
    /\ wpc[w] = "working"
    /\ UseFencing => wtok[w] = token
    /\ commits' = commits \cup {w} /\ jobDone' = TRUE
    /\ wpc' = [wpc EXCEPT ![w] = "done"]
    /\ UNCHANGED <<owner, token, expired, wtok>>

\* src: worker/run.go:99 (rows affected == 0 -> ErrLeaseLost)
Abort(w) ==
    /\ wpc[w] = "working" /\ UseFencing /\ wtok[w] # token
    /\ wpc' = [wpc EXCEPT ![w] = "aborted"]
    /\ UNCHANGED <<owner, token, expired, jobDone, wtok, commits>>

Step == Expire \/ \E w \in Workers : Claim(w) \/ Commit(w) \/ Abort(w)
Next == Step \/ (jobDone /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ \A w \in Workers : WF_vars(Commit(w)) /\ WF_vars(Abort(w))

----------------------------------------------------------------------------
SingleCommit == Cardinality(commits) <= 1
\* Liveness: once someone holds a valid claim, the job gets done.
ClaimedEventuallyDone == (owner # None) ~> jobDone

\* Sanity (must FAIL): a reclaim after expiry is reachable.
NoReclaim == token <= 1
=============================================================================
