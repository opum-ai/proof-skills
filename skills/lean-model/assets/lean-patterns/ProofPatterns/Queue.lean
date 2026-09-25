import ProofPatterns.Explore

/-!
# Queue: FIFO channel, with no loss, reordering, or duplication

The invariant `recvd ++ chan = sent` says every message sent is either delivered, in order,
or still in flight. Model lossy or duplicating channels as extra constructors. The
invariant then fails, which tells you what the consumer must tolerate.
-/
namespace ProofPatterns.Queue
open Explore

structure S (α : Type) where
  sent  : List α := []
  chan  : List α := []
  recvd : List α := []

inductive Step : S α → S α → Prop
  | send (m : α) : Step s { s with sent := s.sent ++ [m], chan := s.chan ++ [m] }
  | recv : s.chan = m :: rest → Step s { s with chan := rest, recvd := s.recvd ++ [m] }

def Inv (s : S α) : Prop := s.recvd ++ s.chan = s.sent

theorem inv_step (h : Inv s) (hs : Step s s') : Inv s' := by
  cases hs with
  | send => simp_all [Inv, ← List.append_assoc]
  | recv hc => simp_all [Inv]

/-- Delivered messages are always a prefix of sent messages, in order. -/
theorem recvd_prefix (h : Reach Step ({} : S α) s) : s.recvd <+: s.sent := by
  have hi : Inv s := Reach.inv Inv (by simp [Inv]) (fun _ _ hi hs => inv_step hi hs) h
  exact ⟨s.chan, hi⟩

end ProofPatterns.Queue
