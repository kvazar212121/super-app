"""Ish e'lonlari tizimini HAQIQIY HTTP so'rovlar bilan sinaydi.

Foydalanuvchi talabi:
  "ustlar bo'limiga kirganingda ustlar uchun alohida e'lon berib qo'yish
   tugmasi bo'ladi, ish qilinadigan joyni rasmga olib, summani yozib,
   qachon qilinish kerakligini yozib e'lon berib qo'yilishi kerak.
   Oddiy odam va ustalar soha egasi panelida e'lonlarni ko'rish joyi
   bo'lishi kerak, u yerda qilinadigan ishlarni ko'rib mijozga takliflar
   berishadi. O'rtasida chat bo'lishi mumkin, SMS xonasida va
   bildirishnomalarda ham kelgan xabarlari turishi kerak."

HAQIQIY PostgreSQL kerak:
    SUPERAPP_TEST_DB=postgresql+asyncpg://user:pass@host:port/db
"""
import asyncio
import os
import sys
from datetime import datetime, timedelta, timezone

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

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy import select

    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.main import create_app
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.user import User

    from sqlalchemy import text
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async with async_session() as db:
        client = User(name="Mijoz", surname="Test", phone="+998901112233",
                      hashed_password=hash_password("parol123"))
        master1 = User(name="Usta", surname="Bir", phone="+998902223344",
                       hashed_password=hash_password("parol123"))
        master2 = User(name="Usta", surname="Ikki", phone="+998903334455",
                       hashed_password=hash_password("parol123"))
        outsider = User(name="Begona", surname="Odam", phone="+998904445566",
                        hashed_password=hash_password("parol123"))
        cat_electric = Category(key="electrician", title_uz="Elektrik", icon="zap")
        cat_plumber = Category(key="plumber", title_uz="Santexnik", icon="droplet")
        db.add_all([client, master1, master2, outsider, cat_electric, cat_plumber])
        await db.flush()

        p1 = Provider(category_id=cat_electric.id, name="Elektrik Ali",
                      address="Toshkent 1", phone="+998900000001",
                      owner_user_id=master1.id)
        p2 = Provider(category_id=cat_electric.id, name="Elektrik Vali",
                      address="Toshkent 2", phone="+998900000002",
                      owner_user_id=master2.id)
        p_plumb = Provider(category_id=cat_plumber.id, name="Santexnik Hasan",
                           address="Toshkent 3", phone="+998900000003",
                           owner_user_id=master2.id)
        db.add_all([p1, p2, p_plumb])
        await db.commit()
        ids = dict(cat_e=cat_electric.id, cat_p=cat_plumber.id,
                   p1=p1.id, p2=p2.id, p_plumb=p_plumb.id,
                   m1=master1.id, m2=master2.id, client=client.id)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:

        async def login(phone, password="parol123"):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": password})
            assert r.status_code == 200, f"login {phone}: {r.status_code} {r.text[:200]}"
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        client_h = await login("+998901112233")
        m1_h = await login("+998902223344")
        m2_h = await login("+998903334455")
        out_h = await login("+998904445566")

        now = datetime.now(timezone.utc)

        # ── TALAB: mijoz e'lon beradi (rasm, summa, qachon) ───────────
        r = await c.post("/api/v1/jobs", headers=client_h, json={
            "category_id": ids["cat_e"],
            "title": "Rozetka almashtirish",
            "description": "Oshxonada 3 ta rozetka ishlamayapti",
            "photos": ["/uploads/jobs/job_1.jpg", "/uploads/jobs/job_2.jpg"],
            "address": "Toshkent, Chilonzor 5",
            "budget": 300000,
            "needed_at": (now + timedelta(days=2)).isoformat(),
            "expires_at": (now + timedelta(days=1)).isoformat(),
        })
        check("mijoz e'lon berdi", r.status_code == 201,
              f"{r.status_code} {r.text[:250]}")
        if r.status_code != 201:
            print("E'lon yaratilmadi, davom etib bo'lmaydi")
            for f in fail:
                print("  " + f)
            sys.exit(1)
        job = r.json()
        jid = job["id"]
        check("rasmlar saqlandi", len(job["photos"]) == 2, f"{job['photos']}")
        check("summa saqlandi", job["budget"] == 300000, f"{job['budget']}")
        check("muddat saqlandi", job["needed_at"] is not None)
        check("holat 'open'", job["status"] == "open", f"{job['status']}")

        # Validatsiya
        r = await c.post("/api/v1/jobs", headers=client_h, json={
            "category_id": ids["cat_e"], "title": "x",
            "description": "qisqa", "address": "a",
        })
        check("qisqa sarlavha rad etiladi", r.status_code == 422, f"{r.status_code}")

        r = await c.post("/api/v1/jobs", headers=client_h, json={
            "category_id": ids["cat_e"], "title": "O'tgan muddat",
            "description": "test tavsif", "address": "Toshkent",
            "expires_at": (now - timedelta(days=1)).isoformat(),
        })
        check("o'tgan muddat rad etiladi", r.status_code == 400, f"{r.status_code}")

        # ── TALAB: ustalar e'lonlarni ko'radi ─────────────────────────
        r = await c.get("/api/v1/jobs/feed", headers=m1_h,
                        params={"category_id": ids["cat_e"]})
        check("usta lentada e'lonni ko'radi",
              r.status_code == 200 and any(j["id"] == jid for j in r.json()),
              f"{r.status_code} {str(r.json())[:200]}")

        # Boshqa soha ustasi bu e'lonni ko'rmasligi kerak (filtr bilan)
        r = await c.get("/api/v1/jobs/feed", headers=m2_h,
                        params={"category_id": ids["cat_p"]})
        check("boshqa soha lentasida bu e'lon yo'q",
              r.status_code == 200 and not any(j["id"] == jid for j in r.json()),
              f"{str(r.json())[:150]}")

        # ── TALAB: usta taklif beradi ─────────────────────────────────
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m1_h, json={
            "provider_id": ids["p1"], "price": 250000,
            "duration_text": "1 kun", "message": "Bugun kelaman",
        })
        check("usta taklif berdi", r.status_code == 201,
              f"{r.status_code} {r.text[:200]}")
        offer1 = r.json() if r.status_code == 201 else {}
        check("taklifda chat uchun user_id bor",
              offer1.get("provider_owner_user_id") == ids["m1"],
              f"{offer1.get('provider_owner_user_id')} != {ids['m1']}")

        # Takroriy taklif
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m1_h, json={
            "provider_id": ids["p1"], "price": 200000,
        })
        check("bitta usta ikkinchi marta taklif bera olmaydi",
              r.status_code == 409, f"{r.status_code}")

        # Boshqa usta taklif beradi
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m2_h, json={
            "provider_id": ids["p2"], "price": 280000, "duration_text": "2 kun",
        })
        check("ikkinchi usta taklif berdi", r.status_code == 201, f"{r.status_code}")
        offer2 = r.json() if r.status_code == 201 else {}

        # ── Xavfsizlik: begona odam boshqa provayder nomidan ──────────
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=out_h, json={
            "provider_id": ids["p1"], "price": 100000,
        })
        check("begona odam boshqa provayder nomidan taklif bera olmaydi",
              r.status_code == 403, f"{r.status_code}")

        # Mijoz o'z e'loniga taklif bera olmaydi
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=client_h, json={
            "provider_id": ids["p1"], "price": 100000,
        })
        check("mijoz o'z e'loniga taklif bera olmaydi",
              r.status_code in (400, 403), f"{r.status_code}")

        # Boshqa soha provayderi
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m2_h, json={
            "provider_id": ids["p_plumb"], "price": 100000,
        })
        check("boshqa soha provayderi taklif bera olmaydi",
              r.status_code == 400, f"{r.status_code}")

        # Manfiy narx
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m1_h, json={
            "provider_id": ids["p1"], "price": -5,
        })
        check("manfiy narx rad etiladi", r.status_code == 422, f"{r.status_code}")

        # ── TALAB: mijoz takliflarni ko'radi ──────────────────────────
        r = await c.get(f"/api/v1/jobs/{jid}/offers", headers=client_h)
        check("mijoz takliflarni ko'radi",
              r.status_code == 200 and len(r.json()) == 2,
              f"{r.status_code} {len(r.json()) if r.status_code==200 else '?'}")
        offers = r.json() if r.status_code == 200 else []
        if offers:
            check("taklifda usta nomi va reytingi bor",
                  offers[0].get("provider_name") is not None
                  and "provider_rating" in offers[0],
                  f"{offers[0]}")

        # Begona odam takliflarni ko'ra olmaydi
        r = await c.get(f"/api/v1/jobs/{jid}/offers", headers=out_h)
        check("begona odam takliflarni ko'ra olmaydi", r.status_code == 403,
              f"{r.status_code}")

        # ── Usta o'z takliflarini ko'radi ─────────────────────────────
        r = await c.get("/api/v1/jobs/offers/my", headers=m1_h)
        check("usta o'z takliflarini ko'radi",
              r.status_code == 200 and len(r.json()) == 1,
              f"{r.status_code} {str(r.json())[:150]}")
        if r.status_code == 200 and r.json():
            check("taklif ichida e'lon ma'lumoti bor",
                  r.json()[0].get("job", {}).get("id") == jid,
                  f"{str(r.json()[0].get('job'))[:100]}")

        # ── TALAB: mijoz ustani tanlaydi ──────────────────────────────
        r = await c.post(
            f"/api/v1/jobs/{jid}/offers/{offer1['id']}/accept", headers=client_h)
        check("mijoz ustani tanladi",
              r.status_code == 200 and r.json()["status"] == "assigned",
              f"{r.status_code} {r.text[:200]}")
        check("tanlangan usta yozildi",
              r.json().get("assigned_provider_id") == ids["p1"],
              f"{r.json().get('assigned_provider_id')}")

        # Qolgan takliflar avtomatik rad etilishi kerak
        r = await c.get(f"/api/v1/jobs/{jid}/offers", headers=client_h)
        st = {o["id"]: o["status"] for o in r.json()}
        check("tanlangan taklif 'accepted'", st.get(offer1["id"]) == "accepted",
              f"{st}")
        check("qolgan taklif avtomatik 'rejected'",
              st.get(offer2["id"]) == "rejected", f"{st}")

        # Ikkinchi marta tanlab bo'lmaydi
        r = await c.post(
            f"/api/v1/jobs/{jid}/offers/{offer2['id']}/accept", headers=client_h)
        check("ikkinchi marta usta tanlab bo'lmaydi", r.status_code == 400,
              f"{r.status_code}")

        # Tanlangach yangi taklif qabul qilinmaydi
        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=m2_h, json={
            "provider_id": ids["p2"], "price": 150000,
        })
        check("yopilgan e'longa yangi taklif berib bo'lmaydi",
              r.status_code in (400, 409), f"{r.status_code}")

        # ── TALAB: bildirishnomalar ───────────────────────────────────
        async def notif_types(headers):
            r = await c.get("/api/v1/notifications", headers=headers)
            if r.status_code != 200:
                return None
            data = r.json()
            items = data.get("notifications", data) if isinstance(data, dict) else data
            return [n.get("type") for n in items]

        types = await notif_types(m1_h)
        check("tanlangan ustaga bildirishnoma keldi",
              types is not None and "job_accepted" in types, f"turlari={types}")

        types = await notif_types(m2_h)
        check("rad etilgan ustaga ham xabar keldi",
              types is not None and "job_rejected" in types, f"turlari={types}")

        types = await notif_types(client_h)
        check("mijozga yangi taklif haqida bildirishnoma keldi",
              types is not None and "job_offer" in types, f"turlari={types}")

        # ── TALAB: chat (mavjud messages tizimi) ──────────────────────
        r = await c.post("/api/v1/messages/send", headers=client_h, json={
            "recipient_id": ids["m1"],
            "text": "Assalomu alaykum, qachon kela olasiz?",
        })
        check("mijoz ustaga chat xabari yubordi", r.status_code in (200, 201),
              f"{r.status_code} {r.text[:200]}")

        # Usta SMS xonasida (yozishmalar ro'yxatida) ko'radi
        r = await c.get("/api/v1/messages/conversations", headers=m1_h)
        check("usta SMS xonasida yozishmani ko'radi",
              r.status_code == 200 and len(
                  r.json().get("conversations", r.json())
                  if isinstance(r.json(), dict) else r.json()) > 0,
              f"{r.status_code} {str(r.json())[:200]}")

        # O'qilmagan xabar soni (bildirishnoma nishoni uchun)
        r = await c.get("/api/v1/messages/unread-count", headers=m1_h)
        check("o'qilmagan xabar soni ko'rinadi", r.status_code == 200,
              f"{r.status_code}")

        # ── Ishni yakunlash ───────────────────────────────────────────
        r = await c.post(f"/api/v1/jobs/{jid}/complete", headers=out_h)
        check("begona odam ishni yakunlay olmaydi", r.status_code == 403,
              f"{r.status_code}")

        r = await c.post(f"/api/v1/jobs/{jid}/complete", headers=client_h)
        check("mijoz ishni yakunladi",
              r.status_code == 200 and r.json()["status"] == "completed",
              f"{r.status_code} {r.text[:150]}")

        # ── Bekor qilish ──────────────────────────────────────────────
        r = await c.post("/api/v1/jobs", headers=client_h, json={
            "category_id": ids["cat_e"], "title": "Bekor qilinadigan ish",
            "description": "test tavsif matni", "address": "Toshkent",
        })
        jid2 = r.json()["id"]
        r = await c.delete(f"/api/v1/jobs/{jid2}", headers=out_h)
        check("begona odam e'lonni bekor qila olmaydi", r.status_code == 403,
              f"{r.status_code}")
        r = await c.delete(f"/api/v1/jobs/{jid2}", headers=client_h)
        check("mijoz e'lonni bekor qildi",
              r.status_code == 200 and r.json()["status"] == "cancelled",
              f"{r.status_code}")
        r = await c.post(f"/api/v1/jobs/{jid2}/offers", headers=m1_h, json={
            "provider_id": ids["p1"], "price": 100000,
        })
        check("bekor qilingan e'longa taklif berib bo'lmaydi",
              r.status_code == 400, f"{r.status_code}")

        # ── Taklifni qaytarib olish ───────────────────────────────────
        r = await c.post("/api/v1/jobs", headers=client_h, json={
            "category_id": ids["cat_e"], "title": "Uchinchi ish",
            "description": "test tavsif matni", "address": "Toshkent",
        })
        jid3 = r.json()["id"]
        r = await c.post(f"/api/v1/jobs/{jid3}/offers", headers=m1_h, json={
            "provider_id": ids["p1"], "price": 120000,
        })
        oid3 = r.json()["id"]
        r = await c.delete(f"/api/v1/jobs/offers/{oid3}", headers=out_h)
        check("begona odam taklifni qaytarib ola olmaydi", r.status_code == 403,
              f"{r.status_code}")
        r = await c.delete(f"/api/v1/jobs/offers/{oid3}", headers=m1_h)
        check("usta taklifini qaytarib oldi",
              r.status_code == 200 and r.json()["status"] == "withdrawn",
              f"{r.status_code} {r.text[:150]}")

        # ── ADMIN MONITORING (4-vazifa) ───────────────────────────────
        # Admin panelda ilgari KO'RINMAYDIGAN ma'lumotlar
        async with async_session() as db:
            adm = User(name="Admin", surname="Test", phone="admin",
                       hashed_password=hash_password("admin123"),
                       is_admin=True, is_super_admin=True)
            db.add(adm)
            await db.commit()
        adm_h = await login("admin", "admin123")

        r = await c.get("/api/v1/admin/monitoring/jobs", headers=adm_h)
        check("admin ish e'lonlarini ko'radi", r.status_code == 200,
              f"{r.status_code} {r.text[:200]}")
        if r.status_code == 200:
            d = r.json()
            check("monitoring: e'lonlar ro'yxati bor", "items" in d, f"{list(d)}")
            check("monitoring: konversiya hisoblanadi",
                  "conversion_percent" in d.get("summary", {}),
                  f"{d.get('summary')}")

        r = await c.get("/api/v1/admin/monitoring/fraud", headers=adm_h)
        check("admin firibgarlik statistikasini ko'radi", r.status_code == 200,
              f"{r.status_code} {r.text[:200]}")

        r = await c.get("/api/v1/admin/monitoring/push-reach", headers=adm_h)
        check("admin push qamrovini ko'radi", r.status_code == 200,
              f"{r.status_code} {r.text[:200]}")
        if r.status_code == 200:
            d = r.json()
            check("push qamrovi foizda hisoblanadi", "reach_percent" in d, f"{list(d)}")

        r = await c.get("/api/v1/admin/monitoring/blocked-users", headers=adm_h)
        check("admin bloklangan mijozlarni ko'radi", r.status_code == 200,
              f"{r.status_code}")

        r = await c.get("/api/v1/admin/monitoring/activity", headers=adm_h)
        check("admin faollik statistikasini ko'radi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")

        # Oddiy foydalanuvchi monitoringga kira olmaydi
        r = await c.get("/api/v1/admin/monitoring/fraud", headers=client_h)
        check("oddiy user monitoringni ko'ra olmaydi", r.status_code == 403,
              f"{r.status_code}")

        # ── Autentifikatsiyasiz ───────────────────────────────────────
        r = await c.get("/api/v1/jobs/feed")
        check("tokensiz lentani ko'rib bo'lmaydi", r.status_code in (401, 403),
              f"{r.status_code}")

    await engine.dispose()

    print(f"\nO'TDI ({len(ok)}):")
    for o in ok:
        print(f"  {o}")
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for f in fail:
            print(f"  {f}")
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")


asyncio.run(main())
