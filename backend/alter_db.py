import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

async def main():
    engine = create_async_engine(settings.DATABASE_URL)
    async with engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE providers ADD COLUMN lead_fee DOUBLE PRECISION;"))
            print("Column added.")
        except Exception as e:
            print("Error or column already exists:", e)

asyncio.run(main())
