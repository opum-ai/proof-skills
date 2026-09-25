"""Async storage clients. In production these wrap Postgres and the payment gateway;
here they are in-memory fakes with the same interface. Each call yields to the event
loop, like a real network round-trip."""
import asyncio


class DedupStore:
    def __init__(self):
        self._seen: set[str] = set()

    async def seen(self, event_id: str) -> bool:
        await asyncio.sleep(0)
        return event_id in self._seen

    async def mark(self, event_id: str) -> None:
        await asyncio.sleep(0)
        self._seen.add(event_id)


class Gateway:
    def __init__(self):
        self.captures: list[tuple[str, int]] = []

    async def capture(self, payment_intent: str, amount: int) -> str:
        await asyncio.sleep(0)
        self.captures.append((payment_intent, amount))
        return f"ch_{len(self.captures)}"


class Ledger:
    def __init__(self):
        self.rows: dict[str, str] = {}

    async def record(self, event_id: str, charge_id: str) -> None:
        await asyncio.sleep(0)
        self.rows[event_id] = charge_id
