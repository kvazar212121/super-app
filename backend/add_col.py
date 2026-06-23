import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

engine = create_async_engine(settings.database_url)

async def main():
    async with engine.begin() as conn:
        try:
            await conn.execute(text('ALTER TABLE promos ADD COLUMN image_url VARCHAR(500)'))
            print('Added image_url to promos')
        except Exception as e:
            print(e)

asyncio.run(main())
