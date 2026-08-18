"""E'lon faqat SHU HUDUDDAGI ustalarga ko'rinishi.

Foydalanuvchi talabi:
    "bu elani bir huddagi odamlar yani ustalar kora olishi kerak
     masalan toshkent shaxardan bo'lsa shuni ichidan"

Ilgari usta lentasi faqat KATEGORIYA bo'yicha filtrlanardi, ya'ni
Buxorodagi elektrik Toshkentdagi e'lonni ko'rib, bekorga taklif
berardi. Bu test shuning oldi olinganini tekshiradi.

HAQIQIY koordinatalar ishlatiladi (Toshkent, Buxoro, Samarqand).
"""
import asyncio
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

# Haqiqiy koordinatalar
TOSHKENT = (41.2995, 69.2401)
TOSHKENT_CHILONZOR = (41.2756, 69.2035)   # shahar ichida, ~5 km
TOSHKENT_YUNUSOBOD = (41.3670, 69.2870)   # shahar ichida, ~9 km
BUXORO = (39.7747, 64.4286)               # ~440 km
SAMARQAND = (39.6270, 66.9750)            # ~270 km

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
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.user import User
    from app.services.ai_job.geo import (
        distance_km, is_visible_to_provider, region_of,
    )

    # ── Sof mantiq tekshiruvlari (bazasiz) ───────────────────────────
    d = distance_km(*TOSHKENT, *BUXORO)
    check("Toshkent-Buxoro masofasi ~440 km", 400 < d < 480, f"{d:.0f} km")

    d = distance_km(*TOSHKENT_CHILONZOR, *TOSHKENT_YUNUSOBOD)
    check("Toshkent ichidagi masofa 50 km dan kam", d < 50, f"{d:.1f} km")

    check("manzil matnidan Toshkent tanildi",
          region_of("Toshkent, Chilonzor 5") == "toshkent", "")
    check("kirillcha ham tanildi",
          region_of("Ташкент, Чиланзар") == "toshkent", "")
    check("Buxoro boshqa hudud deb tanildi",
          region_of("Buxoro shahri") == "buxoro", "")

    # Koordinatasiz, lekin manzil matni bor
    check("koordinatasiz: bir shahar -> ko'rinadi",
          is_visible_to_provider(None, None, "Toshkent, Chilonzor",
                                 None, None, "Toshkent, Yunusobod"), "")
    check("koordinatasiz: boshqa shahar -> ko'rinmaydi",
          not is_visible_to_provider(None, None, "Toshkent, Chilonzor",
                                     None, None, "Buxoro markazi"), "")
    check("hech narsa aniq emas -> KO'RINADI (e'lon yo'qolmasin)",
          is_visible_to_provider(None, None, None, None, None, None), "")

    # ── Haqiqiy HTTP oqimi ───────────────────────────────────────────
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        client = User(name="Mijoz", surname="T", phone="+998900001111",
                      hashed_password=hash_password("parol123"))
        u_tosh = User(name="Usta", surname="Toshkent", phone="+998900002222",
                      hashed_password=hash_password("parol123"))
        u_bux = User(name="Usta", surname="Buxoro", phone="+998900003333",
                     hashed_password=hash_password("parol123"))
        db.add_all([cat, client, u_tosh, u_bux])
        await db.flush()

        p_tosh = Provider(category_id=cat.id, name="Toshkent ustasi",
                          address="Toshkent, Yunusobod", phone="+998901111111",
                          owner_user_id=u_tosh.id,
                          lat=TOSHKENT_YUNUSOBOD[0], lng=TOSHKENT_YUNUSOBOD[1])
        p_bux = Provider(category_id=cat.id, name="Buxoro ustasi",
                         address="Buxoro markazi", phone="+998902222222",
                         owner_user_id=u_bux.id,
                         lat=BUXORO[0], lng=BUXORO[1])
        p_sam = Provider(category_id=cat.id, name="Samarqand ustasi",
                         address="Samarqand", phone="+998903333333",
                         lat=SAMARQAND[0], lng=SAMARQAND[1])
        db.add_all([p_tosh, p_bux, p_sam])
        await db.commit()
        cid = cat.id
        ids = {"tosh": p_tosh.id, "bux": p_bux.id, "sam": p_sam.id}

    async with AsyncClient(transport=ASGITransport(app=app),
                           base_url="http://t") as c:
        async def login(phone):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": "parol123"})
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        h = await login("+998900001111")
        h_tosh = await login("+998900002222")
        h_bux = await login("+998900003333")

        # Toshkentda e'lon (koordinata bilan)
        r = await c.post("/api/v1/jobs", headers=h, json={
            "category_id": cid,
            "title": "Rozetka almashtirish",
            "description": "Uchta rozetka kuyib qolgan",
            "address": "Toshkent, Chilonzor 5",
            "lat": TOSHKENT_CHILONZOR[0], "lng": TOSHKENT_CHILONZOR[1],
        })
        check("Toshkentda e'lon yaratildi", r.status_code == 201,
              f"{r.status_code} {r.text[:150]}")
        jid = r.json().get("id")

        # ── ASOSIY TEKSHIRUV ─────────────────────────────────────────
        r = await c.get(f"/api/v1/jobs/feed?provider_id={ids['tosh']}",
                        headers=h_tosh)
        tosh_jobs = r.json() if r.status_code == 200 else []
        check("Toshkent ustasi Toshkent e'lonini KO'RADI",
              any(x["id"] == jid for x in tosh_jobs),
              f"{r.status_code}, {len(tosh_jobs)} ta")

        r = await c.get(f"/api/v1/jobs/feed?provider_id={ids['bux']}",
                        headers=h_bux)
        bux_jobs = r.json() if r.status_code == 200 else []
        check("Buxoro ustasi Toshkent e'lonini KO'RMAYDI",
              all(x["id"] != jid for x in bux_jobs),
              f"{len(bux_jobs)} ta ko'rindi")

        r = await c.get(f"/api/v1/jobs/feed?provider_id={ids['sam']}",
                        headers=h_bux)
        sam_jobs = r.json() if r.status_code == 200 else []
        check("Samarqand ustasi ham KO'RMAYDI (270 km)",
              all(x["id"] != jid for x in sam_jobs),
              f"{len(sam_jobs)} ta ko'rindi")

        # Masofa ko'rsatiladimi (usta uchun foydali)
        mine = [x for x in tosh_jobs if x["id"] == jid]
        check("e'lon kartasida masofa ko'rsatiladi",
              mine and mine[0].get("distance_km") is not None,
              f"{mine[0].get('distance_km') if mine else 'yo`q'}")
        if mine and mine[0].get("distance_km") is not None:
            check("masofa oqilona (Toshkent ichida < 20 km)",
                  mine[0]["distance_km"] < 20,
                  f"{mine[0]['distance_km']} km")

        # provider_id berilmasa — eski xatti-harakat (hammasi)
        r = await c.get("/api/v1/jobs/feed", headers=h_bux)
        all_jobs = r.json() if r.status_code == 200 else []
        check("provider_id berilmasa filtr yo'q (eski xatti-harakat)",
              any(x["id"] == jid for x in all_jobs),
              f"{len(all_jobs)} ta")

        # Koordinatasiz e'lon: manzil matni bo'yicha
        r = await c.post("/api/v1/jobs", headers=h, json={
            "category_id": cid,
            "title": "Kran oqyapti",
            "description": "Oshxonadagi kran tomchilayapti",
            "address": "Toshkent, Sergeli tumani",
        })
        jid2 = r.json().get("id") if r.status_code == 201 else None
        check("koordinatasiz e'lon ham yaratiladi", jid2 is not None,
              f"{r.status_code}")

        r = await c.get(f"/api/v1/jobs/feed?provider_id={ids['tosh']}",
                        headers=h_tosh)
        check("koordinatasiz e'lon Toshkent ustasiga ko'rinadi (manzil matni)",
              any(x["id"] == jid2 for x in r.json()), "ko'rinmadi")

        r = await c.get(f"/api/v1/jobs/feed?provider_id={ids['bux']}",
                        headers=h_bux)
        check("koordinatasiz e'lon Buxoro ustasiga KO'RINMAYDI",
              all(x["id"] != jid2 for x in r.json()), "ko'rindi")

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
