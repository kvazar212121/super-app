"""Adminkada e'lon bo'limi sozlamalari, ikki tillilik va rasm endpointi.

Foydalanuvchi talablari:
    "adminkada shu eloni bo'yicha premium yoqish yomaslik ham
     bo'lishi kerak ekan o'ylab korsam"
    "ai o'zbek tilida sorasin va rus tilida yozsa rus tilida
     gapirsin, ikki tilda bo'lgan programma"
    "ai agent chat bo'limida rasmga olishni ham qo'shimchasini qil"
"""
import asyncio
import io
import os
import sys

DB = os.environ.get("SUPERAPP_TEST_DB")

# ⚠️ ISHCHI BAZAGA TEGMASLIK QO'RIQCHISI.
# Bu test `DROP SCHEMA public CASCADE` qiladi. Xato baza
# ko'rsatilsa butun ishchi ma'lumot o'chib ketardi (bu bir
# marta haqiqatan sodir bo'lgan).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_guard import guard as _db_guard  # noqa: E402
_db_guard(DB)

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
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy import text
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.main import create_app
    from app.models.user import User
    from app.services import settings_service
    from app.services.ai_agent.prompt import SYSTEM_PROMPT

    # ── Prompt: ikki tillilik va e'lon qoidalari ─────────────────────
    check("prompt endi 'faqat o'zbekcha' demaydi",
          "Faqat o'zbek tilida, qisqa" not in SYSTEM_PROMPT,
          "eski qat'iy qoida qolgan")
    check("prompt rus tilini eslatadi",
          "рус" in SYSTEM_PROMPT.lower() or "Отвечайте" in SYSTEM_PROMPT,
          "rus tili haqida yo'q")
    check("prompt e'lon tool'larini biladi",
          "start_job_draft" in SYSTEM_PROMPT, "yo'q")
    check("prompt bron va e'lon farqini tushuntiradi",
          "E'LON" in SYSTEM_PROMPT and "BRON" in SYSTEM_PROMPT, "yo'q")
    check("prompt tasdiq majburiyligini aytadi",
          "confirm=true" in SYSTEM_PROMPT, "yo'q")

    # ── FEATURE_DEFS: e'lon bo'limi ──────────────────────────────────
    keys = {k for k, _ in settings_service.FEATURE_DEFS}
    check("'jobs' bo'limi adminka ro'yxatida bor", "jobs" in keys, f"{keys}")

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async with async_session() as db:
        admin = User(name="Admin", surname="T", phone="admin",
                     hashed_password=hash_password("admin123"),
                     is_admin=True, is_super_admin=True)
        user = User(name="Mijoz", surname="T", phone="+998900001111",
                    hashed_password=hash_password("parol123"))
        db.add_all([admin, user])
        await db.commit()

    async with AsyncClient(transport=ASGITransport(app=app),
                           base_url="http://t") as c:
        async def login(phone, pwd):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": pwd})
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        h_admin = await login("admin", "admin123")
        h_user = await login("+998900001111", "parol123")

        # ── Adminka: bo'limlar ro'yxatida jobs bormi ─────────────────
        r = await c.get("/api/v1/admin/feature-flags", headers=h_admin)
        check("admin bo'limlar ro'yxatini oldi", r.status_code == 200,
              f"{r.status_code}")
        flags = r.json().get("flags", []) if r.status_code == 200 else []
        jobs_flag = next((f for f in flags if f["key"] == "jobs"), None)
        check("adminkada 'Ish e'lonlari' bo'limi ko'rinadi",
              jobs_flag is not None, f"{[f['key'] for f in flags]}")
        check("bo'limda premium holati qaytadi",
              jobs_flag is not None and "premium" in jobs_flag,
              f"{jobs_flag}")
        check("boshlanishida premium talab qilinmaydi",
              jobs_flag and jobs_flag.get("premium") is False,
              f"{jobs_flag.get('premium') if jobs_flag else '?'}")

        # ── Admin premium'ni YOQADI ─────────────────────────────────
        payload = {"flags": [
            {"key": f["key"], "enabled": f["enabled"],
             "message": f.get("message") or "",
             "premium": (f["key"] == "jobs")}
            for f in flags
        ]}
        r = await c.put("/api/v1/admin/feature-flags", headers=h_admin,
                        json=payload)
        check("admin premium sozlamasini saqladi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")

        r = await c.get("/api/v1/admin/feature-flags", headers=h_admin)
        jobs_flag = next(
            (f for f in r.json().get("flags", []) if f["key"] == "jobs"), None
        )
        check("premium YOQILGANI saqlandi",
              jobs_flag and jobs_flag.get("premium") is True,
              f"{jobs_flag}")

        # ── Endi oddiy foydalanuvchi e'lon BERA OLMAYDI ─────────────
        from app.services.ai_job.limits import jobs_require_premium
        check("kod premium talabini ko'radi", jobs_require_premium() is True,
              "sozlama o'qilmadi")

        # ── Premium'ni qaytarib o'chiramiz ──────────────────────────
        payload = {"flags": [
            {"key": f["key"], "enabled": f["enabled"],
             "message": f.get("message") or "", "premium": False}
            for f in r.json().get("flags", [])
        ]}
        await c.put("/api/v1/admin/feature-flags", headers=h_admin,
                    json=payload)
        check("premium o'chirildi", jobs_require_premium() is False,
              "hali yoqiq")

        # ── AI chatga rasm yuborish endpointi ───────────────────────
        from PIL import Image
        buf = io.BytesIO()
        Image.new("RGB", (80, 60), (120, 120, 120)).save(buf, "PNG")
        buf.seek(0)
        r = await c.post("/api/v1/ai/job-photo", headers=h_user,
                         files={"file": ("joy.png", buf, "image/png")})
        # AI kaliti test muhitida yo'q — rasm baribir SAQLANISHI kerak
        check("rasm endpointi ishlaydi", r.status_code == 200,
              f"{r.status_code} {r.text[:200]}")
        if r.status_code == 200:
            body = r.json()
            check("rasm URL qaytadi (e'longa biriktirish uchun)",
                  isinstance(body.get("url"), str) and body["url"],
                  f"{body}")
            check("AI ishlamasa ham rasm yo'qolmaydi",
                  "analysis" in body, "analysis kaliti yo'q")
            check("foydalanuvchiga keyingi qadam aytiladi",
                  bool(body.get("message")), "message yo'q")

        # Tokensiz yuklab bo'lmaydi
        r = await c.post("/api/v1/ai/job-photo",
                         files={"file": ("x.png", io.BytesIO(b"x"), "image/png")})
        check("tokensiz rasm yuklab bo'lmaydi",
              r.status_code in (401, 403), f"{r.status_code}")

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
