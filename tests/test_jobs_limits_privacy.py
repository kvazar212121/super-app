"""E'lon chegaralari va maxfiylik: oddiy forma AI bilan bir xil qoidada.

Nega bu test bor — ikkita haqiqiy kamchilik topilgan edi:

1) **Telefon raqami tarqalardi.** `JobOffer.to_dict()` ustaning haqiqiy
   raqamini mijozga qaytarardi. Foydalanuvchining qat'iy talabi:
   "HAQIQIY RAQAM BERILMAYDI, aloqa faqat ilova ichida". Raqam
   tarqalsa biz o'rtadan chiqib qolamiz (lead fee yo'qoladi).

2) **Chegarani chetlab o'tish mumkin edi.** 3 ta ochiq e'lon / 5 kun
   muddat tekshiruvi FAQAT AI tool'ida edi. Oddiy `POST /jobs` (ilovadagi
   forma) hech narsa tekshirmasdi, ya'ni foydalanuvchi cheksiz e'lon bera
   olardi.

Birinchi qism bazasiz ishlaydi (kod tuzilishi), ikkinchisi haqiqiy
PostgreSQL bo'lsa ishlaydi.
"""
import asyncio
import inspect
import os
import sys

BACKEND = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend"
)
sys.path.insert(0, BACKEND)


DB = os.environ.get("SUPERAPP_TEST_DB")

# ⚠️ ISHCHI BAZAGA TEGMASLIK QO'RIQCHISI.
# Bu test `DROP SCHEMA public CASCADE` qiladi. Xato baza
# ko'rsatilsa butun ishchi ma'lumot o'chib ketardi (bu bir
# marta haqiqatan sodir bo'lgan).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_guard import guard as _db_guard  # noqa: E402
_db_guard(DB)

# Bazasiz ham import qilinishi kerak (statik tekshiruvlar uchun).
# Haqiqiy ulanish ochilmaydi, faqat URL to'g'ri shaklda bo'lsin.
os.environ.setdefault(
    "DATABASE_URL", DB or "postgresql+asyncpg://x:x@127.0.0.1:1/x"
)
if DB:
    os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

ROOT = os.path.dirname(BACKEND)

# Ustaning haqiqiy raqami — javobda uchramasligi kerak
MASTER_PHONE = "+998911112233"

ok, fail, skipped = [], [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def _read_lib(rel):
    """Flutter faylini o'qiydi. Yo'q bo'lsa None (konteyner muhiti)."""
    path = os.path.join(ROOT, rel)
    if not os.path.exists(path):
        return None
    return open(path).read()


# ── 1-qism: bazasiz ──────────────────────────────────────────────────
def static_checks():
    from app.models.job import JobOffer
    from app.schemas.job import OfferOut
    from app.api.v1 import jobs as jobs_api

    src = inspect.getsource(JobOffer.to_dict)
    check("taklif javobida provider_phone YO'Q (model)",
          '"provider_phone"' not in src,
          "to_dict hali raqam qaytaryapti")

    check("taklif sxemasida provider_phone YO'Q",
          "provider_phone" not in OfferOut.model_fields,
          f"maydonlar: {list(OfferOut.model_fields)}")

    check("mijoz ustaga ilova ichida yoza oladi (owner_user_id bor)",
          "provider_owner_user_id" in OfferOut.model_fields,
          "chatni ochish uchun kerak")

    # Flutter tomoni. Backend konteynerida `lib/` yo'q, shuning uchun
    # fayl topilmasa TEKSHIRUV O'TKAZIB YUBORILADI (jimgina yiqilmaydi).
    dart = _read_lib("lib/models/job.dart")
    if dart is None:
        skipped.append("Flutter tekshiruvlari (lib/ ulanmagan)")
    else:
        check("Flutter modeli ham raqamni o'qimaydi",
              "provider_phone" not in dart and "providerPhone" not in dart,
              "Dart modelida qolgan")

        feed = _read_lib("lib/screens/jobs_feed_screen.dart") or ""
        # Rasm vidjeti `Image.network` dan `CachedNetworkImage` ga
        # o'tkazilgan (RAM keshi cheklangan). Test niyatni tekshiradi —
        # rasm ko'rsatiladimi va xato holati qayta ishlanadimi — konkret
        # vidjet nomini emas.
        rasm_bor = "Image.network" in feed or "CachedNetworkImage" in feed
        check("usta e'lon kartasida RASMNI ko'radi",
              "job.photos" in feed and rasm_bor,
              "usta ish hajmini rasmsiz baholay olmaydi")
        check("rasm yuklanmasa karta buzilmaydi",
              "errorBuilder" in feed or "errorWidget" in feed,
              "xato holati uchun zaxira vidjet yo'q")

    create_src = inspect.getsource(jobs_api.create_job)
    check("oddiy POST /jobs chegarani tekshiradi",
          "check_can_create_job" in create_src,
          "forma orqali cheksiz e'lon berish mumkin")
    check("oddiy POST /jobs muddat qo'yadi",
          "expires_at_for" in create_src,
          "e'lon abadiy ochiq qolardi")


def limit_math_checks():
    """Chegara hisobi — bazasiz, soxta foydalanuvchi bilan."""
    from datetime import datetime, timezone
    from app.services.ai_job import limits

    class FakeUser:
        def __init__(self, premium):
            self.is_premium = premium
            self.premium_until = (
                datetime(2099, 1, 1, tzinfo=timezone.utc) if premium else None
            )

    free, prem = FakeUser(False), FakeUser(True)

    check("oddiy foydalanuvchi: 3 ta ochiq e'lon",
          limits.job_limit_for(free) == 3, str(limits.job_limit_for(free)))
    check("premium: 20 ta", limits.job_limit_for(prem) == 20,
          str(limits.job_limit_for(prem)))
    check("oddiy foydalanuvchi: 5 kun muddat",
          limits.job_expiry_days(free) == 5, str(limits.job_expiry_days(free)))
    check("premium: muddat cheksiz",
          limits.job_expiry_days(prem) is None,
          str(limits.job_expiry_days(prem)))

    exp = limits.expires_at_for(free)
    delta = (exp - datetime.now(timezone.utc)).days
    check("oddiy e'lon 5 kundan keyin yopiladi", delta == 4 or delta == 5,
          f"{delta} kun")
    check("premium e'londa tugash vaqti yo'q",
          limits.expires_at_for(prem) is None)


# ── 2-qism: haqiqiy HTTP ─────────────────────────────────────────────
async def live_checks():
    from httpx import ASGITransport, AsyncClient
    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.main import create_app
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.user import User

    from sqlalchemy import text
    # drop_all ishlamaydi: users <-> finance_groups orasida aylanma FK bor
    # (SQLAlchemy jadval tartibini hisoblay olmaydi). Loyihaning boshqa
    # testlari ham shu sababli DROP SCHEMA ishlatadi.
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="zap")
        client = User(name="Mijoz", surname="Test", phone="+998900000101",
                      hashed_password=hash_password("parol123"))
        master = User(name="Usta", surname="Ali", phone="+998900000102",
                      hashed_password=hash_password("parol123"))
        db.add_all([cat, client, master])
        await db.flush()
        prov = Provider(name="Usta Ali", category_id=cat.id,
                        address="Toshkent, Chilonzor",
                        owner_user_id=master.id, phone=MASTER_PHONE,
                        lat=41.2995, lng=69.2401)
        db.add(prov)
        await db.commit()
        cid, prov_id = cat.id, prov.id

    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport,
                           base_url="http://test") as c:
        async def login(phone):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": "parol123"})
            assert r.status_code == 200, f"login {phone}: {r.text[:200]}"
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        h_client = await login("+998900000101")
        h_master = await login("+998900000102")

        async def post_job(title):
            return await c.post("/api/v1/jobs", headers=h_client, json={
                "category_id": cid,
                "title": title,
                "description": "Rozetka ishlamayapti, almashtirish kerak",
                "address": "Toshkent, Chilonzor 5",
                "lat": 41.2756, "lng": 69.2035,
            })

        first = await post_job("Rozetka 1")
        check("1-e'lon yaratildi", first.status_code == 201,
              f"{first.status_code} {first.text[:120]}")
        job_id = first.json().get("id")

        check("e'longa avtomatik muddat qo'yildi (5 kun)",
              first.json().get("expires_at") is not None,
              "expires_at bo'sh — e'lon abadiy ochiq qolardi")

        r2 = await post_job("Rozetka 2")
        r3 = await post_job("Rozetka 3")
        check("2 va 3-e'lon ham yaratiladi",
              r2.status_code == 201 and r3.status_code == 201,
              f"{r2.status_code}/{r3.status_code}")

        r4 = await post_job("Rozetka 4")
        check("4-e'lon RAD ETILADI (chegara 3 ta)", r4.status_code == 403,
              f"{r4.status_code}")
        detail = str(r4.json().get("detail", ""))
        check("xato tushunarli: nima qilishni aytadi",
              "Premium" in detail and "3" in detail, detail[:120])

        # ── Maxfiylik: taklif javobida raqam bo'lmasin ───────────────
        ro = await c.post(f"/api/v1/jobs/{job_id}/offers", headers=h_master,
                          json={"provider_id": prov_id, "price": 200000,
                                "message": "Bugun kelaman"})
        check("usta taklif berdi", ro.status_code in (200, 201),
              f"{ro.status_code} {ro.text[:120]}")

        rl = await c.get(f"/api/v1/jobs/{job_id}/offers", headers=h_client)
        body = rl.text
        offers = rl.json() if rl.status_code == 200 else []
        check("mijoz taklifni ko'rdi", len(offers) == 1, f"{len(offers)} ta")
        check("javobda ustaning HAQIQIY RAQAMI yo'q",
              MASTER_PHONE not in body and "provider_phone" not in body,
              "raqam tarqaldi!")
        if offers:
            o = offers[0]
            check("usta ismi va reytingi ko'rinadi (chatda kerak)",
                  "provider_name" in o and "provider_rating" in o,
                  str(list(o)))
            check("ilova ichida yozish uchun owner_user_id bor",
                  o.get("provider_owner_user_id") is not None)

    await engine.dispose()


def main():
    static_checks()
    limit_math_checks()
    if DB:
        asyncio.run(live_checks())
    else:
        print("SKIP: SUPERAPP_TEST_DB berilmagan — jonli qism o'tkazildi")

    print()
    for x in ok:
        print("  ✓", x)
    for x in skipped:
        print("  ~ o'tkazildi:", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")


main()
