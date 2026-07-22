"""Admin balans/premium endpointlari testi (SQLite in-memory)."""
import os, asyncio
from datetime import datetime as _DT, timezone, timedelta
os.environ.setdefault('DATABASE_URL', 'postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL', 'postgresql+psycopg2://u:p@localhost/db')

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles


@compiles(JSONB, "sqlite")
def _compile_jsonb_sqlite(element, compiler, **kw):
    return "JSON"


from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.db.base import Base

import app.models  # noqa
import app.models.user, app.models.provider, app.models.order, app.models.transaction
import app.models.category, app.models.setting, app.models.review
from app.models.user import User
from app.models.transaction import Transaction

from app.api.v1.admin.users import (
    adjust_balance, grant_premium, BalanceAdjust, PremiumGrant,
)
from fastapi import HTTPException


async def main():
    _NOW = _DT(2026, 1, 1, 12, 0)
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with Session() as db:
        admin = User(name="Admin", surname="A", phone="+99800", hashed_password="x",
                     balance=0.0, is_admin=True, created_at=_NOW)
        user = User(name="Ali", surname="Vali", phone="+99891", hashed_password="x",
                    balance=10000.0, is_premium=False, created_at=_NOW)
        db.add(admin); db.add(user); await db.flush(); await db.commit()
        uid = user.id

        # ===== 1. Balans to'ldirish (+50000) =====
        out = await adjust_balance(uid, BalanceAdjust(amount=50000, description="test topup"), admin=admin, db=db)
        await db.commit()
        assert out.balance == 60000.0, f"FAIL topup: {out.balance}"
        txs = (await db.execute(sa.select(Transaction))).scalars().all()
        assert len(txs) == 1 and txs[0].type == "admin_topup" and float(txs[0].amount) == 50000, \
            f"FAIL tx: {[(t.type, float(t.amount)) for t in txs]}"
        print(f"OK 1: balans +50000 -> {out.balance}, tx=admin_topup 50000")

        # ===== 2. Balansdan yechish (-20000) =====
        out = await adjust_balance(uid, BalanceAdjust(amount=-20000), admin=admin, db=db)
        await db.commit()
        assert out.balance == 40000.0, f"FAIL deduct: {out.balance}"
        txs = (await db.execute(sa.select(Transaction))).scalars().all()
        assert any(t.type == "admin_deduct" and float(t.amount) == 20000 for t in txs), "FAIL deduct tx"
        print(f"OK 2: balans -20000 -> {out.balance}, tx=admin_deduct 20000")

        # ===== 3. Balans manfiy bo'la olmaydi =====
        try:
            await adjust_balance(uid, BalanceAdjust(amount=-999999), admin=admin, db=db)
            assert False, "FAIL: manfiy balansga ruxsat berildi"
        except HTTPException as e:
            assert e.status_code == 400
            print("OK 3: manfiy balans bloklandi (400)")

        # ===== 4. Premium berish (30 kun) =====
        await db.rollback()  # 3-testдаги xatoдан keyin sessiyani tozalaymiz
        out = await grant_premium(uid, PremiumGrant(is_premium=True, days=30), admin=admin, db=db)
        await db.commit()
        u2 = await db.get(User, uid)
        assert u2.is_premium is True, "FAIL: is_premium False"
        assert u2.premium_until is not None, "FAIL: premium_until None"
        # muddat ~30 kun keyin bo'lishi kerak (SQLite tz-naive saqlashi mumkin)
        pu = _as_aware(u2.premium_until)
        delta = pu - datetime_now_utc()
        assert timedelta(days=29) < delta < timedelta(days=31), f"FAIL muddat: {delta}"
        print(f"OK 4: premium berildi, is_premium=True, muddat={pu.date()}")

        # ===== 5. Premiumни uzaytirish (yana 30 kun mavjud muddat ustiga) =====
        prev_until = pu
        out = await grant_premium(uid, PremiumGrant(is_premium=True, days=30), admin=admin, db=db)
        await db.commit()
        u3 = await db.get(User, uid)
        pu3 = _as_aware(u3.premium_until)
        assert pu3 > prev_until, "FAIL: muddat uzaymadi"
        delta2 = pu3 - prev_until
        assert timedelta(days=29) < delta2 < timedelta(days=31), f"FAIL uzaytirish: {delta2}"
        print(f"OK 5: premium uzaytirildi, yangi muddat={pu3.date()}")

        # ===== 6. Premiumni bekor qilish =====
        out = await grant_premium(uid, PremiumGrant(is_premium=False, days=0), admin=admin, db=db)
        await db.commit()
        u4 = await db.get(User, uid)
        assert u4.is_premium is False and u4.premium_until is None, \
            f"FAIL bekor: is_premium={u4.is_premium}, until={u4.premium_until}"
        print("OK 6: premium bekor qilindi, is_premium=False, muddat=None")

        # ===== 7. Premium BALANSGA tegmasligi kerak =====
        assert u4.balance == 40000.0, f"FAIL: premium balansni o'zgartirdi! {u4.balance}"
        print(f"OK 7: premium balansga tegmadi, balans={u4.balance}")

    print("\n=== BARCHA TESTLAR MUVAFFAQIYATLI ===")


def datetime_now_utc():
    return _DT.now(timezone.utc)


def _as_aware(dt):
    """SQLite tz-naive datetime'ни UTC-aware qiladi (solishtirish uchun)."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


if __name__ == "__main__":
    asyncio.run(main())
