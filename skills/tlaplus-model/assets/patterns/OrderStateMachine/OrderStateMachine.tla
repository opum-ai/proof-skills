------------------------- MODULE OrderStateMachine -------------------------
(* Pattern: a persisted state machine updated by concurrent handlers.       *)
(* The cancel handler reads the status, decides, then writes: a payment     *)
(* webhook can land in between, giving paid -> cancelled (money kept, order *)
(* cancelled). Checked with an ACTION property over allowed transitions.    *)
(* UseCAS = TRUE models the fix: UPDATE orders SET status='cancelled'        *)
(*                               WHERE id=? AND status='pending'             *)
EXTENDS Naturals

CONSTANTS UseCAS
States == {"pending", "paid", "shipped", "cancelled"}
Allowed == {<<"pending", "paid">>, <<"pending", "cancelled">>, <<"paid", "shipped">>}

VARIABLES status, cpc, cread
vars == <<status, cpc, cread>>

TypeOK == status \in States /\ cpc \in {"start", "decide", "done"} /\ cread \in States

Init == status = "pending" /\ cpc = "start" /\ cread = "pending"

\* src: api/webhooks.rb:12 (order.update!(status: :paid) if order.pending?)  -- atomic in SQL
Pay == status = "pending" /\ status' = "paid" /\ UNCHANGED <<cpc, cread>>
\* src: jobs/fulfil.rb:8
Ship == status = "paid" /\ status' = "shipped" /\ UNCHANGED <<cpc, cread>>

\* src: api/orders_controller.rb:40 (order = Order.find(id))
CancelRead == cpc = "start" /\ cread' = status /\ cpc' = "decide" /\ UNCHANGED status

\* src: api/orders_controller.rb:41-43 (if order.pending? then order.update!(status: :cancelled))
CancelWrite ==
    /\ cpc = "decide" /\ cread = "pending"
    /\ UseCAS => status = "pending"
    /\ status' = "cancelled" /\ cpc' = "done" /\ UNCHANGED cread

CancelSkip ==
    /\ cpc = "decide"
    /\ cread # "pending" \/ (UseCAS /\ status # "pending")
    /\ cpc' = "done" /\ UNCHANGED <<status, cread>>

Next == Pay \/ Ship \/ CancelRead \/ CancelWrite \/ CancelSkip
Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
\* Action property: every change of status is an allowed edge.
ValidTransitions == [][status' # status => <<status, status'>> \in Allowed]_vars

\* Sanity (must FAIL): cancellation is reachable at all.
NeverCancelled == status # "cancelled"
=============================================================================
