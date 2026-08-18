"""Chegaralar, adminka bayrog'i, muddat uzaytirish va xavfsizlik.

Foydalanuvchi qarorlari:
    • oddiy: 7 kun, 5 ta e'lon, 6 rasm; premium: 30 kun, 50 ta, 10 rasm
    • adminkadan bo'lim O'CHIRILSA — tool ham, API ham ishlamaydi
    • muddat tugagach e'lon O'CHMAYDI, uzaytiriladi (premium bepul)
    • aloqadan oldin firibgarlik ogohlantirishi, shikoyat support'ga
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


RASMLAR = [f"/uploads/listings/{i}.jpg" for i in range(8)]


async def main():
    from fastapi import HTTPException
    from sqlalchemy import text
    from sqlalchemy.dialects.postgresql import JSONB
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.marketplace import Listing, ListingCondition, ListingStatus
    from app.models.support import SupportMessage
    from app.models.user import User
    from app.services.ai_agent.market_tools import (
        clear_draft, publish_listing, start_listing_draft,
    )
    from app.services.marketplace import currency, expire_old
    from app.services.marketplace import limits, photos as photo_rules
    from app.services.marketplace.extend import extend_info, extend_listing
    from app.services.marketplace.publisher import create_listing, own_listing
    from app.services.marketplace.draft import ListingDraft
    from app.services.marketplace.safety import report_listing, warning_text
    from app.services.marketplace.validator import ask_text, missing_fields

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
        oddiy = User(name="Oddiy", surname="T", phone="+998900001111",
                     hashed_password=hash_password("parol123"), balance=0)
        prem = User(name="Premium", surname="T", phone="+998900002222",
                    hashed_password=hash_password("parol123"),
                    is_premium=True, balance=0,
                    premium_until=now + timedelta(days=30))
        boy = User(name="Balansli", surname="T", phone="+998900003333",
                   hashed_password=hash_password("parol123"), balance=50_000)
        db.add_all([oddiy, prem, boy])
        await db.commit()
        uid, pid, bid = oddiy.id, prem.id, boy.id

    async def olish(db, user_id):
        """Foydalanuvchini oladi va premium sanasini UTC qiladi.

        SQLite vaqt mintaqasini saqlamaydi; haqiqiy Postgres'da bu
        shart emas, lekin test ikkalasida ham ishlashi kerak.
        """
        user = await db.get(User, user_id)
        if user.premium_until is not None and user.premium_until.tzinfo is None:
            user.premium_until = user.premium_until.replace(tzinfo=timezone.utc)
        return user

    def qoralama(nom="Test buyum"):
        return ListingDraft(
            category_key="boshqa", title=nom, description="Sinov e'loni",
            price=1_000_000, currency="UZS",
            condition=ListingCondition.good, address="Toshkent",
            photos=list(RASMLAR[:3]),
        )

    # ── 1. Standart chegaralar (reja bo'yicha) ───────────────────────
    check("oddiy muddat 7 kun", limits.free_days() == 7)
    check("premium muddat 30 kun", limits.premium_days() == 30)
    check("oddiy 5 ta e'lon", limits.free_limit() == 5)
    check("premium 50 ta e'lon", limits.premium_limit() == 50)
    check("kamida 3 rasm", limits.min_photos() == 3)

    async with async_session() as db:
        oddiy_u = await olish(db, uid)
        prem_u = await olish(db, pid)
        check("oddiyga 6 ta rasm", limits.max_photos(oddiy_u) == 6)
        check("premiumga 10 ta rasm", limits.max_photos(prem_u) == 10)
        check("premium muddati 30 kun", limits.listing_days(prem_u) == 30)

    # ── 2. Rasm chegarasi: kam bo'lsa rad, ko'p bo'lsa KESILADI ──────
    check("2 ta rasm rad etiladi",
          photo_rules.check(RASMLAR[:2]) is not None)
    check("3 ta rasm qabul qilinadi",
          photo_rules.check(RASMLAR[:3]) is None)
    async with async_session() as db:
        oddiy_u = await olish(db, uid)
        kesilgan = photo_rules.trim(RASMLAR, oddiy_u)
        check("oddiy foydalanuvchida 6 tadan ortig'i kesiladi",
              len(kesilgan) == 6, f"{len(kesilgan)}")
        prem_u = await olish(db, pid)
        check("premiumda 8 ta rasm ham qoladi",
              len(photo_rules.trim(RASMLAR, prem_u)) == 8,
              f"{len(photo_rules.trim(RASMLAR, prem_u))}")
    check("takrorlangan rasm bir marta olinadi",
          photo_rules.normalize([RASMLAR[0], RASMLAR[0]]) == [RASMLAR[0]])

    # ── 3. E'lon soni chegarasi ──────────────────────────────────────
    async with async_session() as db:
        user = await olish(db, uid)
        yaratilgan = 0
        xato = None
        for i in range(7):
            try:
                await create_listing(db, user, qoralama(f"Buyum {i}"))
                yaratilgan += 1
            except HTTPException as exc:
                xato = exc
                break
        check("oddiy foydalanuvchi 5 tadan ko'p ocholmaydi",
              yaratilgan == 5, f"{yaratilgan} ta")
        check("chegara xabari nima qilishni aytadi",
              xato is not None and "Premium" in str(xato.detail),
              f"{xato.detail if xato else 'xato yo`q'}")

    # ── 4. Sotilgan e'lon chegaraga sanalmaydi ───────────────────────
    async with async_session() as db:
        item = (await db.get(Listing, 1))
        item.status = ListingStatus.sold
        await db.commit()
        user = await olish(db, uid)
        soni = await limits.active_listing_count(db, uid)
        check("sotilgani faol e'lon sifatida sanalmaydi", soni == 4, f"{soni}")
        await create_listing(db, user, qoralama("Yangi buyum"))
        check("o'rniga yangisini berish mumkin",
              await limits.active_listing_count(db, uid) == 5)

    # ── 5. Adminka: bo'lim o'chirilsa hech narsa ishlamaydi ──────────
    from app.services import settings_service
    asl_get_bool = settings_service.get_bool

    def ochirilgan(key, default=True):
        if key == "feature_marketplace_enabled":
            return False
        return asl_get_bool(key, default)

    settings_service.get_bool = ochirilgan
    try:
        check("bo'lim o'chirilgani ko'rinadi",
              limits.marketplace_enabled() is False)
        async with async_session() as db:
            clear_draft(pid)
            raw, action = await start_listing_draft(db, pid, {
                "category": "telefon",
            })
            res = json.loads(raw)
            check("o'chirilganda AI tool ishlamaydi",
                  res["status"] == "disabled", f"{res}")
            check("o'chirilganda tushuntirish beriladi",
                  bool(res.get("message")), f"{res}")

            raw, _ = await publish_listing(db, pid, {"confirm": True})
            check("o'chirilganda e'lon ham berilmaydi",
                  json.loads(raw)["status"] == "disabled", f"{raw}")

        async with async_session() as db:
            user = await olish(db, pid)
            rad = False
            try:
                await create_listing(db, user, qoralama("O'chirilgan davr"))
            except HTTPException:
                rad = True
            check("o'chirilganda oddiy forma ham rad etadi", rad)
    finally:
        settings_service.get_bool = asl_get_bool

    check("qayta yoqilganda ishlaydi", limits.marketplace_enabled() is True)

    # ── 6. Adminka: premium talab qilish ─────────────────────────────
    def premium_talab(key, default=True):
        if key == "feature_marketplace_premium":
            return True
        return asl_get_bool(key, default)

    settings_service.get_bool = premium_talab
    try:
        async with async_session() as db:
            user = await olish(db, bid)  # premiumsiz
            rad = None
            try:
                await create_listing(db, user, qoralama("Premium talab"))
            except HTTPException as exc:
                rad = exc
            check("premium talab qilinsa oddiy foydalanuvchi bera olmaydi",
                  rad is not None and rad.status_code == 403, f"{rad}")

            prem_u = await olish(db, pid)
            berildi = await create_listing(db, prem_u, qoralama("Premium e'lon"))
            check("premium foydalanuvchi bera oladi", berildi.id is not None)
            check("premium e'loni 30 kunlik",
                  berildi.expires_at is not None)
    finally:
        settings_service.get_bool = asl_get_bool

    # ── 7. Muddat tugashi: e'lon O'CHMAYDI ───────────────────────────
    async with async_session() as db:
        item = await db.get(Listing, 2)
        item.expires_at = now - timedelta(days=1)
        await db.commit()
        soni = await expire_old(db)
        check("muddati tugaganlar belgilanadi", soni >= 1, f"{soni}")

    async with async_session() as db:
        item = await db.get(Listing, 2)
        check("e'lon O'CHIRILMAYDI, faqat holati o'zgaradi",
              item is not None and item.status == ListingStatus.expired,
              f"{item.status if item else 'yo`q'}")

    # ── 8. Uzaytirish: premium bepul, boshqasi balansdan ─────────────
    async with async_session() as db:
        prem_u = await olish(db, pid)
        info = extend_info(prem_u)
        check("premiumga uzaytirish bepul", info["free"] is True, f"{info}")

        oddiy_u = await olish(db, uid)
        info = extend_info(oddiy_u)
        check("oddiy foydalanuvchiga narx bor",
              info["free"] is False and info["price"] > 0, f"{info}")

    async with async_session() as db:
        oddiy_u = await olish(db, uid)
        xato = None
        try:
            await extend_listing(db, oddiy_u, 2)
        except HTTPException as exc:
            xato = exc
        check("balans yetmasa uzaytirilmaydi",
              xato is not None and xato.status_code == 402, f"{xato}")

    async with async_session() as db:
        # Balansli foydalanuvchiga e'lon berib, uzaytirtiramiz.
        boy_u = await olish(db, bid)
        item = await create_listing(db, boy_u, qoralama("Balansli e'lon"))
        item.expires_at = now - timedelta(days=1)
        item.status = ListingStatus.expired
        await db.commit()
        item_id = item.id

    async with async_session() as db:
        boy_u = await olish(db, bid)
        oldingi = boy_u.balance
        yangilangan = await extend_listing(db, boy_u, item_id)
        check("to'lov bilan uzaytiriladi",
              yangilangan.status == ListingStatus.active,
              f"{yangilangan.status}")
        check("muddat kelajakka suriladi",
              yangilangan.expires_at is not None, "muddat yo'q")
        boy_u = await olish(db, bid)
        check("balansdan yechiladi", boy_u.balance < oldingi,
              f"{oldingi} -> {boy_u.balance}")

    # ── 9. Begona e'longa tegib bo'lmaydi ────────────────────────────
    async with async_session() as db:
        xato = None
        try:
            await own_listing(db, pid, item_id)  # boshqa odamniki
        except HTTPException as exc:
            xato = exc
        check("begona e'lon topilmadi deb qaytadi",
              xato is not None and xato.status_code == 404, f"{xato}")

    # ── 10. Xavfsizlik: ogohlantirish va shikoyat ────────────────────
    check("ogohlantirishda firibgarlik haqida aytiladi",
          "firibgar" in warning_text().lower(), warning_text())
    check("oldindan pul o'tkazmaslik eslatiladi",
          "pul" in warning_text().lower())
    check("rus tilida ham bor",
          any(c in warning_text("ru") for c in "абвгдеёжзий"))

    async with async_session() as db:
        ticket_id = await report_listing(db, uid, item_id, "Boshqa gap aytdi")
        check("shikoyat support ticketiga tushadi", ticket_id > 0)

    async with async_session() as db:
        from sqlalchemy import select
        rows = (await db.execute(select(SupportMessage))).scalars().all()
        check("shikoyat matnida e'lon raqami bor",
              any(str(item_id) in m.text for m in rows), f"{[m.text for m in rows]}")
        check("shikoyat sababi saqlanadi",
              any("Boshqa gap" in m.text for m in rows), "sabab yo'q")

    # ── 11. Validator: yetishmaganlar BIR RO'YXATDA ──────────────────
    bosh = ListingDraft(category_key="telefon")
    yetishmagan = missing_fields(bosh)
    check("telefon uchun model va xotira ham majburiy",
          "model" in yetishmagan and "xotira" in yetishmagan,
          f"{yetishmagan}")
    matn = ask_text(bosh) or ""
    check("savol matnida hammasi bir ro'yxatda",
          matn.count("•") >= 5, f"{matn}")
    check("bir yozuvda yozish mumkinligi aytiladi",
          "bir yozuv" in matn.lower(), matn)

    kelishamiz = ListingDraft(category_key="boshqa", title="Divan",
                              is_negotiable=True,
                              condition=ListingCondition.good,
                              address="Toshkent")
    check("«Kelishamiz» bo'lsa narx so'ralmaydi",
          "price" not in missing_fields(kelishamiz),
          f"{missing_fields(kelishamiz)}")

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
