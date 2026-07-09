from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine

from app.core.config import settings

engine = create_async_engine(
    settings.database_url,
    echo=False,  # SQL echo hech qachon yoqilmaydi (prodda log toshqinini oldini oladi)
    pool_size=settings.db_pool_size,       # har worker uchun (env: DB_POOL_SIZE)
    max_overflow=settings.db_max_overflow, # env: DB_MAX_OVERFLOW
    pool_pre_ping=True,   # bog'lanish tirikligini tekshiradi (stale connection xatolarini oldini oladi)
    pool_recycle=1800,    # 30 daqiqada bog'lanishni yangilaydi
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

sync_engine = create_engine(
    settings.database_sync_url,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=1800,
    # Kichik pool — sync engine faqat notification/settings uchun ishlatiladi.
    # Async(15) + sync(5) = 20/worker × 3 = 60 < Postgres max_connections(200).
    pool_size=2,
    max_overflow=3,
)
sync_session = sessionmaker(sync_engine, class_=Session, expire_on_commit=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


def get_sync_db():
    db = sync_session()
    try:
        yield db
    finally:
        db.close()