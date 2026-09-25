import asyncio
from app.payments import PaymentWebhookHandler
from app.stores import DedupStore, Gateway, Ledger


def make():
    return PaymentWebhookHandler(DedupStore(), Gateway(), Ledger())


def test_single_delivery_captures_once():
    h = make()
    assert asyncio.run(h.handle({"id": "evt_1", "payment_intent": "pi_1", "amount": 500})) == "ok"
    assert h.gateway.captures == [("pi_1", 500)]


def test_redelivery_is_ignored():
    h = make()
    ev = {"id": "evt_1", "payment_intent": "pi_1", "amount": 500}
    asyncio.run(h.handle(ev))
    assert asyncio.run(h.handle(ev)) == "duplicate"
    assert len(h.gateway.captures) == 1
