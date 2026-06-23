import asyncio
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from app.models.category import Category

engine = create_async_engine('postgresql+asyncpg://postgres:postgres@127.0.0.1:5432/superapp')

async def main():
    async with AsyncSession(engine) as session:
        result = await session.execute(select(func.count(Category.id)))
        count = result.scalar()
        print(f"Count: {count}")
        
        res2 = await session.execute(select(Category))
        cats = res2.scalars().all()
        for c in cats:
            print(c.key)

asyncio.run(main())
