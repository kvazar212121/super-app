"""Buyurtmalarni avtomatik yakunlash scheduleri.

HAQIQIY MUAMMO: prod serverda (hubservis.uz) bu scheduler har 5
daqiqada yiqilardi va loglarda 6884 marta takrorlangan edi:

    Error in order completion scheduler: greenlet_spawn has not been
    called; can't call await_only() here.

Sabab: `run_completion_checks` da `order.provider` LAZY bog'lanish
o'qiladi. Async kontekstda uni oldindan yuklamasdan o'qib bo'lmaydi.
Natijada butun tekshiruv birinchi buyurtmadayoq to'xtardi, ya'ni:
  - ustaga "ishni yakunladingizmi?" eslatmasi bormasdi
  - 24 soatdan keyin buyurtma avtomatik yakunlanmasdi
  - komissiya yechilmasdi

Bu test HAQIQIY PostgreSQL bilan ishlaydi.
"""
import asyncio
import os
import sys
from datetime import datetime, timedelta, timezone

DB = os.environ.get("SUPERAPP_TEST_DB")
if not DB:
    print("SKIP: SUPERAPP_TEST_DB berilmagan (haqiqiy PostgreSQL kerak)")
    sys.exit(0)

BACKEND = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend"
)
sys.path.insert(0, BACKEND)
os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from sqlalchemy import text
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.category import Category
    from app.models.order import Order, OrderStatus
    from app.models.provider import Provider
    from app.models.user import User
    from app.services.order_service import OrderService

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    now = datetime.now(timezone.utc).replace(tzinfo=None)

    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        client = User(name="Mijoz", surname="T", phone="+998900001111",
                      hashed_password=hash_password("parol123"))
        owner = User(name="Usta", surname="T", phone="+998900002222",
                     hashed_password=hash_password("parol123"))
        db.add_all([cat, client, owner])
        await db.flush()

        prov = Provider(category_id=cat.id, name="Usta A", address="T",
                        phone="+998900003333", owner_user_id=owner.id)
        db.add(prov)
        await db.flush()

        # (a) 2 soatdan oshgan, eslatma yuborilishi kerak
        db.add(Order(user_id=client.id, provider_id=prov.id,
                     category_id=cat.id, status=OrderStatus.confirmed,
                     date=now - timedelta(hours=3), price=100000,
                     service_name="Rozetka almashtirish", address="Toshkent"))
        # (b) 24 soatdan oshgan, avtomatik yakunlanishi kerak
        db.add(Order(user_id=client.id, provider_id=prov.id,
                     category_id=cat.id,
                     status=OrderStatus.awaiting_confirmation,
                     date=now - timedelta(hours=30), price=200000,
                     service_name="Simlarni tortish", address="Toshkent"))
        await db.commit()
        prov_id = prov.id

    # ── ASOSIY TEKSHIRUV ──────────────────────────────────────────────
    # Tuzatishdan oldin bu chaqiruv MissingGreenlet bilan yiqilardi.
    async with async_session() as db:
        try:
            await OrderService.run_completion_checks(db)
            await db.commit()
            check("scheduler xatosiz ishlaydi (MissingGreenlet yo'q)", True)
        except Exception as e:
            msg = str(e)
            check("scheduler xatosiz ishlaydi (MissingGreenlet yo'q)",
                  False, msg[:200])
            if "greenlet" in msg.lower():
                print("\n>>> Aynan prod serverdagi xato takrorlandi <<<\n")

    # ── NATIJA HAQIQATAN QO'LLANDIMI ─────────────────────────────────
    async with async_session() as db:
        from sqlalchemy import select
        rows = (await db.execute(select(Order).order_by(Order.id))).scalars().all()
        statuses = [r.status for r in rows]
        check("24 soatlik buyurtma avtomatik yakunlandi",
              OrderStatus.completed in statuses, f"{statuses}")
        check("2 soatlik buyurtma hali yakunlanmagan (faqat eslatma)",
              statuses[0] == OrderStatus.confirmed, f"{statuses}")

        prov = await db.get(Provider, prov_id)
        check("yakunlangan buyurtma provayder hisobiga qo'shildi",
              prov.completed_orders_count == 1,
              f"{prov.completed_orders_count}")

    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")


asyncio.run(main())
