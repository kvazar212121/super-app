"""Mini-ilovalar auditi: budilnik, kaloriya, fitnes, moliya.

Foydalanuvchi so'radi: "majburlovchi budilnik, kaloriya hisoblagich,
fitnes va mening moliyam mini ilovlarni mantiqiy to'g'riligini va
logikasini qarab chiq va ishlatganda qanday xatolar bo'lishi mumkin
shularni bir qarab ko'r".

Bu test HAQIQIY HTTP so'rovlar bilan har bir mini-ilovani chegara
holatlarda sinaydi: noto'g'ri kirish, boshqa odamning ma'lumotiga
kirish, mantiqiy ziddiyatlar, nol/manfiy qiymatlar.

Maqsad: ishlatganda chiqadigan xatolarni OLDINDAN topish.
"""
import asyncio
import os
import sys
from datetime import date, datetime, timedelta, timezone

DB = os.environ.get("SUPERAPP_TEST_DB")
if not DB:
    print("SKIP: SUPERAPP_TEST_DB berilmagan (haqiqiy PostgreSQL kerak)")
    sys.exit(0)

BACKEND = os.environ.get(
    "SUPERAPP_BACKEND",
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend"),
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
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail, warn = [], [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def note(name, detail):
    """Xato emas, lekin e'tibor berish kerak bo'lgan holat."""
    warn.append(f"{name}: {detail}")


async def main():
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy import text

    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.main import create_app
    from app.models.user import User

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async with async_session() as db:
        u1 = User(name="Aziz", surname="Test", phone="+998901112233",
                  hashed_password=hash_password("parol123"))
        u2 = User(name="Begona", surname="Odam", phone="+998902223344",
                  hashed_password=hash_password("parol123"))
        db.add_all([u1, u2])
        await db.commit()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:

        async def login(phone):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": "parol123"})
            assert r.status_code == 200, f"login: {r.status_code} {r.text[:200]}"
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        h1 = await login("+998901112233")
        h2 = await login("+998902223344")

        # ══════════════ 1. MAJBURLOVCHI BUDILNIK ══════════════
        print("\n--- BUDILNIK ---")

        r = await c.post("/api/v1/alarms", headers=h1, json={
            "label": "Ertalabki", "hour": 7, "minute": 30,
            "repeat_days": "1,2,3,4,5", "mission_type": "math",
            "mission_config": {"difficulty": "medium", "count": 2},
        })
        check("budilnik yaratildi", r.status_code == 201,
              f"{r.status_code} {r.text[:200]}")
        alarm = r.json() if r.status_code == 201 else {}
        aid = alarm.get("id")

        # Noto'g'ri vaqt
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "hour": 25, "minute": 0})
        check("soat 25 rad etiladi", r.status_code == 422, f"{r.status_code}")
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "hour": 7, "minute": 99})
        check("daqiqa 99 rad etiladi", r.status_code == 422, f"{r.status_code}")
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "hour": -1, "minute": 0})
        check("manfiy soat rad etiladi", r.status_code == 422, f"{r.status_code}")

        # MANTIQIY XAVF: repeat_days CSV, lekin tekshirilmaydi
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "label": "Buzuq kunlar", "hour": 8, "minute": 0,
            "repeat_days": "9,abc,-3",
        })
        check("noto'g'ri repeat_days rad etiladi", r.status_code == 422,
              f"{r.status_code} — '9,abc,-3' qabul qilinsa budilnik "
              f"jimgina 'bir martalik' bo'lib qoladi")

        # To'g'ri qiymat tartiblanadi va takrorlar olib tashlanadi
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "label": "Tartib", "hour": 9, "minute": 0,
            "repeat_days": "5,1,1,3",
        })
        check("repeat_days tartiblanadi va takror olib tashlanadi",
              r.status_code == 201 and r.json()["repeat_days"] == "1,3,5",
              f"{r.status_code} {r.json().get('repeat_days') if r.status_code==201 else ''}")

        # Boshqa odamning budilnigi
        if aid:
            r = await c.put(f"/api/v1/alarms/{aid}", headers=h2,
                            json={"label": "O'g'irlangan"})
            check("begona odam budilnikni o'zgartira olmaydi",
                  r.status_code in (403, 404), f"{r.status_code}")
            r = await c.delete(f"/api/v1/alarms/{aid}", headers=h2)
            check("begona odam budilnikni o'chira olmaydi",
                  r.status_code in (403, 404), f"{r.status_code}")

        # Snooze chegarasi
        r = await c.post("/api/v1/alarms", headers=h1, json={
            "hour": 6, "minute": 0, "snooze_minutes": 0})
        check("snooze 0 daqiqa rad etiladi", r.status_code == 422, f"{r.status_code}")

        # ══════════════ 2. KALORIYA HISOBLAGICH ══════════════
        print("\n--- KALORIYA ---")

        r = await c.put("/api/v1/calories/profile", headers=h1, json={
            "sex": "male", "age": 30, "height_cm": 180, "weight_kg": 80,
            "activity_level": "moderate", "goal": "lose",
        })
        check("kaloriya profili saqlandi", r.status_code in (200, 201),
              f"{r.status_code} {r.text[:200]}")
        prof = r.json() if r.status_code in (200, 201) else {}

        # Mifflin-St Jeor: 10*80 + 6.25*180 - 5*30 + 5 = 1780
        # TDEE = 1780 * 1.55 = 2759, lose -> -500 = 2259
        goal = prof.get("daily_calorie_goal") or prof.get("calorie_goal")
        if goal:
            check("kaloriya maqsadi to'g'ri hisoblandi (2259)",
                  abs(goal - 2259) <= 2, f"{goal}, kutilgan ~2259")
        else:
            note("kaloriya maqsadi javobda yo'q", f"{str(prof)[:200]}")

        # Chegara qiymatlar
        for bad, label in [
            ({"sex": "male", "age": 5, "height_cm": 180, "weight_kg": 80}, "yosh 5"),
            ({"sex": "male", "age": 30, "height_cm": 300, "weight_kg": 80}, "bo'y 300"),
            ({"sex": "male", "age": 30, "height_cm": 180, "weight_kg": 5}, "vazn 5"),
            ({"sex": "male", "age": 30, "height_cm": 180, "weight_kg": 500}, "vazn 500"),
        ]:
            bad.setdefault("activity_level", "moderate")
            bad.setdefault("goal", "maintain")
            r = await c.put("/api/v1/calories/profile", headers=h1, json=bad)
            check(f"{label} rad etiladi", r.status_code == 422, f"{r.status_code}")

        # Ovqat qo'shish
        r = await c.post("/api/v1/calories/log", headers=h1, json={
            "dish_name": "Palov", "calories": 650, "protein_g": 20,
            "fat_g": 25, "carbs_g": 80, "meal_type": "lunch",
        })
        check("ovqat qo'shildi", r.status_code in (200, 201),
              f"{r.status_code} {r.text[:200]}")

        # MANTIQIY XAVF: manfiy kaloriya
        r = await c.post("/api/v1/calories/log", headers=h1, json={
            "dish_name": "Manfiy", "calories": -500, "meal_type": "lunch",
        })
        check("manfiy kaloriya rad etiladi", r.status_code == 422,
              f"{r.status_code}")

        # Haddan tashqari katta qiymat
        r = await c.post("/api/v1/calories/log", headers=h1, json={
            "dish_name": "Katta", "calories": 9999999, "meal_type": "lunch",
        })
        check("haddan tashqari katta kaloriya rad etiladi",
              r.status_code == 422, f"{r.status_code}")

        # Begona odam ma'lumoti
        r = await c.get("/api/v1/calories/summary", headers=h2)
        check("boshqa odamning kaloriyasi ko'rinmaydi",
              r.status_code in (200, 404),
              f"{r.status_code}")
        if r.status_code == 200:
            data = r.json()
            eaten = (data.get("calories_eaten") or data.get("total_calories")
                     or data.get("consumed_calories") or 0)
            check("begona foydalanuvchida ovqat yo'q", eaten == 0,
                  f"eaten={eaten} (u2 hech narsa qo'shmagan!)")

        # ══════════════ 3. FITNES ══════════════
        print("\n--- FITNES ---")

        r = await c.get("/api/v1/fitness/exercises", headers=h1)
        check("mashqlar ro'yxati ochiladi", r.status_code == 200, f"{r.status_code}")

        r = await c.get("/api/v1/fitness/plans/active", headers=h1)
        check("fitnes reja endpointi javob beradi",
              r.status_code in (200, 404), f"{r.status_code} {r.text[:150]}")

        # ══════════════ 4. MENING MOLIYAM ══════════════
        print("\n--- MOLIYA ---")

        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 50000, "category": "Oziq-ovqat",
            "description": "Non", "date": date.today().isoformat(),
        })
        check("xarajat yozildi", r.status_code in (200, 201),
              f"{r.status_code} {r.text[:200]}")

        # MANTIQIY XAVF: manfiy summa
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": -100000, "category": "Test",
            "date": date.today().isoformat(),
        })
        check("manfiy summa rad etiladi", r.status_code == 422, f"{r.status_code}")

        # Nol summa
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 0, "category": "Nol",
            "date": date.today().isoformat(),
        })
        check("nol summa rad etiladi", r.status_code == 422, f"{r.status_code}")

        # Noto'g'ri tur
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "allaqanday", "amount": 1000, "category": "Test",
            "date": date.today().isoformat(),
        })
        check("noto'g'ri tur rad etiladi", r.status_code == 422, f"{r.status_code}")

        # Kelajakdagi sana. FinanceRecord — sodir bo'lgan fakt; kelajakdagi
        # to'lov uchun alohida "Rejalashtirilgan to'lovlar" bo'limi bor.
        # Kelajak sanali yozuv joriy oy statistikasiga kirmay "yo'qoladi".
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 5000, "category": "Kelajak",
            "date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
        })
        check("kelajakdagi sana rad etiladi", r.status_code == 422, f"{r.status_code}")

        # Bugungi sana esa qabul qilinishi shart (chegara holati)
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 5000, "category": "Bugun",
            "date": datetime.now(timezone.utc).isoformat(),
        })
        check("bugungi sana qabul qilinadi", r.status_code == 201, f"{r.status_code}")
        today_rec_id = r.json().get("id") if r.status_code == 201 else None

        # O'tgan sana ham qabul qilinadi (eski xarajatni keyin kiritish)
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "income", "amount": 7000, "category": "O'tgan",
            "date": (datetime.now(timezone.utc) - timedelta(days=400)).isoformat(),
        })
        check("o'tgan sana qabul qilinadi", r.status_code == 201, f"{r.status_code}")

        # Tahrirlashda ham kelajakka surib bo'lmaydi (PATCH teshigi)
        if today_rec_id:
            r = await c.patch(f"/api/v1/finance/{today_rec_id}", headers=h1, json={
                "date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
            })
            check("tahrirda kelajak sana rad etiladi", r.status_code == 422,
                  f"{r.status_code}")

        # Chegara: qurilma soati bir necha soat oldinda bo'lishi mumkin,
        # 1 kunlik yon berish ichidagi sana RAD ETILMASLIGI kerak
        # (aks holda haqiqiy xarajat yozilmay qoladi).
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 1000, "category": "Yon berish",
            "date": (datetime.now(timezone.utc) + timedelta(hours=6)).isoformat(),
        })
        check("yon berish ichidagi sana qabul qilinadi (soat mintaqasi)",
              r.status_code == 201, f"{r.status_code}")

        # Naive sana (soat mintaqasisiz) — mobil ilova shunday yuborishi
        # mumkin. Taqqoslashda TypeError bermay, UTC deb qaralishi kerak.
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 1000, "category": "Naive",
            "date": (datetime.now(timezone.utc) - timedelta(days=2))
                    .replace(tzinfo=None).isoformat(),
        })
        check("naive (mintaqasiz) o'tgan sana qabul qilinadi",
              r.status_code == 201, f"{r.status_code} {r.text[:150]}")

        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 1000, "category": "Naive kelajak",
            "date": (datetime.now(timezone.utc) + timedelta(days=10))
                    .replace(tzinfo=None).isoformat(),
        })
        check("naive kelajak sana ham rad etiladi (500 emas)",
              r.status_code == 422, f"{r.status_code}")

        # Rejalashtirilgan to'lov: kelajak sana AYNAN shu yerda o'rinli
        r = await c.post("/api/v1/finance/planned", headers=h1, json={
            "title": "Ijara", "amount": 1500000, "category": "Uy",
            "due_date": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
        })
        check("rejalashtirilgan to'lovda kelajak sana o'rinli",
              r.status_code in (200, 201), f"{r.status_code}")

        # Lekin manfiy summa u yerda ham mantiqsiz
        r = await c.post("/api/v1/finance/planned", headers=h1, json={
            "title": "Xato", "amount": -5000, "category": "Uy",
            "due_date": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
        })
        check("rejalashtirilgan to'lovda manfiy summa rad etiladi",
              r.status_code == 422, f"{r.status_code}")

        # Kelajakdagi sana
        r = await c.post("/api/v1/finance/", headers=h1, json={
            "type": "expense", "amount": 1000, "category": "Kelajak",
            "date": (date.today() + timedelta(days=365)).isoformat(),
        })
        if r.status_code in (200, 201):
            note("kelajakdagi sana qabul qilinadi",
                 "1 yil keyingi xarajat bugungi hisobotga tushib ketishi mumkin")

        # Begona odam yozuvlari
        r = await c.get("/api/v1/finance/", headers=h2)
        if r.status_code == 200:
            data = r.json()
            items = data if isinstance(data, list) else data.get("items", data.get("records", []))
            check("begona odam boshqaning yozuvlarini ko'rmaydi",
                  len(items) == 0, f"{len(items)} ta yozuv ko'rindi!")

    await engine.dispose()

    print(f"\n{'='*60}")
    print(f"O'TDI ({len(ok)}):")
    for o in ok:
        print(f"  ✓ {o}")
    if warn:
        print(f"\nE'TIBOR BERING — ishlatganda muammo bo'lishi mumkin ({len(warn)}):")
        for w in warn:
            print(f"  ! {w}")
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for f in fail:
            print(f"  ✗ {f}")
        sys.exit(1)
    print(f"\nOK: {len(ok)} tekshiruv o'tdi, {len(warn)} ta ogohlantirish")


asyncio.run(main())
