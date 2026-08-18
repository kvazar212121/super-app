"""Savdo REST API — HTTP darajasida (haqiqiy so'rovlar).

Boshqa savdo testlari servis funksiyalarini bevosita chaqiradi.
Bu yerda esa ilova ko'radigan narsa sinaladi: yo'llar, avtorizatsiya,
xato kodlari va javob shakli. Marshrut tartibi xato bo'lsa (masalan
`/my/list` `/{listing_id}` dan keyin tursa) faqat shu daraja ushlaydi.
"""
import asyncio
import os
import sys
import tempfile

DB = os.environ.get("SUPERAPP_TEST_DB")
if not DB:
    _tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    _tmp.close()
    DB = f"sqlite+aiosqlite:///{_tmp.name}"

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJ, "backend"))

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
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy import text
    from sqlalchemy.dialects.postgresql import JSONB

    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.main import create_app
    from app.models.user import User
    from app.services.marketplace import currency

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

    async with async_session() as db:
        db.add_all([
            User(name="Sotuvchi", surname="T", phone="+998900000021",
                 hashed_password=hash_password("parol123")),
            User(name="Xaridor", surname="T", phone="+998900000022",
                 hashed_password=hash_password("parol123")),
        ])
        await db.commit()

    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://t") as c:
        async def login(phone):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": "parol123"})
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        sot = await login("+998900000021")
        xar = await login("+998900000022")

        # ── Avtorizatsiya majburiy ───────────────────────────────────
        r = await c.get("/api/v1/marketplace/search")
        check("tokensiz qidiruv rad etiladi",
              r.status_code in (401, 403), f"{r.status_code}")

        # ── Toifalar ─────────────────────────────────────────────────
        r = await c.get("/api/v1/marketplace/categories")
        check("toifalar ro'yxati ochiladi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        data = r.json() if r.status_code == 200 else {}
        kalitlar = {x["key"] for x in data.get("categories", [])}
        check("10 ta toifa bor", len(kalitlar) == 10, f"{sorted(kalitlar)}")
        check("rejadagi toifalar joyida",
              {"telefon", "avto", "mebel", "hayvon", "boshqa"} <= kalitlar,
              f"{sorted(kalitlar)}")
        check("har toifada maydonlar ro'yxati bor",
              all(x.get("required_fields") for x in data.get("categories", [])),
              "bo'sh ro'yxat bor")
        check("rasm chegarasi ilovaga aytiladi",
              data.get("min_photos") == 3 and data.get("max_photos") == 6,
              f"{data.get('min_photos')}/{data.get('max_photos')}")

        # ── E'lon berish ─────────────────────────────────────────────
        yangi = {
            "category": "telefon",
            "title": "iPhone 13 Pro 256GB",
            "description": "Ideal holatda",
            "price": 4_500_000,
            "currency": "UZS",
            "condition": "ideal",
            "address": "Toshkent, Chilonzor",
            "attributes": {"model": "iPhone 13 Pro", "xotira": "256GB"},
            "photos": ["/a.jpg", "/b.jpg", "/c.jpg"],
        }
        r = await c.post("/api/v1/marketplace", headers=sot, json=yangi)
        check("e'lon yaratildi (201)", r.status_code == 201,
              f"{r.status_code} {r.text[:200]}")
        item = r.json() if r.status_code == 201 else {}
        lid = item.get("id")
        check("javobda narx so'mda ham keladi",
              item.get("price_uzs") == 4_500_000, f"{item.get('price_uzs')}")
        check("javobda telefon raqami YO'Q",
              not any("phone" in k for k in item), f"{sorted(item)}")

        # ── Rasm yetmasa 400 ─────────────────────────────────────────
        kam = dict(yangi, photos=["/a.jpg"], title="Kam rasmli")
        r = await c.post("/api/v1/marketplace", headers=sot, json=kam)
        check("2 tadan kam rasm bilan e'lon rad etiladi",
              r.status_code == 400, f"{r.status_code} {r.text[:150]}")

        # ── Qidiruv ──────────────────────────────────────────────────
        r = await c.get("/api/v1/marketplace/search?category=telefon",
                        headers=xar)
        check("xaridor qidiruvi ishlaydi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        topildi = r.json() if r.status_code == 200 else []
        check("e'lon qidiruvda ko'rinadi",
              any(x["id"] == lid for x in topildi), f"{topildi}")
        check("qidiruv javobida ham raqam yo'q",
              topildi and not any("phone" in k for k in topildi[0]),
              "raqam bor")

        r = await c.get("/api/v1/marketplace/search?category=telefon",
                        headers=sot)
        check("sotuvchi o'z e'lonini qidiruvda ko'rmaydi",
              all(x["id"] != lid for x in r.json()), f"{r.json()}")

        r = await c.get("/api/v1/marketplace/search?price_max=1000",
                        headers=xar)
        check("narx chegarasi HTTP orqali ham ishlaydi",
              r.json() == [], f"{r.json()}")

        # ── "Mening e'lonlarim" marshruti ID bilan chalkashmaydi ─────
        r = await c.get("/api/v1/marketplace/my/list", headers=sot)
        check("/my/list ishlaydi (marshrut tartibi to'g'ri)",
              r.status_code == 200, f"{r.status_code} {r.text[:150]}")
        meniki = r.json() if r.status_code == 200 else {}
        check("o'z e'lonlarim ro'yxatda",
              any(x["id"] == lid for x in meniki.get("listings", [])),
              f"{meniki}")
        check("uzaytirish shartlari ham qaytadi",
              "price" in (meniki.get("extend") or {}), f"{meniki.get('extend')}")

        # ── Bitta e'lon + ko'rishlar ─────────────────────────────────
        r = await c.get(f"/api/v1/marketplace/{lid}", headers=xar)
        check("bitta e'lon ochiladi", r.status_code == 200, f"{r.status_code}")
        check("begona ko'rgani sanaladi", r.json().get("views") == 1,
              f"{r.json().get('views')}")

        r = await c.get(f"/api/v1/marketplace/{lid}", headers=sot)
        check("egasining ko'rishi sanalmaydi", r.json().get("views") == 1,
              f"{r.json().get('views')}")

        r = await c.get("/api/v1/marketplace/999999", headers=xar)
        check("yo'q e'lon uchun 404", r.status_code == 404, f"{r.status_code}")

        # ── Ogohlantirish ────────────────────────────────────────────
        r = await c.get(f"/api/v1/marketplace/{lid}/safety", headers=xar)
        check("ogohlantirish endpointi ishlaydi", r.status_code == 200,
              f"{r.status_code}")
        ogoh = r.json() if r.status_code == 200 else {}
        check("ogohlantirish matni firibgarlik haqida",
              "firibgar" in (ogoh.get("text") or "").lower(), f"{ogoh}")
        check("tugmalar keladi (Tushunarli / Shikoyat)",
              len(ogoh.get("buttons") or []) == 2, f"{ogoh.get('buttons')}")

        # ── Shikoyat ─────────────────────────────────────────────────
        r = await c.post(f"/api/v1/marketplace/{lid}/report", headers=xar,
                         json={"reason": "Boshqa gap aytdi"})
        check("shikoyat qabul qilinadi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        check("support ticketi yaratiladi",
              (r.json() or {}).get("ticket_id", 0) > 0, f"{r.text[:120]}")

        # ── BEGONA e'longa tegib bo'lmaydi ───────────────────────────
        r = await c.post(f"/api/v1/marketplace/{lid}/sold", headers=xar)
        check("begona e'lonni sotildi qilib bo'lmaydi (404)",
              r.status_code == 404, f"{r.status_code}")

        r = await c.post(f"/api/v1/marketplace/{lid}/extend", headers=xar)
        check("begona e'lonni uzaytirib bo'lmaydi (404)",
              r.status_code == 404, f"{r.status_code}")

        # ── Egasi boshqara oladi ─────────────────────────────────────
        r = await c.post(f"/api/v1/marketplace/{lid}/hide", headers=sot)
        check("egasi yashira oladi",
              r.status_code == 200 and r.json().get("status") == "hidden",
              f"{r.status_code} {r.text[:120]}")

        r = await c.get("/api/v1/marketplace/search?category=telefon",
                        headers=xar)
        check("yashirilgan e'lon qidiruvdan chiqadi",
              all(x["id"] != lid for x in r.json()), f"{r.json()}")

        r = await c.post(f"/api/v1/marketplace/{lid}/reopen", headers=sot)
        check("qayta e'lon qilish ishlaydi",
              r.status_code == 200 and r.json().get("status") == "active",
              f"{r.status_code} {r.text[:120]}")

        r = await c.post(f"/api/v1/marketplace/{lid}/sold", headers=sot)
        check("egasi sotildi deb belgilaydi",
              r.status_code == 200 and r.json().get("status") == "sold",
              f"{r.status_code} {r.text[:120]}")

        # ── Uzaytirish: balans yetmasa 402 ───────────────────────────
        r = await c.post(f"/api/v1/marketplace/{lid}/extend", headers=sot)
        check("balans yetmasa 402 qaytadi", r.status_code == 402,
              f"{r.status_code} {r.text[:150]}")

        # ── Adminka: bo'lim o'chirilsa API ham to'xtaydi ─────────────
        from app.services import settings_service
        asl = settings_service.get_bool

        def ochirilgan(key, default=True):
            if key == "feature_marketplace_enabled":
                return False
            return asl(key, default)

        settings_service.get_bool = ochirilgan
        try:
            r = await c.get("/api/v1/marketplace/search", headers=xar)
            check("o'chirilganda qidiruv 403",
                  r.status_code == 403, f"{r.status_code}")
            r = await c.post("/api/v1/marketplace", headers=sot, json=yangi)
            check("o'chirilganda e'lon berish 403",
                  r.status_code == 403, f"{r.status_code}")
            r = await c.get("/api/v1/marketplace/my/list", headers=sot)
            check("o'chirilganda mening e'lonlarim ham 403",
                  r.status_code == 403, f"{r.status_code}")
        finally:
            settings_service.get_bool = asl

        r = await c.get("/api/v1/marketplace/search", headers=xar)
        check("qayta yoqilganda ishlaydi", r.status_code == 200,
              f"{r.status_code}")

    # ── Ishga tushish: jadvallar create_all bilan yaratiladimi ──────
    # Alembic ishlatilmaydi, ya'ni serverda jadval FAQAT shu yo'l bilan
    # paydo bo'ladi. Model import qilinmasa jadval yaratilmay qoladi va
    # savdo prodda 500 beradi — shuni qo'riqlaymiz.
    check("listings jadvali metadata'да ro'yxatdan o'tgan",
          "listings" in Base.metadata.tables, f"{len(Base.metadata.tables)}")
    check("listing_photos jadvali ham",
          "listing_photos" in Base.metadata.tables, "yo'q")

    startup_src = open(
        os.path.join(PROJ, "backend/app/core/startup.py")
    ).read()
    check("startup create_all chaqiradi (Alembic yo'q)",
          "Base.metadata.create_all" in startup_src, "topilmadi")

    models_init = open(
        os.path.join(PROJ, "backend/app/models/__init__.py")
    ).read()
    check("modellar paketi Listing'ni import qiladi (aks holda jadval yaratilmaydi)",
          "marketplace import" in models_init, "import yo'q")

    # ── Scheduler ulanganmi ─────────────────────────────────────────
    sched_src = open(
        os.path.join(PROJ, "backend/app/core/schedulers.py")
    ).read()
    check("muddat scheduleri yozilgan",
          "listing_expiry_scheduler" in sched_src, "yo'q")
    check("scheduler bolalar ro'yxatiga qo'shilgan",
          sched_src.count("listing_expiry_scheduler") >= 2,
          "ishga tushirilmagan")

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
