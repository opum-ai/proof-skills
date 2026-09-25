"""Order lifecycle: pending -> paid -> shipped, or pending -> cancelled.

INCIDENT-2291 (2025): an order was cancelled after it had been paid. We added the row lock
AND the conditional update below ("belt and braces"), plus the post-check.
"""
from .db import OrdersDB


class OrderService:
    def __init__(self, db: OrdersDB, refunds):
        self.db = db
        self.refunds = refunds

    # Called from the payment provider's webhook (separate worker pool).
    def mark_paid(self, order_id: str) -> bool:
        return self.db.update_where(order_id, "pending", "paid")

    def mark_shipped(self, order_id: str) -> bool:
        return self.db.update_where(order_id, "paid", "shipped")

    # Called from the customer-facing API.
    def cancel_order(self, order_id: str) -> str:
        with self.db.row_locks[order_id]:                  # SELECT ... FOR UPDATE
            status = self.db.get(order_id)
            if status != "pending":
                return f"cannot cancel: {status}"
            ok = self.db.update_where(order_id, "pending", "cancelled")
            if not ok:
                return "cannot cancel: changed concurrently"
            # post-check from INCIDENT-2291
            if self.db.get(order_id) != "cancelled":
                self.refunds.flag_for_review(order_id)
                return "error: inconsistent state"
            return "cancelled"
