import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings

async def main():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        await conn.execute(
            text("ALTER TYPE orderstatus ADD VALUE IF NOT EXISTS 'awaiting_confirmation';")
        )

from sqlalchemy import text
asyncio.run(main())
