"""Xaridor qidiruvi: filtr, saralash, valyuta va grid chegarasi.

Foydalanuvchi qarorlari shu yerda qo'riqlanadi:
    • RAG yo'q — oddiy filtrlar (toifa, narx, holat, hudud)
    • narx DOIM so'mda ko'rsatiladi (dollarli e'lon konvertatsiya qilinadi)
    • chatда 20 tagacha karta
    • o'z e'loningni sotib olmaysan (qidiruvda ko'rinmaydi)
    • muddati tugagan e'lon qidiruvga chiqmaydi
"""
import asyncio
import json
import os
import sys
import tempfile
from datetime import datetime, timedelta, timezone

DB = os.environ.get("SUPERAPP_TEST_DB")
_tmp = None
if not DB:
    _tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    _tmp.close()
    DB = f"sqlite+aiosqlite:///{_tmp.name}"

BACKEND = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend"
)
sys.path.insert(0, BACKEND)

# ⚠️ ISHCHI BAZAGA TEGMASLIK QO'RIQCHISI.
# Bu test `DROP SCHEMA public CASCADE` qiladi. Xato baza
# ko'rsatilsa butun ishchi ma'lumot o'chib ketardi (bu bir
# marta haqiqatan sodir bo'lgan).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_guard import guard as _db_guard  # noqa: E402
_db_guard(DB)
os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "").replace(
    "+aiosqlite", ""
)
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from sqlalchemy import text
    from sqlalchemy.dialects.postgresql import JSONB
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.marketplace import Listing, ListingCondition, ListingStatus
    from app.models.user import User
    from app.services.marketplace import currency, search_listings
    from app.services.marketplace.fields import resolve_category
    from app.services.marketplace.search import MAX_RESULTS

    # Tashqi CBU so'roviga bog'lanib qolmaslik uchun kursni qo'lda beramiz.
    currency.set_rates({"USD": 12000.0})

    async with engine.begin() as conn:
        if engine.dialect.name == "postgresql":
            await conn.execute(text("DROP SCHEMA public CASCADE"))
            await conn.execute(text("CREATE SCHEMA public"))
            await conn.run_sync(Base.metadata.create_all)
        else:
            mumkin = [
                t for t in Base.metadata.sorted_tables
                if not any(isinstance(c.type, JSONB) for c in t.columns)
            ]
            await conn.run_sync(Base.metadata.drop_all, tables=mumkin)
            await conn.run_sync(Base.metadata.create_all, tables=mumkin)

    now = datetime.now(timezone.utc)
    async with async_session() as db:
        sotuvchi = User(name="Sotuvchi", surname="T", phone="+998900001111",
                        hashed_password=hash_password("parol123"))
        xaridor = User(name="Xaridor", surname="T", phone="+998900002222",
                       hashed_password=hash_password("parol123"))
        db.add_all([sotuvchi, xaridor])
        await db.commit()
        sid, xid = sotuvchi.id, xaridor.id

        db.add_all([
            # Toshkent markazi (41.31, 69.24) atrofida
            Listing(user_id=sid, category_key="telefon",
                    title="iPhone 13 Pro", description="Ideal telefon",
                    price=4_500_000, currency="UZS",
                    condition=ListingCondition.like_new,
                    address="Toshkent", lat=41.31, lng=69.24,
                    status=ListingStatus.active,
                    expires_at=now + timedelta(days=7)),
            Listing(user_id=sid, category_key="telefon",
                    title="Redmi Note 12", description="Arzon telefon",
                    price=1_800_000, currency="UZS",
                    condition=ListingCondition.good,
                    address="Toshkent", lat=41.35, lng=69.28,
                    status=ListingStatus.active,
                    expires_at=now + timedelta(days=7)),
            # Dollarli e'lon: xaridorga SO'MDA ko'rinishi kerak
            Listing(user_id=sid, category_key="telefon",
                    title="Samsung S23", description="Dollarda narx",
                    price=500, currency="USD",
                    condition=ListingCondition.new,
                    address="Toshkent", lat=41.30, lng=69.25,
                    status=ListingStatus.active,
                    expires_at=now + timedelta(days=7)),
            Listing(user_id=sid, category_key="mebel",
                    title="Yumshoq divan", description="Yaxshi holatda",
                    price=2_000_000, currency="UZS",
                    condition=ListingCondition.good,
                    address="Toshkent", status=ListingStatus.active,
                    expires_at=now + timedelta(days=7)),
            # Muddati TUGAGAN — qidiruvda ko'rinmasligi kerak
            Listing(user_id=sid, category_key="telefon",
                    title="Eski Nokia", description="Muddati o'tgan e'lon",
                    price=200_000, currency="UZS",
                    condition=ListingCondition.used,
                    address="Toshkent", status=ListingStatus.active,
                    expires_at=now - timedelta(days=1)),
            # Sotilgan — ko'rinmaydi
            Listing(user_id=sid, category_key="telefon",
                    title="Sotilgan telefon", description="Allaqachon ketgan",
                    price=1_000_000, currency="UZS",
                    condition=ListingCondition.good,
                    address="Toshkent", status=ListingStatus.sold),
            # Xaridorning O'ZINIKI — o'z e'loni chiqmasligi kerak
            Listing(user_id=xid, category_key="telefon",
                    title="Mening telefonim", description="O'zimniki",
                    price=900_000, currency="UZS",
                    condition=ListingCondition.good,
                    address="Toshkent", status=ListingStatus.active,
                    expires_at=now + timedelta(days=7)),
        ])
        await db.commit()

    # ── 1. Toifa filtri ──────────────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, category="telefon",
                                    exclude_user_id=xid)
        nomlar = [r["title"] for r in res]
        check("toifa bo'yicha filtrlanadi",
              all("divan" not in n.lower() for n in nomlar), f"{nomlar}")
        check("muddati tugagan e'lon ko'rinmaydi",
              "Eski Nokia" not in nomlar, f"{nomlar}")
        check("sotilgan e'lon ko'rinmaydi",
              "Sotilgan telefon" not in nomlar, f"{nomlar}")
        check("o'z e'loni qidiruvda ko'rinmaydi",
              "Mening telefonim" not in nomlar, f"{nomlar}")
        check("faol telefonlar topiladi", len(nomlar) == 3, f"{nomlar}")

    # ── 2. Narx SO'MDA (dollarli e'lon konvertatsiya qilinadi) ───────
    async with async_session() as db:
        res = await search_listings(db, query="Samsung", exclude_user_id=xid)
        check("dollarli e'lon topildi", len(res) == 1, f"{res}")
        if res:
            check("narx so'mga aylantirildi (500$ × 12000)",
                  res[0]["price_uzs"] == 6_000_000, f"{res[0]['price_uzs']}")
            check("asl narx ham saqlanadi", res[0]["price"] == 500,
                  f"{res[0]['price']}")
            check("asl valyuta ko'rinadi", res[0]["currency"] == "USD",
                  f"{res[0]['currency']}")

    # ── 3. Narx oralig'i — SO'MDA solishtiriladi ─────────────────────
    async with async_session() as db:
        res = await search_listings(db, category="telefon", price_max=2_000_000,
                                    exclude_user_id=xid)
        nomlar = [r["title"] for r in res]
        check("narx chegarasi ishlaydi (faqat arzoni)",
              nomlar == ["Redmi Note 12"], f"{nomlar}")

        res = await search_listings(db, category="telefon", price_min=5_000_000,
                                    exclude_user_id=xid)
        nomlar = [r["title"] for r in res]
        check("dollarli e'lon so'mdagi chegara bo'yicha topiladi",
              nomlar == ["Samsung S23"], f"{nomlar}")

    # ── 4. Holat filtri ──────────────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, condition="new", exclude_user_id=xid)
        check("holat bo'yicha filtr",
              [r["title"] for r in res] == ["Samsung S23"], f"{res}")

        res = await search_listings(db, condition="yaroqsiz_qiymat",
                                    exclude_user_id=xid)
        check("noma'lum holat filtri natijani yo'q qilmaydi",
              len(res) >= 3, f"{len(res)}")

    # ── 5. Matn bo'yicha qidiruv ─────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, query="iPhone", exclude_user_id=xid)
        check("nom bo'yicha topiladi",
              [r["title"] for r in res] == ["iPhone 13 Pro"], f"{res}")

        res = await search_listings(db, query="arzon", exclude_user_id=xid)
        check("tavsif bo'yicha ham topiladi",
              [r["title"] for r in res] == ["Redmi Note 12"], f"{res}")

    # ── 6. Saralash: yaqinlik ────────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, category="telefon",
                                    lat=41.30, lng=69.25, exclude_user_id=xid)
        nomlar = [r["title"] for r in res]
        check("eng yaqini birinchi turadi",
              nomlar[0] == "Samsung S23", f"{nomlar}")
        check("masofa hisoblanadi",
              res[0]["distance_km"] is not None, f"{res[0]}")
        check("koordinatasiz e'lon ham yo'qolmaydi",
              len(nomlar) == 3, f"{nomlar}")

    # ── 7. Saralash: narx ────────────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, category="telefon", sort="price_asc",
                                    exclude_user_id=xid)
        narxlar = [r["price_uzs"] for r in res]
        check("narx o'sish bo'yicha saralanadi",
              narxlar == sorted(narxlar), f"{narxlar}")

        res = await search_listings(db, category="telefon", sort="price_desc",
                                    exclude_user_id=xid)
        narxlar = [r["price_uzs"] for r in res]
        check("narx kamayish bo'yicha saralanadi",
              narxlar == sorted(narxlar, reverse=True), f"{narxlar}")

    # ── 8. Hudud radiusi ─────────────────────────────────────────────
    async with async_session() as db:
        res = await search_listings(db, category="telefon", lat=41.30,
                                    lng=69.25, radius_km=1.0,
                                    exclude_user_id=xid)
        nomlar = [r["title"] for r in res]
        check("radius tashqarisidagi e'lon chiqmaydi",
              "Redmi Note 12" not in nomlar, f"{nomlar}")

    # ── 9. Chatдagi 20 ta chegarasi ──────────────────────────────────
    async with async_session() as db:
        for i in range(30):
            db.add(Listing(user_id=sid, category_key="kiyim",
                           title=f"Kurtka {i}", description="Ko'p e'lon testi",
                           price=100_000 + i, currency="UZS",
                           condition=ListingCondition.good,
                           address="Toshkent", status=ListingStatus.active,
                           expires_at=now + timedelta(days=7)))
        await db.commit()

        res = await search_listings(db, category="kiyim", limit=100,
                                    exclude_user_id=xid)
        check("chatда eng ko'pi 20 ta karta",
              len(res) == MAX_RESULTS == 20, f"{len(res)}")

    # ── 10. Toifani erkin matndan aniqlash ───────────────────────────
    check("«telefonimni sotaman» -> telefon",
          resolve_category("telefonimni sotaman") == "telefon")
    check("«mashinamni sotmoqchiman» -> avto",
          resolve_category("mashinamni sotmoqchiman") == "avto")
    check("«divan» -> mebel", resolve_category("divan sotiladi") == "mebel")
    check("noma'lum narsa -> boshqa",
          resolve_category("kosmik kema") == "boshqa")
    check("bo'sh qiymat ham xato bermaydi",
          resolve_category(None) == "boshqa")

    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi ({engine.dialect.name})")


asyncio.run(main())
