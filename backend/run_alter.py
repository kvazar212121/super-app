import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings

async def main():
    engine = create_async_engine("postgresql+asyncpg://postgres:postgres@localhost:5434/superapp")
    async with engine.begin() as conn:
        from sqlalchemy import text
        try:
            await conn.execute(text("ALTER TABLE providers ADD COLUMN IF NOT EXISTS is_paused BOOLEAN DEFAULT FALSE;"))
            print("Column added successfully!")
        except Exception as e:
            print(f"Error adding column: {e}")
            
if __name__ == "__main__":
    asyncio.run(main())
