"""Payment webhook handler. The provider delivers each event at least once and
retries on timeout, so handling must be idempotent."""
from .stores import DedupStore, Gateway, Ledger


class PaymentWebhookHandler:
    def __init__(self, dedup: DedupStore, gateway: Gateway, ledger: Ledger):
        self.dedup = dedup
        self.gateway = gateway
        self.ledger = ledger

    async def handle(self, event: dict) -> str:
        event_id = event["id"]
        if await self.dedup.seen(event_id):
            return "duplicate"
        charge_id = await self.gateway.capture(event["payment_intent"], event["amount"])
        await self.ledger.record(event_id, charge_id)
        await self.dedup.mark(event_id)
        return "ok"
