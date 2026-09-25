"""Tiny stand-in for the orders table. `update_where` is one atomic SQL statement:
UPDATE orders SET status = :new WHERE id = :id AND status = :expected."""
import threading


class OrdersDB:
    def __init__(self):
        self._rows: dict[str, str] = {}
        self._mu = threading.Lock()        # models the database's own statement atomicity
        self.row_locks: dict[str, threading.Lock] = {}

    def insert(self, order_id: str, status: str = "pending") -> None:
        with self._mu:
            self._rows[order_id] = status
            self.row_locks[order_id] = threading.Lock()

    def get(self, order_id: str) -> str:
        with self._mu:
            return self._rows[order_id]

    def update_where(self, order_id: str, expected: str, new: str) -> bool:
        with self._mu:
            if self._rows[order_id] != expected:
                return False
            self._rows[order_id] = new
            return True
