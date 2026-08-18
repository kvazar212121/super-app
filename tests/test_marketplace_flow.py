"""AI chat orqali BUYUM SOTISH — uchdan-uchgacha oqim.

Foydalanuvchi so'ragan oqim:
    "telefonimni sotmoqchiman"
      -> AI kerakli maydonlarni BIR YO'LA ro'yxat qilib beradi
      -> odam yozgani qo'shiladi, faqat QOLGANI so'raladi
      -> kamida 3 ta rasm talab qilinadi
      -> tasdiqlangach e'lon yaratiladi

Tool'lar HAQIQIY PostgreSQL ustida chaqiriladi (AI modeli o'rniga
biz to'g'ridan-to'g'ri chaqiramiz — bizning mantiq sinaladi).
"""
import asyncio
import json
import os
import sys
from datetime import datetime, timedelta, timezone

# Bu test BAZAGA bog'liq mantiqni (chegara, muddat, egalik) sinaydi,
# lekin PostgreSQL'ga xos narsa ishlatmaydi. Shuning uchun baza
# berilmasa VAQTINCHA SQLite faylida ishlaydi — test SKIP bo'lib
# jimgina o'tib ketmasin. SUPERAPP_TEST_DB berilsa o'sha ishlatiladi.
import tempfile

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
os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "").replace("+aiosqlite", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


RASMLAR = ["/uploads/listings/a.jpg", "/uploads/listings/b.jpg",
           "/uploads/listings/c.jpg"]


async def main():
    from sqlalchemy import func as sqlfunc, select, text
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.marketplace import Listing, ListingStatus
    from app.models.user import User
    from app.services.ai_agent.market_tools import (
        add_listing_photos, clear_draft, close_listing_tool, my_listings_tool,
        publish_listing, start_listing_draft, update_listing_draft,
    )
    from app.services.marketplace import currency

    # Tashqi tarmoqqa chiqmaslik uchun kursni qo'lda beramiz.
    currency.set_rates({"USD": 12600.0})

    async with engine.begin() as conn:
        if engine.dialect.name == "postgresql":
            await conn.execute(text("DROP SCHEMA public CASCADE"))
            await conn.execute(text("CREATE SCHEMA public"))
            await conn.run_sync(Base.metadata.create_all)
        else:
            # SQLite ba'zi jadvallarni ko'tara olmaydi (boshqa
            # bo'limlarda JSONB kabi Postgres turlari bor) — o'shalar
            # tashlab ketiladi, qolgani to'liq yaratiladi. Savdo
            # mantig'i shu jadvallarga bog'liq emas.
            from sqlalchemy.dialects.postgresql import JSONB
            mumkin = [
                t for t in Base.metadata.sorted_tables
                if not any(isinstance(c.type, JSONB) for c in t.columns)
            ]
            await conn.run_sync(Base.metadata.drop_all, tables=mumkin)
            await conn.run_sync(Base.metadata.create_all, tables=mumkin)

    async with async_session() as db:
        sotuvchi = User(name="Sotuvchi", surname="T", phone="+998900001111",
                        hashed_password=hash_password("parol123"))
        prem = User(name="Premium", surname="T", phone="+998900002222",
                    hashed_password=hash_password("parol123"),
                    is_premium=True,
                    premium_until=datetime.now(timezone.utc) + timedelta(days=30))
        db.add_all([sotuvchi, prem])
        await db.commit()
        uid, pid = sotuvchi.id, prem.id

    # ── 1. AI KERAKLI MAYDONLARNI RO'YXAT QILIB BERADI ───────────────
    async with async_session() as db:
        clear_draft(uid)
        raw, _ = await start_listing_draft(db, uid, {
            "category": "telefon",
        })
        res = json.loads(raw)
        check("sotuv suhbati boshlanadi",
              res["status"] == "collecting", f"{res}")
        check("toifa aniqlanadi", res.get("category") == "telefon", f"{res}")
        maydonlar = res.get("required_fields") or []
        check("maydonlar BIR YO'LA ro'yxat bo'lib beriladi",
              len(maydonlar) >= 5, f"{maydonlar}")
        check("telefon uchun xotira so'raladi",
              any("Xotira" in m for m in maydonlar), f"{maydonlar}")
        check("kamida rasm soni aytiladi",
              res.get("min_photos") == 3, f"{res.get('min_photos')}")

    # ── 2. Faqat QOLGANI so'raladi ───────────────────────────────────
    async with async_session() as db:
        raw, _ = await update_listing_draft(db, uid, {
            "title": "iPhone 13 Pro 256GB",
            "price": 4500000,
            "attributes": {"model": "iPhone 13 Pro", "xotira": "256GB"},
        })
        res = json.loads(raw)
        check("hali to'liq emas", res["status"] == "collecting", f"{res}")
        check("berilgan maydon qayta so'ralmaydi",
              "title" not in res.get("missing", []), f"{res.get('missing')}")
        check("qolgani so'raladi (holat, manzil)",
              "condition" in res.get("missing", [])
              and "address" in res.get("missing", []), f"{res.get('missing')}")
        check("savol matni tayyor beriladi",
              bool(res.get("ask_user")), f"{res}")

    async with async_session() as db:
        raw, _ = await update_listing_draft(db, uid, {
            "condition": "ideal",
            "address": "Toshkent, Chilonzor",
        })
        res = json.loads(raw)
        check("hamma maydon to'lgach 'ready'",
              res["status"] == "ready", f"{res}")
        check("oldingi ma'lumot YO'QOLMAYDI",
              "iPhone" in (res.get("summary") or ""), f"{res.get('summary')}")

    # ── 3. RASMSIZ e'lon berilmaydi (kamida 3 ta) ────────────────────
    async with async_session() as db:
        raw, _ = await publish_listing(db, uid, {"confirm": True})
        res = json.loads(raw)
        check("rasmsiz e'lon YARATILMAYDI",
              res["status"] == "need_photos", f"{res}")
        check("nechta rasm kerakligi aniq aytiladi",
              "3" in (res.get("message") or ""), f"{res.get('message')}")

    async with async_session() as db:
        raw, _ = await add_listing_photos(db, uid, {"photos": RASMLAR[:2]})
        res = json.loads(raw)
        check("2 ta rasm hali kam", res["status"] == "need_photos", f"{res}")

        raw, _ = await add_listing_photos(db, uid, {"photos": [RASMLAR[2]]})
        res = json.loads(raw)
        check("3 ta rasm yetarli", res["status"] == "photos_ok", f"{res}")

    # ── 4. TASDIQSIZ e'lon yaratilmaydi ──────────────────────────────
    async with async_session() as db:
        raw, action = await publish_listing(db, uid, {})
        res = json.loads(raw)
        check("confirm'siz e'lon yaratilmaydi",
              res["status"] == "needs_confirmation", f"{res}")
        check("tasdiqsiz chaqiruv client action bermaydi",
              action is None, f"{action}")

    async with async_session() as db:
        cnt = (await db.execute(select(sqlfunc.count(Listing.id)))).scalar()
        check("bazada hali e'lon YO'Q", cnt == 0, f"{cnt} ta")

    # ── 5. Tasdiqlangach e'lon yaratiladi ────────────────────────────
    listing_id = None
    async with async_session() as db:
        raw, action = await publish_listing(db, uid, {"confirm": True})
        res = json.loads(raw)
        check("tasdiqlangach e'lon yaratiladi",
              res["status"] == "success", f"{res}")
        listing_id = res.get("listing_id")
        check("client action 'listings_changed'",
              action and action.get("type") == "listings_changed", f"{action}")

    async with async_session() as db:
        item = await db.get(Listing, listing_id) if listing_id else None
        check("e'lon bazada faol",
              item is not None and item.status == ListingStatus.active,
              f"{item.status if item else 'yo`q'}")
        check("e'lon egasi to'g'ri", item and item.user_id == uid, "boshqa")
        check("toifa saqlandi", item and item.category_key == "telefon",
              f"{item.category_key if item else ''}")
        check("toifaga xos maydonlar saqlandi",
              item and (item.attributes or {}).get("xotira") == "256GB",
              f"{item.attributes if item else ''}")
        check("3 ta rasm biriktirildi",
              item and len(item.photos) == 3,
              f"{len(item.photos) if item else 0} ta")
        check("birinchi rasm asosiy (sort_order=0)",
              item and item.photos[0].sort_order == 0, "tartib buzuq")
        check("oddiy foydalanuvchi e'loni 7 kunda tugaydi",
              item and item.expires_at is not None, "expires_at yo'q")
        if item and item.expires_at:
            # SQLite vaqt mintaqasini saqlamaydi — UTC deb qaraymiz.
            muddat = item.expires_at
            if muddat.tzinfo is None:
                muddat = muddat.replace(tzinfo=timezone.utc)
            kun = (muddat - datetime.now(timezone.utc)).days
            check("muddat aynan 7 kun", 6 <= kun <= 7, f"{kun} kun")

    # ── 6. TELEFON RAQAMI hech qayerda yo'q ──────────────────────────
    async with async_session() as db:
        item = await db.get(Listing, listing_id)
        data = item.to_dict()
        check("e'lon ma'lumotida telefon raqami YO'Q",
              not any("phone" in k for k in data), f"{list(data)}")
        check("qiymatlar ichida ham raqam yo'q",
              "+998" not in json.dumps(data, ensure_ascii=False), "raqam bor")

    # ── 7. "Kelishamiz" — narxsiz e'lon ham bo'ladi ──────────────────
    async with async_session() as db:
        clear_draft(uid)
        await start_listing_draft(db, uid, {
            "category": "mebel",
            "title": "Yumshoq divan",
            "condition": "yaxshi",
            "address": "Toshkent, Yunusobod",
            "attributes": {"tur": "divan"},
            "price": "kelishamiz",
            "photos": RASMLAR,
        })
        raw, _ = await publish_listing(db, uid, {"confirm": True})
        res = json.loads(raw)
        check("«Kelishamiz» e'loni yaratiladi",
              res["status"] == "success", f"{res}")
        divan_id = res.get("listing_id")

    async with async_session() as db:
        item = await db.get(Listing, divan_id)
        check("narx yo'q, «kelishamiz» belgisi bor",
              item and item.price is None and item.is_negotiable,
              f"{item.price if item else ''}")

    # ── 8. «Mening e'lonlarim» ───────────────────────────────────────
    async with async_session() as db:
        raw, action = await my_listings_tool(db, uid, {})
        res = json.loads(raw)
        check("mening e'lonlarim ko'rinadi", res.get("count") == 2, f"{res}")
        check("ilovaga to'liq ma'lumot yuboriladi",
              action and action.get("type") == "my_listings", f"{action}")

    # ── 9. «Sotildi» — tasdiq bilan ──────────────────────────────────
    async with async_session() as db:
        raw, _ = await close_listing_tool(db, uid, {"listing_id": listing_id})
        res = json.loads(raw)
        check("sotildi ham TASDIQ so'raydi",
              res["status"] == "needs_confirmation", f"{res}")

    async with async_session() as db:
        raw, _ = await close_listing_tool(db, uid, {
            "listing_id": listing_id, "confirm": True,
        })
        res = json.loads(raw)
        check("tasdiqlangach sotildi bo'ladi",
              res.get("new_status") == "sold", f"{res}")

    # ── 10. BEGONA e'longa tegib bo'lmaydi ───────────────────────────
    async with async_session() as db:
        raw, _ = await close_listing_tool(db, pid, {
            "listing_id": divan_id, "confirm": True,
        })
        res = json.loads(raw)
        check("begona e'lonni yopib bo'lmaydi",
              res["status"] == "error", f"{res}")

    async with async_session() as db:
        item = await db.get(Listing, divan_id)
        check("begona e'lon holati o'zgarmadi",
              item and item.status == ListingStatus.active,
              f"{item.status if item else ''}")

    # ── 11. Rus tili ─────────────────────────────────────────────────
    async with async_session() as db:
        clear_draft(pid)
        raw, _ = await start_listing_draft(db, pid, {
            "category": "avto", "lang": "ru",
        })
        res = json.loads(raw)
        matn = " ".join(res.get("required_fields") or [])
        check("rus tilida maydonlar ro'yxati beriladi",
              any(c in matn for c in "абвгдеёжзийклмнопрстуфхцчшщэюя"),
              f"{matn}")

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
