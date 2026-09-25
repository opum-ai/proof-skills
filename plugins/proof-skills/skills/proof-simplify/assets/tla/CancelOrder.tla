---------------------------- MODULE CancelOrder ----------------------------
(* CURRENT code: cancel takes a row lock (SELECT ... FOR UPDATE) AND uses a *)
(* conditional UPDATE ... WHERE status='pending'. The payment webhook does   *)
(* an atomic conditional UPDATE and never takes the lock.                   *)
(* Question for proof-simplify: which of the two protections is doing work? *)
EXTENDS Naturals

CONSTANTS UseLock, UseCAS
States == {"pending", "paid", "shipped", "cancelled"}
Allowed == {<<"pending", "paid">>, <<"pending", "cancelled">>, <<"paid", "shipped">>}

VARIABLES status, cpc, cread, lock
vars == <<status, cpc, cread, lock>>

Init == status = "pending" /\ cpc = "start" /\ cread = "pending" /\ lock = "free"

\* src: api/webhooks.rb:12 (UPDATE orders SET status='paid' WHERE id=? AND status='pending')
Pay  == status = "pending" /\ status' = "paid" /\ UNCHANGED <<cpc, cread, lock>>
\* src: jobs/fulfil.rb:8
Ship == status = "paid" /\ status' = "shipped" /\ UNCHANGED <<cpc, cread, lock>>

\* src: api/orders_controller.rb:39-40 (Order.lock.find(id))
CancelRead ==
    /\ cpc = "start"
    /\ UseLock => lock = "free"
    /\ lock' = (IF UseLock THEN "cancel" ELSE lock)
    /\ cread' = status /\ cpc' = "decide" /\ UNCHANGED status

\* src: api/orders_controller.rb:41-43 (update where status='pending'; commit releases lock)
CancelWrite ==
    /\ cpc = "decide" /\ cread = "pending"
    /\ UseCAS => status = "pending"
    /\ status' = "cancelled" /\ cpc' = "done" /\ UNCHANGED cread
    /\ lock' = (IF UseLock THEN "free" ELSE lock)

CancelSkip ==
    /\ cpc = "decide"
    /\ cread # "pending" \/ (UseCAS /\ status # "pending")
    /\ cpc' = "done" /\ UNCHANGED <<status, cread>>
    /\ lock' = (IF UseLock THEN "free" ELSE lock)

Next == Pay \/ Ship \/ CancelRead \/ CancelWrite \/ CancelSkip
Spec == Init /\ [][Next]_vars

ValidTransitions == [][status' # status => <<status, status'>> \in Allowed]_vars
TypeOK == status \in States /\ lock \in {"free", "cancel"}
=============================================================================
