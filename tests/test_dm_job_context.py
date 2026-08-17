"""Chatni ish e'loniga bog'lash va real vaqtda yetkazish.

Foydalanuvchi talabi:
    "usta elon bo'yicha kirib yozganda narigi oddiy foydalanuvchi
     tomonida chat maydonida shu elon bilan kelgan dep chiqarib
     qo'yishi kerak"
    "chatni o'zida taklif bergan ustalarni yulduzchalari va
     malumotlar bo'lishi kerak"

Ilgari `DirectMessage` da e'lon bilan bog'lovchi maydon YO'Q edi,
ya'ni mijoz xabar qaysi e'lon haqida ekanini bilmasdi. Bir vaqtda
3 ta e'loni bo'lsa, kim nima haqida yozayotgani chalkashardi.

Bundan tashqari xabar yuborilganda WebSocket'ga UMUMAN yuborilmasdi:
qabul qiluvchi ilovani qayta ochmaguncha xabarni ko'rmasdi.
"""
import asyncio
import os
import sys

DB = os.environ.get("SUPERAPP_TEST_DB")
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
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.user import User

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    # ── Migratsiya: ustun haqiqatan yaratildimi ──────────────────────
    async with engine.begin() as conn:
        row = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name='direct_messages' AND column_name='job_id'"
        ))
        check("direct_messages.job_id ustuni bor",
              row.first() is not None, "ustun topilmadi")

    app = create_app()

    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        client = User(name="Mijoz", surname="T", phone="+998900001111",
                      hashed_password=hash_password("parol123"))
        master = User(name="Usta Aziz", surname="T", phone="+998900002222",
                      hashed_password=hash_password("parol123"))
        stranger = User(name="Begona", surname="T", phone="+998900003333",
                        hashed_password=hash_password("parol123"))
        db.add_all([cat, client, master, stranger])
        await db.flush()

        prov = Provider(category_id=cat.id, name="Aziz elektrik",
                        address="Toshkent, Yunusobod", phone="+998901111111",
                        owner_user_id=master.id, rating=4.8, review_count=15)
        db.add(prov)
        await db.commit()
        cid, uid, mid, sid = cat.id, client.id, master.id, stranger.id

    async with AsyncClient(transport=ASGITransport(app=app),
                           base_url="http://t") as c:
        async def login(phone):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": "parol123"})
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        h_client = await login("+998900001111")
        h_master = await login("+998900002222")
        h_stranger = await login("+998900003333")

        # Mijoz e'lon beradi
        r = await c.post("/api/v1/jobs", headers=h_client, json={
            "category_id": cid,
            "title": "Rozetka almashtirish",
            "description": "Uchta rozetka kuyib qolgan",
            "address": "Toshkent, Chilonzor 5",
        })
        check("e'lon yaratildi", r.status_code == 201, f"{r.status_code}")
        jid = r.json().get("id")

        # ── Usta e'lon orqali yozadi ─────────────────────────────────
        r = await c.post("/api/v1/messages/send", headers=h_master, json={
            "recipient_id": uid,
            "text": "Salom, bu ishni bugun qila olaman",
            "job_id": jid,
        })
        check("usta e'lon orqali xabar yubordi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        if r.status_code == 200:
            body = r.json()
            check("javobda job_id qaytadi", body.get("job_id") == jid,
                  f"{body.get('job_id')}")
            check("javobda e'lon nomi bor ('bu e'lon bo'yicha' uchun)",
                  body.get("job", {}).get("title") == "Rozetka almashtirish",
                  f"{body.get('job')}")

        # ── Mijoz tomonida ko'rinishi ────────────────────────────────
        r = await c.get(f"/api/v1/messages/thread/{mid}", headers=h_client)
        check("mijoz yozishmani ochdi", r.status_code == 200, f"{r.status_code}")
        thread = r.json() if r.status_code == 200 else {}
        msgs = thread.get("messages", [])
        check("xabar ko'rinadi", len(msgs) == 1, f"{len(msgs)} ta")
        if msgs:
            check("mijoz tomonida ham e'lon nomi ko'rinadi",
                  msgs[0].get("job", {}).get("title") == "Rozetka almashtirish",
                  f"{msgs[0].get('job')}")
            check("xabar mijozniki emas deb belgilanadi",
                  msgs[0].get("is_mine") is False, f"{msgs[0].get('is_mine')}")

        # ── Ustaning yulduzchalari va ma'lumotlari ───────────────────
        pp = thread.get("peer_provider")
        check("chatda ustaning profili ko'rinadi", pp is not None, "yo'q")
        if pp:
            check("ustaning reytingi (yulduzchalari) ko'rinadi",
                  pp.get("rating") == 4.8, f"{pp.get('rating')}")
            check("sharhlar soni ko'rinadi",
                  pp.get("review_count") == 15, f"{pp.get('review_count')}")
            check("usta nomi ko'rinadi",
                  pp.get("name") == "Aziz elektrik", f"{pp.get('name')}")
            check("profilga o'tish uchun provider_id bor",
                  pp.get("id") is not None, "id yo'q")

        # ── Oddiy xabar (e'lonsiz) ham ishlaydi ──────────────────────
        r = await c.post("/api/v1/messages/send", headers=h_client, json={
            "recipient_id": mid,
            "text": "Rahmat, kutaman",
        })
        check("e'lonsiz oddiy xabar ham ishlaydi", r.status_code == 200,
              f"{r.status_code}")
        if r.status_code == 200:
            check("e'lonsiz xabarda job_id null",
                  r.json().get("job_id") is None, f"{r.json().get('job_id')}")
            check("e'lonsiz xabarda job konteksti yo'q",
                  "job" not in r.json(), "ortiqcha kalit bor")

        # ── XAVFSIZLIK: begona odam e'lonni bog'lay olmaydi ──────────
        # Aks holda istalgan odam boshqa birovning e'lon nomini
        # chatga chiqarib, ishonch qozonishga urinardi.
        r = await c.post("/api/v1/messages/send", headers=h_stranger, json={
            "recipient_id": mid,
            "text": "Men ham shu ish haqida",
            "job_id": jid,
        })
        check("begona odam e'lonni bog'lay OLMAYDI", r.status_code == 403,
              f"{r.status_code} {r.text[:120]}")

        # ── Mavjud bo'lmagan e'lon ───────────────────────────────────
        r = await c.post("/api/v1/messages/send", headers=h_master, json={
            "recipient_id": uid, "text": "test", "job_id": 999999,
        })
        check("mavjud bo'lmagan e'lon -> 404", r.status_code == 404,
              f"{r.status_code}")

        # ── E'lon egasi ham bog'lay oladi ────────────────────────────
        r = await c.post("/api/v1/messages/send", headers=h_client, json={
            "recipient_id": mid,
            "text": "Qachon kelasiz?",
            "job_id": jid,
        })
        check("e'lon egasi ham bog'lay oladi", r.status_code == 200,
              f"{r.status_code}")

        # ── Yozishmalar ro'yxati buzilmaganini tekshirish ────────────
        r = await c.get("/api/v1/messages/conversations", headers=h_client)
        check("yozishmalar ro'yxati ishlaydi", r.status_code == 200,
              f"{r.status_code}")
        check("ro'yxatda usta bor",
              r.status_code == 200 and len(r.json()) >= 1,
              f"{len(r.json()) if r.status_code == 200 else '?'}")

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
