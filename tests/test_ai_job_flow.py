"""AI orqali ish e'loni berish — uchdan-uchgacha oqim.

Foydalanuvchi so'ragan oqim:
    Mijoz AI chatga rasm + "shu joyni tamirlash kerak, ertaga" yozadi
    -> AI yetishmagan ma'lumotni SO'RAYDI
    -> hammasi yig'ilgach TASDIQ so'raydi
    -> tasdiqlangach e'lon yaratiladi
    -> e'lon faqat SHU HUDUDDAGI ustalarga ko'rinadi

Bu test tool'larni HAQIQIY PostgreSQL ustida chaqiradi (AI modeli
o'rniga biz to'g'ridan-to'g'ri chaqiramiz — model javobini emas,
BIZNING mantiqni sinaymiz).
"""
import asyncio
import json
import os
import sys
from datetime import datetime, timedelta, timezone

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
    from sqlalchemy import text
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.category import Category
    from app.models.job import JobPost, JobStatus
    from app.models.provider import Provider
    from app.models.user import User
    from app.services.ai_agent.job_tools import (
        clear_draft, publish_job, start_job_draft, update_job_draft,
    )

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        client = User(name="Mijoz", surname="T", phone="+998900001111",
                      hashed_password=hash_password("parol123"))
        prem = User(name="Premium", surname="T", phone="+998900002222",
                    hashed_password=hash_password("parol123"),
                    is_premium=True,
                    premium_until=datetime.now(timezone.utc) + timedelta(days=30))
        db.add_all([cat, client, prem])
        await db.commit()
        cid, uid, pid = cat.id, client.id, prem.id

    # ── 1. Yetishmagan ma'lumot SO'RALADI ────────────────────────────
    async with async_session() as db:
        clear_draft(uid)
        raw, _ = await start_job_draft(db, uid, {
            "description": "Uchta rozetka kuyib qolgan",
        })
        res = json.loads(raw)
        check("to'liq bo'lmagan e'lon darhol yaratilmaydi",
              res["status"] == "needs_more_info", f"{res}")
        check("AI foydalanuvchiga savol beradi",
              bool(res.get("ask_user")), f"{res}")
        check("qaysi maydon yetishmayotgani aytiladi",
              "address" in res.get("missing", []), f"{res.get('missing')}")

    # ── 2. Ma'lumot BO'LAK-BO'LAK yig'iladi ──────────────────────────
    async with async_session() as db:
        raw, _ = await update_job_draft(db, uid, {"category": "electrician"})
        res = json.loads(raw)
        check("soha qo'shilgach hali manzil so'raladi",
              res["status"] == "needs_more_info", f"{res}")

        raw, _ = await update_job_draft(db, uid, {
            "title": "Rozetka almashtirish",
            "address": "Toshkent, Chilonzor 5",
        })
        res = json.loads(raw)
        check("hamma ma'lumot yig'ilgach 'ready' bo'ladi",
              res["status"] == "ready", f"{res}")
        check("xulosada e'lon nomi bor",
              "Rozetka" in res.get("summary", ""), f"{res.get('summary')}")
        check("oldingi tavsif YO'QOLMAYDI (merge to'g'ri)",
              "rozetka" in res.get("summary", "").lower(), f"{res.get('summary')}")

    # ── 3. TASDIQSIZ e'lon YARATILMAYDI ──────────────────────────────
    async with async_session() as db:
        raw, action = await publish_job(db, uid, {})
        res = json.loads(raw)
        check("confirm'siz e'lon yaratilmaydi",
              res["status"] == "needs_confirmation", f"{res}")
        check("tasdiqsiz chaqiruv client action bermaydi",
              action is None, f"{action}")

    async with async_session() as db:
        from sqlalchemy import select, func as sqlfunc
        cnt = (await db.execute(
            select(sqlfunc.count(JobPost.id))
        )).scalar()
        check("bazada hali e'lon YO'Q", cnt == 0, f"{cnt} ta topildi")

    # ── 4. TASDIQLANGACH e'lon yaratiladi ────────────────────────────
    async with async_session() as db:
        raw, action = await publish_job(db, uid, {"confirm": True})
        res = json.loads(raw)
        check("tasdiqlangach e'lon yaratiladi",
              res["status"] == "success", f"{res}")
        job_id = res.get("job_id")
        check("client action 'jobs_changed' qaytadi",
              action and action.get("type") == "jobs_changed", f"{action}")

    async with async_session() as db:
        job = await db.get(JobPost, job_id) if job_id else None
        check("e'lon bazada bor va ochiq",
              job is not None and job.status == JobStatus.open,
              f"{job.status if job else 'yo`q'}")
        check("e'lon to'g'ri foydalanuvchiga tegishli",
              job and job.user_id == uid, "boshqa foydalanuvchi")
        check("e'lon nomi saqlandi",
              job and job.title == "Rozetka almashtirish", f"{job.title if job else ''}")
        # 5 kunlik muddat (oddiy foydalanuvchi)
        check("oddiy foydalanuvchi e'loni 5 kunda tugaydi",
              job and job.expires_at is not None, "expires_at yo'q")
        if job and job.expires_at:
            days = (job.expires_at - datetime.now(timezone.utc)).days
            check("muddat aynan 5 kun (4-5 oralig'ida)",
                  4 <= days <= 5, f"{days} kun")

    # ── 5. CHEGARA: 3 ta ochiq e'lon ─────────────────────────────────
    async with async_session() as db:
        created = 1  # yuqorida 1 ta yaratildi
        for i in range(2, 5):  # 2, 3, 4-e'lon
            clear_draft(uid)
            raw, _ = await start_job_draft(db, uid, {
                "category": "electrician",
                "title": f"Ish {i}",
                "description": "Test uchun e'lon matni",
                "address": "Toshkent, Chilonzor 5",
            })
            raw, _ = await publish_job(db, uid, {"confirm": True})
            res = json.loads(raw)
            if res["status"] == "success":
                created += 1
            else:
                check(f"{i}-e'londa chegara ishladi",
                      res["status"] == "limit_reached", f"{res}")
                check("chegara xabari tushunarli (nima qilishni aytadi)",
                      "Premium" in res.get("message", ""),
                      f"{res.get('message')}")
                break
        check("oddiy foydalanuvchi 3 tadan ko'p ocholmaydi",
              created == 3, f"{created} ta yaratildi")

    # ── 6. PREMIUM foydalanuvchi: cheksiz muddat ─────────────────────
    async with async_session() as db:
        clear_draft(pid)
        raw, _ = await start_job_draft(db, pid, {
            "category": "electrician",
            "title": "Premium ishi",
            "description": "Premium foydalanuvchi e'loni",
            "address": "Toshkent, Yunusobod 1",
        })
        raw, _ = await publish_job(db, pid, {"confirm": True})
        res = json.loads(raw)
        check("premium e'lon bera oladi", res["status"] == "success", f"{res}")
        pjob_id = res.get("job_id")

    async with async_session() as db:
        pjob = await db.get(JobPost, pjob_id) if pjob_id else None
        check("premium e'loni MUDDATSIZ (cheksiz)",
              pjob is not None and pjob.expires_at is None,
              f"{pjob.expires_at if pjob else 'yo`q'}")

    # ── 7. Premium 4-e'lonni ham bera oladi (oddiy bera olmasdi) ─────
    async with async_session() as db:
        made = 1
        for i in range(2, 6):
            clear_draft(pid)
            await start_job_draft(db, pid, {
                "category": "electrician",
                "title": f"Premium ish {i}",
                "description": "Premium chegarasi tekshiruvi",
                "address": "Toshkent, Yunusobod 1",
            })
            raw, _ = await publish_job(db, pid, {"confirm": True})
            if json.loads(raw)["status"] == "success":
                made += 1
        check("premium 3 tadan ko'p e'lon bera oladi",
              made >= 4, f"{made} ta")

    # ── 8. RUS TILI ──────────────────────────────────────────────────
    async with async_session() as db:
        clear_draft(uid)
        raw, _ = await start_job_draft(db, uid, {"lang": "ru"})
        res = json.loads(raw)
        ask = res.get("ask_user") or ""
        check("rus tilida savol beriladi",
              any(c in ask for c in "абвгдеёжзийклмнопрстуфхцчшщэюя"),
              f"{ask}")

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
