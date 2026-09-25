/-!
# Graph: reachability, acyclicity, and topological order by certificate checking

Rather than proving the production topological sort correct, prove a small *checker*
correct and run it on the production output. If `checkRank g rank = true`, then `g` is
acyclic and `rank` orders every path. This is verification-guided development (as with
AWS Cedar): the fast code stays untrusted, and the checker is trusted and tiny.
-/
namespace ProofPatterns.Graph

abbrev G := List (Nat × Nat)
def Edge (g : G) (u v : Nat) : Prop := (u, v) ∈ g

/-- Untrusted code (for example, the production topo-sort) produces a rank; Lean checks it. -/
def checkRank (g : G) (rank : Nat → Nat) : Bool := g.all fun (u, v) => rank u < rank v

theorem path_increases (g : G) (rank : Nat → Nat) (hc : checkRank g rank = true)
    (h : Relation.TransGen (Edge g) u v) : rank u < rank v := by
  simp only [checkRank, List.all_eq_true] at hc
  induction h with
  | single e => exact of_decide_eq_true (hc _ e)
  | tail _ e ih => have := of_decide_eq_true (hc _ e); simp only at this; omega

theorem acyclic_of_check (hc : checkRank g rank = true) :
    ∀ v, ¬ Relation.TransGen (Edge g) v v :=
  fun _ h => Nat.lt_irrefl _ (path_increases g rank hc h)

/-- Topological order → rank (index in the order). -/
def rankOf (order : List Nat) (v : Nat) : Nat := order.idxOf v

example : checkRank [(1,2),(2,3),(1,3)] (rankOf [1,2,3]) = true := by decide
example : checkRank [(1,2),(2,1)] (rankOf [1,2]) = false := by decide

/-- Executable reachability with fuel (for `#eval` and bounded checks). -/
def reachable (g : G) (fuel : Nat) (frontier seen : List Nat) : List Nat :=
  match fuel, frontier with
  | 0, _ | _, [] => seen
  | f + 1, v :: rest =>
    let succ := (g.filter (·.1 == v)).map (·.2) |>.filter (· ∉ seen)
    reachable g f (rest ++ succ) (seen ++ succ)

#eval reachable [(1,2),(2,3),(3,1),(4,5)] 100 [1] [1]   -- [1, 2, 3]

end ProofPatterns.Graph
