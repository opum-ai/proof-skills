--------------------------- MODULE DagScheduler ---------------------------
(* Pattern: concurrent DAG executor, checked against EVERY DAG on Nodes.     *)
(* The initial state picks any acyclic edge set, so one TLC run covers all   *)
(* small graphs (3 nodes: 25 DAGs; 4 nodes: 543 DAGs).                      *)
(* ReadyWhenDone = FALSE is the classic bug: a task is dispatched once its  *)
(* predecessors have *started* (running or done) instead of *finished*.     *)
EXTENDS Naturals, FiniteSets

CONSTANTS Nodes, Workers, ReadyWhenDone

RECURSIVE Reach(_, _)
Reach(E, S) == LET S2 == S \cup {e[2] : e \in {x \in E : x[1] \in S}}
               IN IF S2 = S THEN S ELSE Reach(E, S2)
Acyclic(E) == \A e \in E : e[1] \notin Reach(E, {e[2]})
AllEdges == {e \in Nodes \X Nodes : e[1] # e[2]}

VARIABLES E, running, done
vars == <<E, running, done>>

Preds(t) == {e[1] : e \in {x \in E : x[2] = t}}

Init == E \in {G \in SUBSET AllEdges : Acyclic(G)} /\ running = {} /\ done = {}

\* src: scheduler/executor.py:61-70 (ready = [t for t in pending if deps_satisfied(t)])
Dispatch(t) ==
    /\ t \notin running \cup done
    /\ Cardinality(running) < Workers
    /\ Preds(t) \subseteq (IF ReadyWhenDone THEN done ELSE done \cup running)
    /\ running' = running \cup {t}
    /\ UNCHANGED <<E, done>>

\* src: scheduler/executor.py:75 (on_complete callback)
Finish(t) ==
    /\ t \in running
    /\ running' = running \ {t} /\ done' = done \cup {t}
    /\ UNCHANGED E

Next == (\E t \in Nodes : Dispatch(t) \/ Finish(t)) \/ (done = Nodes /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(\E t \in Nodes : Dispatch(t) \/ Finish(t))

----------------------------------------------------------------------------
TypeOK == E \subseteq AllEdges /\ running \subseteq Nodes /\ done \subseteq Nodes
DepsRespected == \A t \in running : Preds(t) \subseteq done
RunsOnce == running \cap done = {}
AllComplete == <>(done = Nodes)

\* Sanity (must FAIL): some graph with an edge is actually explored and run.
NeverRunsDependent == ~(\E t \in done : Preds(t) # {})
=============================================================================
