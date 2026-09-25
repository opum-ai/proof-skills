from orders.db import OrdersDB
from orders.service import OrderService


class Refunds:
    def __init__(self):
        self.flagged = []

    def flag_for_review(self, oid):
        self.flagged.append(oid)


def test_cancel_pending():
    db = OrdersDB(); db.insert("o1")
    assert OrderService(db, Refunds()).cancel_order("o1") == "cancelled"


def test_cannot_cancel_paid():
    db = OrdersDB(); db.insert("o1")
    svc = OrderService(db, Refunds())
    svc.mark_paid("o1")
    assert svc.cancel_order("o1").startswith("cannot cancel")
