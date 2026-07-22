import os, asyncio
from datetime import datetime as _DT
os.environ.setdefault('DATABASE_URL','postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL','postgresql+psycopg2://u:p@localhost/db')

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles

# SQLite JSONB'ni bilmaydi — testда JSON sifatida render qilamiz
@compiles(JSONB, "sqlite")
def _compile_jsonb_sqlite(element, compiler, **kw):
    return "JSON"

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.db.base import Base

# Import all models so metadata is complete
import app.models  # noqa
import app.models.user, app.models.provider, app.models.order, app.models.transaction
import app.models.category, app.models.setting, app.models.review
from app.models.user import User
from app.models.provider import Provider
from app.models.category import Category
from app.models.order import Order, OrderStatus
from app.models.transaction import Transaction
from app.models.setting import PlatformSetting
from app.services.order_service import OrderService

async def main():
    _NOW = _DT(2026,1,1,12,0)
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with Session() as db:
        # default_lead_fee = 7000
        db.add(PlatformSetting(key="default_lead_fee", value="7000", description="x"))
        owner = User(name="Prov", surname="Owner", phone="+99890", hashed_password="x", balance=20000.0, created_at=_NOW)
        db.add(owner); await db.flush()
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        db.add(cat); await db.flush()
        prov = Provider(category_id=cat.id, name="Usta", address="Tosh", phone="+99800", owner_user_id=owner.id, is_active=True, lead_fee=None)
        db.add(prov); await db.flush()
        client = User(name="Cli", surname="Ent", phone="+99891", hashed_password="x", balance=0.0, created_at=_NOW)
        db.add(client); await db.flush()

        order = Order(user_id=client.id, category_id=cat.id, provider_id=prov.id,
                      service_name="Ish", address="Tosh", date=_DT(2026,1,1,12,0), price=100000,
                      status=OrderStatus.pending, created_at=_NOW)
        db.add(order); await db.flush()
        await db.commit()

        # 1. Order yaratildi -> lead fee OLINMASLIGI kerak (balans o'zgarmagan)
        await db.refresh(owner)
        assert owner.balance == 20000.0, f"FAIL: create deducted! balance={owner.balance}"
        cnt = await db.scalar(sa.select(sa.func.count(Transaction.id)))
        assert cnt == 0, f"FAIL: tx created on order create: {cnt}"
        print("OK 1: order yaratishда lead fee olinmadi, balans=20000")

        # 2. Order completed -> lead fee 7000 olinadi
        order.status = OrderStatus.completed
        await OrderService.process_commission(db, order)
        await db.commit()
        await db.refresh(owner)
        assert owner.balance == 13000.0, f"FAIL: expected 13000 got {owner.balance}"
        txs = (await db.execute(sa.select(Transaction))).scalars().all()
        assert len(txs) == 1 and txs[0].type=="lead_fee" and float(txs[0].amount)==-7000, f"FAIL tx: {[(t.type,float(t.amount)) for t in txs]}"
        print(f"OK 2: yakunlanganda 7000 yechildi, balans={owner.balance}, tx=lead_fee -7000")

        # 3. IDEMPOTENT: qayta chaqirilsa ikki marta yechmasin
        await OrderService.process_commission(db, order)
        await db.commit()
        await db.refresh(owner)
        assert owner.balance == 13000.0, f"FAIL idempotency: {owner.balance}"
        cnt = await db.scalar(sa.select(sa.func.count(Transaction.id)))
        assert cnt == 1, f"FAIL: duplicate tx: {cnt}"
        print(f"OK 3: idempotent — qayta chaqirilganда yechilmadi, balans={owner.balance}, tx soni=1")

        # 4. provider.lead_fee ustunlik qiladi (default o'rniga)
        owner2 = User(name="P2", surname="O2", phone="+99892", hashed_password="x", balance=50000.0, created_at=_NOW)
        db.add(owner2); await db.flush()
        prov2 = Provider(category_id=cat.id, name="Usta2", address="Tosh", phone="+99801", owner_user_id=owner2.id, is_active=True, lead_fee=12000.0)
        db.add(prov2); await db.flush()
        order2 = Order(user_id=client.id, category_id=cat.id, provider_id=prov2.id,
                       service_name="Ish2", address="T", date=_DT(2026,1,1,12,0), price=200000, status=OrderStatus.completed, created_at=_NOW)
        db.add(order2); await db.flush()
        await OrderService.process_commission(db, order2)
        await db.commit(); await db.refresh(owner2)
        assert owner2.balance == 38000.0, f"FAIL provider fee: {owner2.balance}"
        print(f"OK 4: provider.lead_fee=12000 qo'llandi, balans={owner2.balance}")

    print("\\nBARCHA TESTLAR O'TDI ✅")

asyncio.run(main())
