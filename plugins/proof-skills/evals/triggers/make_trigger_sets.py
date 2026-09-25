"""Generate trigger-eval query sets (should_trigger true/false) for each proof-skills skill.

Run: python3 plugins/proof-skills/evals/triggers/make_trigger_sets.py   (writes <skill>.json next to this file)
"""
import json
import pathlib

HERE = pathlib.Path(__file__).parent

SETS = {
    "formal-verify": [
        ("we keep getting duplicate emails from our notification worker, maybe 1 in 5k sends. its a python asyncio thing in services/notify/sender.py that checks redis for a sent-key then sends then sets the key. can you figure out formally whether it can double send and fix it", True),
        ("Can this race? Two pods run `reconcile()` in controllers/quota.go at the same time and both read the current usage from etcd before writing. I want a real answer, not a guess.", True),
        ("review PR #482 in our payments repo for concurrency issues — it changes the refund flow to use a background job and I'm nervous about double refunds", True),
        ("Our Kotlin inventory service sometimes oversells the last unit during flash sales. Stock check is `if (stock > 0) decrement()` in InventoryService.kt. Please model it and prove the fix.", True),
        ("I have a DAG runner in rust (crates/runner/src/sched.rs) that sometimes deadlocks when a task fails and gets retried. find out why with whatever formal tools make sense", True),
        ("before we build it: here's our design doc for leader election with leases in Postgres (docs/rfc/017-leader.md). check whether two leaders can ever be active at once", True),
        ("the spec in formal/cache-coherence/ was written 4 months ago and a bunch of code in cache/ changed since. is the model still accurate?", True),
        ("set up CI so the TLA+ models under specs/ run on every PR and fail the build if an invariant breaks", True),
        ("is `TokenBucket.take()` in lib/ratelimit.ts thread safe? it's called from worker_threads and I'm seeing more requests through than the limit allows", True),
        ("we lose messages occasionally in our kafka -> transform -> s3 pipeline when a pod restarts mid-batch. code is in pipeline/sink.py. help me find exactly where with a formal model", True),
        ("write a function that checks whether a directed graph has a cycle, in python, with tests", False),
        ("explain the difference between linearizability and serializability with examples", False),
        ("my pytest suite is flaky on CI only — tests/test_api.py::test_upload times out randomly. can you look at the fixture setup?", False),
        ("add a mutex around the counter in metrics.go so the race detector stops complaining", False),
        ("our postgres queries got slow after the last migration, EXPLAIN ANALYZE output attached, what index should I add", False),
        ("convert this Go worker pool to use errgroup instead of manual waitgroups", False),
        ("write hypothesis property-based tests for my JSON parser in parser/json.py", False),
        ("what's the best way to learn TLA+? recommend books or courses", False),
        ("design a rate limiter for our API gateway, sliding window, redis backed — just the architecture, we'll implement later", False),
        ("fix the type errors in src/scheduler.ts after upgrading to typescript 6", False),
    ],
    "tlaplus-model": [
        ("TLC says 'Error: Invariant NoDoubleSpend is violated.' and dumps a trace: State 1: <Initial predicate> bal = 10 /\\ pc = [a |-> \"read\", b |-> \"read\"]  State 2: <ReadA> seenA = 10  State 3: <ReadB> seenB = 10  State 4: <WriteA> bal = 0 /\\ spent = 10  State 5: <WriteB> bal = 0 /\\ spent = 20. what is actually happening in this trace and is it a real bug?", True),
        ("write a TLA+ spec for our two-phase commit coordinator (coordinator.py + participant.py) with crash failures and check atomicity", True),
        ("my .tla file won't parse, SANY says 'Could not find declaration or definition of symbol -.' on line 4", True),
        ("model this in PlusCal: three workers pull from a shared queue with visibility timeouts, a message can be redelivered if the ack is late", True),
        ("liveness property EventuallyAllAcked fails in TLC with a stuttering counterexample even though every worker should keep running — what fairness am I missing", True),
        ("can you write a quint spec for our CRDT counter merge and run the simulator to look for a divergence", True),
        ("TLC has been running for 3 hours on my raft spec with 5 servers and hasn't finished, how do I make the state space manageable", True),
        ("use apalache to prove my invariant is inductive instead of just model checking small instances", True),
        ("exhaustively check how our saga orchestrator behaves if any compensating step fails or is retried — interleavings matter here", True),
        ("I want to replay our production event logs through the spec to see if the implementation ever does something the spec forbids", True),
        ("prove in Lean that my merge sort returns a permutation of its input", False),
        ("write unit tests for the retry decorator in utils/retry.py", False),
        ("draw a sequence diagram of our OAuth login flow for the onboarding doc", False),
        ("what's the time complexity of Dijkstra with a binary heap", False),
        ("explain what a vector clock is", False),
        ("convert our Terraform modules to OpenTofu", False),
        ("set up a Jepsen test harness for our etcd cluster", False),
        ("fix the deadlock the Go race detector reported in cmd/server/main.go line 88 — the lock order is obvious from the stack trace", False),
        ("write a state machine for the order checkout flow in XState for our React app", False),
        ("review my Alloy model of the file permission system", False),
    ],
    "lean-model": [
        ("prove in Lean that our interval merge function in lib/intervals.py never loses coverage — I'll accept a model of it, just keep the model faithful", True),
        ("TLC passed for 3 nodes but I need a proof that the leader lease invariant holds for any number of nodes. can we do that in Lean?", True),
        ("my lean proof is stuck: grind fails on the dispatch case of inv_step and leaves a goal with an awaiting task whose key isn't in seen. what do I do", True),
        ("build an executable Lean model of our pricing rules engine and differential-test it against the production Java implementation", True),
        ("lake build succeeds but I want to make sure there's no sorry or sneaky axiom anywhere in formal/lean before we claim it's verified", True),
        ("prove that the topological sort in scheduler/topo.rs always produces an order consistent with the edges, for every DAG", True),
        ("set up a Lean 4 project (no mathlib please, it's huge) for modeling our state machine and proving transitions stay within the allowed table", True),
        ("model the retry logic in our webhook dispatcher as a transition system in Lean and prove at-most-once delivery by induction", True),
        ("use lean to find a counterexample input for my batching function — i suspect it loses the last partial batch", True),
        ("check this Lean proof uses native_decide and tell me whether that's acceptable for our certification claim", True),
        ("help me with my real analysis homework in Lean mathlib — epsilon delta continuity proof", False),
        ("write a TLA+ spec for the paxos acceptor", False),
        ("what's the difference between Coq and Isabelle", False),
        ("install the Lean VS Code extension on my windows laptop", False),
        ("write a python function that checks if a list is sorted and add doctests", False),
        ("formalize the proof that there are infinitely many primes", False),
        ("refactor the rust borrow checker errors in src/graph.rs", False),
        ("translate this Haskell code to Lean syntax, it's a parser combinator library", False),
        ("prove in Dafny that my binary search is correct", False),
        ("explain dependent types like I'm a backend engineer", False),
    ],
    "proof-simplify": [
        ("we have a TLA+ model of our job leasing that passes. there's a lot of defensive code in worker/lease.go — double checks of ownership, a second lock. can we use the model to delete what's redundant?", True),
        ("do we still need the mutex in CacheWarmer.refresh()? the spec in formal/cache/ says only the scheduler thread ever calls it", True),
        ("cancel_order has a row lock, a conditional update and a post check. use formal methods to figure out what we can safely remove", True),
        ("our Lean proof shows the `pending` and `queued` states behave identically — can we merge them in the OrderStatus enum and delete the transitions between them?", True),
        ("the invariant says claimed_by is non-null iff status == CLAIMED. can we encode that in the types and delete the runtime checks scattered around jobs/*.py?", True),
        ("simplify the retry loop in sync/replicator.ts — I think half the branches can't happen but I want proof before I delete anything", True),
        ("after the bug hunt last week our webhook handler has both a dedup claim and an idempotency key. the model says the key alone is enough — should we remove the claim and how do we prove it's safe", True),
        ("is the `if already_applied: return` guard in apply_migration() dead code given the proven invariant in formal/migrations/Properties.lean?", True),
        ("refactor this 400 line function into smaller functions, keep behavior identical", False),
        ("remove unused imports and dead functions across the repo — just use the linter", False),
        ("simplify this SQL query, it has three nested subqueries", False),
        ("delete the feature flag `new_checkout` and its code paths, it's been at 100% for months", False),
        ("find race conditions in our payment processor", False),
        ("write a TLA+ spec for our cache", False),
        ("make this Python code more idiomatic and shorter", False),
        ("our CI is slow, which tests can we delete?", False),
        ("prove my sorting function is correct in Lean", False),
        ("clean up the error handling in api/handlers.go, there's too much copy paste", False),
        ("is it safe to remove the retry around the S3 upload? we've never seen it fail", False),
        ("reduce the number of locks in our Java connection pool for performance — benchmark it", False),
    ],
}

if __name__ == "__main__":
    for name, items in SETS.items():
        out = [{"query": q, "should_trigger": t} for q, t in items]
        (HERE / f"{name}.json").write_text(json.dumps(out, indent=2) + "\n")
        print(name, sum(t for _, t in items), "positive /", sum(not t for _, t in items), "negative")
