"""aiohttp-style entry point: every incoming delivery is handled in its own task."""
import asyncio
from .payments import PaymentWebhookHandler


async def serve(handler: PaymentWebhookHandler, deliveries: list[dict]) -> list[str]:
    return await asyncio.gather(*(handler.handle(d) for d in deliveries))
