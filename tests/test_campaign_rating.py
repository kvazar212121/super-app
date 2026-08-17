"""Sezonli reyting (aksiya) tizimini HAQIQIY HTTP so'rovlar bilan sinaydi.

Foydalanuvchi talabi (asl so'zlari bilan):
  - reyting 1 sezondagi reyting bo'lishi kerak
  - aksiya doirasida, sovrinli
  - 5 yulduzcha qo'ygan ham, 1 yulduzcha qo'ygan ham 1 TA OVOZ
  - bir kishi faqat 1 ta sartaroshga bera oladi
  - qaysidir kundan boshlanadi
  - adminkadan aksiya e'lon qiladigan joy

Har bir talab shu yerda alohida tekshiriladi.

HAQIQIY PostgreSQL kerak:
    SUPERAPP_TEST_DB=postgresql+asyncpg://user:pass@host:port/db
Berilmasa SKIP qilinadi.
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
os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
# Testda SMS OTP yuborib bo'lmaydi — parol bilan kirishga ruxsat beramiz.
# Bu FAQAT test muhitida, prod sozlamasi o'zgarmaydi.
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from httpx import ASGITransport, AsyncClient

    from app.main import create_app
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.core.security import hash_password
    from app.models.user import User
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.campaign import Campaign, CampaignVote

    # Toza sxema.
    # drop_all ishlamaydi: modellarda o'zaro FK halqasi bor
    # (finance_groups <-> users), SQLAlchemy tartiblay olmaydi.
    # Shuning uchun butun schema'ni CASCADE bilan tashlaymiz.
    from sqlalchemy import text
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    # ── Sinov ma'lumotlari ────────────────────────────────────────────
    async with async_session() as db:
        # is_super_admin: RBAC'da super-admin barcha bo'limlarga ruxsatli
        admin = User(name="Admin", surname="Test", phone="admin",
                     hashed_password=hash_password("admin123"),
                     is_admin=True, is_super_admin=True)
        u1 = User(name="Ali", surname="Valiyev", phone="+998901112233",
                  hashed_password=hash_password("parol123"))
        u2 = User(name="Vali", surname="Aliyev", phone="+998904445566",
                  hashed_password=hash_password("parol123"))
        cat_barber = Category(key="barber", title_uz="Sartaroshxona", icon="cut")
        cat_other = Category(key="football", title_uz="Futbol maydoni", icon="ball")
        db.add_all([admin, u1, u2, cat_barber, cat_other])
        await db.flush()

        p1 = Provider(category_id=cat_barber.id, name="Sartarosh A",
                      address="Toshkent 1", phone="+998900000001")
        p2 = Provider(category_id=cat_barber.id, name="Sartarosh B",
                      address="Toshkent 2", phone="+998900000002")
        p_other = Provider(category_id=cat_other.id, name="Maydon C",
                           address="Toshkent 3", phone="+998900000003")
        db.add_all([p1, p2, p_other])
        await db.commit()
        ids = dict(barber=cat_barber.id, other=cat_other.id,
                   p1=p1.id, p2=p2.id, p_other=p_other.id)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:

        async def make_user(phone, name):
            """Qo'shimcha mijoz yaratadi. Register endpointi OTP talab
            qilishi mumkin, shuning uchun to'g'ridan-to'g'ri bazaga."""
            async with async_session() as db:
                db.add(User(name=name, surname="Test", phone=phone,
                            hashed_password=hash_password("parol123")))
                await db.commit()
            return await login(phone, "parol123")

        async def login(phone, password):
            r = await c.post("/api/v1/auth/login",
                             json={"phone": phone, "password": password})
            assert r.status_code == 200, f"login {phone}: {r.status_code} {r.text[:200]}"
            return {"Authorization": f"Bearer {r.json()['access_token']}"}

        admin_h = await login("admin", "admin123")
        u1_h = await login("+998901112233", "parol123")
        u2_h = await login("+998904445566", "parol123")

        now = datetime.now(timezone.utc)

        # ── TALAB: adminkadan aksiya e'lon qilish ─────────────────────
        r = await c.post("/api/v1/admin/campaigns", headers=admin_h, json={
            "title": "Eng yaxshi sartarosh — Sentabr",
            "description": "Oylik musobaqa",
            "category_id": ids["barber"],
            "starts_at": (now - timedelta(days=1)).isoformat(),
            "ends_at": (now + timedelta(days=29)).isoformat(),
            "prize": "1-o'rin: 5 000 000 so'm",
            # Mavjud tekshiruvlar buyurtmasiz ishlashi uchun himoyani
            # o'chiramiz; himoyaning O'ZI pastda alohida sinaladi.
            "require_completed_order": False,
        })
        check("admin aksiya yaratdi", r.status_code == 201,
              f"{r.status_code} {r.text[:200]}")
        camp = r.json()
        if "id" not in camp:
            print("Aksiya yaratilmadi, javob:", r.status_code, str(camp)[:400])
            sys.exit(1)
        cid = camp["id"]
        check("aksiya holati 'running'", camp.get("status") == "running",
              f"status={camp.get('status')}")

        # ── TALAB: oddiy foydalanuvchi aksiya yarata OLMASLIGI kerak ──
        r = await c.post("/api/v1/admin/campaigns", headers=u1_h, json={
            "title": "Yolg'on aksiya",
            "starts_at": now.isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),
        })
        check("oddiy user aksiya yarata olmaydi", r.status_code == 403,
              f"{r.status_code}")

        # ── Validatsiya: tugash sanasi boshlanishdan oldin ────────────
        r = await c.post("/api/v1/admin/campaigns", headers=admin_h, json={
            "title": "Teskari sana",
            "starts_at": (now + timedelta(days=5)).isoformat(),
            "ends_at": now.isoformat(),
        })
        check("teskari sana rad etiladi", r.status_code == 400, f"{r.status_code}")

        # ── TALAB: foydalanuvchi aksiyani ko'ra oladi ─────────────────
        r = await c.get("/api/v1/campaigns/active")
        check("faol aksiya ko'rinadi",
              r.status_code == 200 and r.json() and r.json()["id"] == cid,
              f"{r.status_code} {r.text[:150]}")

        # ── TALAB: 1 kishi = 1 ovoz (yulduz soni ahamiyatsiz) ─────────
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=u1_h,
                         json={"provider_id": ids["p1"]})
        check("u1 ovoz berdi", r.status_code == 201, f"{r.status_code} {r.text[:200]}")

        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=u1_h,
                         json={"provider_id": ids["p2"]})
        check("u1 IKKINCHI marta ovoz bera olmaydi", r.status_code == 409,
              f"{r.status_code} {r.text[:150]}")

        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=u1_h,
                         json={"provider_id": ids["p1"]})
        check("u1 o'sha providerga ham qayta bera olmaydi", r.status_code == 409,
              f"{r.status_code}")

        # u2 boshqa odam — bera olishi kerak
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=u2_h,
                         json={"provider_id": ids["p1"]})
        check("u2 (boshqa odam) ovoz berdi", r.status_code == 201, f"{r.status_code}")

        # ── Autentifikatsiyasiz ovoz berib bo'lmaydi ──────────────────
        r = await c.post(f"/api/v1/campaigns/{cid}/vote",
                         json={"provider_id": ids["p1"]})
        check("tokensiz ovoz berib bo'lmaydi", r.status_code in (401, 403),
              f"{r.status_code}")

        # ── TALAB: kategoriya chegarasi ───────────────────────────────
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=admin_h,
                         json={"provider_id": ids["p_other"]})
        check("boshqa kategoriya provayderiga ovoz berib bo'lmaydi",
              r.status_code == 400, f"{r.status_code} {r.text[:150]}")

        # Mavjud bo'lmagan provayder
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=admin_h,
                         json={"provider_id": 999999})
        check("mavjud bo'lmagan provayder -> 404", r.status_code == 404,
              f"{r.status_code}")

        # ── TALAB: reyting OVOZ soni bo'yicha ─────────────────────────
        r = await c.get(f"/api/v1/campaigns/{cid}/leaderboard")
        check("reyting olindi", r.status_code == 200, f"{r.status_code}")
        board = r.json()
        check("reytingda 1 ta provayder (2 ovoz olgani)", len(board) == 1,
              f"{len(board)} ta: {str(board)[:300]}")
        if board:
            check("1-o'rin: Sartarosh A, 2 ovoz",
                  board[0]["id"] == ids["p1"] and board[0]["votes"] == 2
                  and board[0]["position"] == 1,
                  f"{board[0]}")

        # ── my-vote: UI tugma holati ──────────────────────────────────
        r = await c.get(f"/api/v1/campaigns/{cid}/my-vote", headers=u1_h)
        check("my-vote: u1 ovoz bergan",
              r.status_code == 200 and r.json()["has_voted"] is True
              and r.json()["provider_id"] == ids["p1"], f"{r.text[:150]}")

        # ── TALAB: aksiya "qaysidir kundan boshlanadi" ────────────────
        r = await c.post("/api/v1/admin/campaigns", headers=admin_h, json={
            "title": "Kelasi oy aksiyasi",
            "category_id": ids["barber"],
            "starts_at": (now + timedelta(days=10)).isoformat(),
            "ends_at": (now + timedelta(days=40)).isoformat(),
        })
        future_id = r.json()["id"]
        check("kelajakdagi aksiya 'upcoming'", r.json()["status"] == "upcoming",
              f"{r.json().get('status')}")
        r = await c.post(f"/api/v1/campaigns/{future_id}/vote", headers=u1_h,
                         json={"provider_id": ids["p1"]})
        check("boshlanmagan aksiyaga ovoz berib bo'lmaydi", r.status_code == 400,
              f"{r.status_code} {r.text[:150]}")

        # ── Tugagan aksiya ────────────────────────────────────────────
        r = await c.post("/api/v1/admin/campaigns", headers=admin_h, json={
            "title": "O'tgan oy aksiyasi",
            "category_id": ids["barber"],
            "starts_at": (now - timedelta(days=40)).isoformat(),
            "ends_at": (now - timedelta(days=10)).isoformat(),
        })
        past_id = r.json()["id"]
        check("tugagan aksiya 'finished'", r.json()["status"] == "finished",
              f"{r.json().get('status')}")
        r = await c.post(f"/api/v1/campaigns/{past_id}/vote", headers=u1_h,
                         json={"provider_id": ids["p1"]})
        check("tugagan aksiyaga ovoz berib bo'lmaydi", r.status_code == 400,
              f"{r.status_code}")

        # ── Admin to'xtatib qo'ysa ────────────────────────────────────
        r = await c.patch(f"/api/v1/admin/campaigns/{cid}", headers=admin_h,
                          json={"is_active": False})
        check("admin aksiyani to'xtatdi",
              r.status_code == 200 and r.json()["status"] == "disabled",
              f"{r.status_code} {r.text[:150]}")
        # u2 allaqachon ovoz bergan, uchinchi odam kerak -> admin bilan sinaymiz
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=admin_h,
                         json={"provider_id": ids["p1"]})
        check("to'xtatilgan aksiyaga ovoz berib bo'lmaydi", r.status_code == 400,
              f"{r.status_code}")
        # qaytarib yoqamiz
        await c.patch(f"/api/v1/admin/campaigns/{cid}", headers=admin_h,
                      json={"is_active": True})

        # ── TALAB: ovozlar aksiya tugagach ham saqlanadi (arxiv) ──────
        r = await c.get(f"/api/v1/campaigns/{past_id}/leaderboard")
        check("tugagan aksiya reytingi ham ochiladi", r.status_code == 200,
              f"{r.status_code}")

        # ── Admin ro'yxatida ovoz soni ────────────────────────────────
        r = await c.get("/api/v1/admin/campaigns", headers=admin_h)
        check("admin ro'yxati olindi", r.status_code == 200, f"{r.status_code}")
        rows = r.json() if r.status_code == 200 else []
        cur = [x for x in rows if x["id"] == cid]
        check("admin ro'yxatida vote_count=2",
              cur and cur[0].get("vote_count") == 2,
              f"{cur[0] if cur else 'yo`q'}")

        # ── TALAB: "sovrinlar bo'ladi" — sovrin matni saqlanib, mijozga
        # ko'rinadigan ochiq endpointda ham qaytishi kerak, aks holda
        # foydalanuvchi nima uchun ovoz berayotganini bilmaydi ──────────
        r = await c.get("/api/v1/campaigns/active")
        cur_pub = r.json() if r.status_code == 200 else None
        check("ochiq /active aynan shu faol aksiyani qaytaradi",
              isinstance(cur_pub, dict) and cur_pub.get("id") == cid,
              f"{str(cur_pub)[:150]}")
        check("ochiq javobda sovrin matni ko'rinadi",
              isinstance(cur_pub, dict)
              and cur_pub.get("prize") == "1-o'rin: 5 000 000 so'm",
              f"{cur_pub.get('prize') if isinstance(cur_pub, dict) else cur_pub}")
        check("ochiq javobda muddat (ends_at) ko'rinadi",
              isinstance(cur_pub, dict) and cur_pub.get("ends_at"),
              "ends_at yo'q")

        # ── TALAB: "eng ko'p ovoz to'plagan g'olib bo'ladi" ────────────
        # Teng ovozda tartib BARQAROR bo'lishi shart: pul sovrinli
        # musobaqada har so'rovda g'olib almashsa nizo kelib chiqadi.
        # p1 da 2 ovoz bor; p2 ga 2 ovoz beramiz (yangi 2 mijoz).
        tie_hs = []
        for i, phone in enumerate(["+998911112201", "+998911112202"]):
            tie_hs.append(await make_user(phone, f"Teng {i}"))
        for h in tie_hs:
            r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=h,
                             json={"provider_id": ids["p2"]})
            check(f"teng-ovoz uchun ovoz berildi", r.status_code == 201,
                  f"{r.status_code} {r.text[:150]}")

        boards = []
        for _ in range(3):
            r = await c.get(f"/api/v1/campaigns/{cid}/leaderboard")
            boards.append([(x["id"], x["votes"]) for x in r.json()])
        check("teng ovozda ikkala provayder 2 tadan",
              boards[0] and sorted(v for _, v in boards[0]) == [2, 2],
              f"{boards[0]}")
        check("teng ovozda tartib barqaror (g'olib almashmaydi)",
              boards[0] == boards[1] == boards[2],
              f"{boards}")
        check("teng ovozda oldin ro'yxatdan o'tgan (kichik id) yuqorida",
              boards[0] and boards[0][0][0] == min(ids["p1"], ids["p2"]),
              f"{boards[0]}")

        # ── Ovoz sanog'i haqiqiy: uchinchi provayderga 1 ovoz ──────────
        h3 = await make_user("+998911112203", "Uch")
        r = await c.post(f"/api/v1/campaigns/{cid}/vote", headers=h3,
                         json={"provider_id": ids["p1"]})
        r = await c.get(f"/api/v1/campaigns/{cid}/leaderboard")
        top = r.json()[0] if r.status_code == 200 and r.json() else {}
        check("ko'proq ovoz olgan 1-o'ringa chiqadi",
              top.get("id") == ids["p1"] and top.get("votes") == 3,
              f"{top.get('id')}/{top.get('votes')}")

        # ── TALAB: "bir kishi bitta ovoz" — PARALLEL so'rovlarda ham ───
        # 409 tekshiruvi ketma-ket so'rovni sinaydi; haqiqiy hujum esa
        # bir vaqtda yuboriladi. UNIQUE(campaign_id, user_id) cheklovi
        # shu holatni ushlashi kerak (aks holda pul sovrini o'g'irlanadi).
        race_h = await make_user("+998911112204", "Poyga")
        results = await asyncio.gather(*[
            c.post(f"/api/v1/campaigns/{cid}/vote", headers=race_h,
                   json={"provider_id": ids["p1"]})
            for _ in range(5)
        ], return_exceptions=True)
        codes = [getattr(x, "status_code", type(x).__name__) for x in results]
        check("parallel 5 ta ovozdan faqat BITTASI o'tadi",
              codes.count(201) == 1, f"{codes}")
        check("parallel qolganlari 500 emas (toza xato)",
              all(x == 201 or x == 409 for x in codes), f"{codes}")

        # Admin ro'yxatidagi vote_count yangi ovozlar bilan yangilanadimi:
        # yuqorida 2 edi, keyin 4 ta ovoz qo'shildi (p2 ga 2, p1 ga 2).
        r = await c.get("/api/v1/admin/campaigns", headers=admin_h)
        rows2 = r.json() if r.status_code == 200 else []
        cur2 = [x for x in rows2 if x["id"] == cid]
        check("admin vote_count yangi ovozlarni hisobga oladi (6)",
              cur2 and cur2[0].get("vote_count") == 6,
              f"{cur2[0].get('vote_count') if cur2 else 'yo`q'}")

        # ── DOIMIY reyting o'zgarmaganini tasdiqlash ──────────────────
        r = await c.get(f"/api/v1/providers/{ids['p1']}")
        check("doimiy reyting (Provider.rating) o'zgarmadi",
              r.status_code == 200 and r.json()["rating"] == 0.0
              and r.json()["review_count"] == 0,
              f"{r.json() if r.status_code==200 else r.status_code}")

        # ── SOXTA OVOZGA QARSHI HIMOYA ────────────────────────────────
        # Sovrin pul bo'lgani uchun eng muhim qism: faqat haqiqiy mijoz
        # (o'sha provayderda yakunlangan buyurtmasi bor odam) ovoz bera
        # olishi kerak.
        r = await c.post("/api/v1/admin/campaigns", headers=admin_h, json={
            "title": "Faqat mijozlar uchun aksiya",
            "category_id": ids["barber"],
            "starts_at": (now - timedelta(days=1)).isoformat(),
            "ends_at": (now + timedelta(days=20)).isoformat(),
            "require_completed_order": True,
        })
        strict_id = r.json()["id"]
        check("himoyali aksiya yaratildi",
              r.status_code == 201 and r.json().get("require_completed_order") is True,
              f"{r.status_code} {str(r.json())[:200]}")

        # u2 bu provayderda BUYURTMA BERMAGAN -> ovoz bera olmasligi kerak
        r = await c.post(f"/api/v1/campaigns/{strict_id}/vote", headers=u2_h,
                         json={"provider_id": ids["p1"]})
        check("buyurtmasiz odam ovoz BERA OLMAYDI", r.status_code == 403,
              f"{r.status_code} {r.text[:200]}")

        # Endi u2 uchun YAKUNLANGAN buyurtma yaratamiz
        async with async_session() as db:
            from sqlalchemy import select
            from app.models.order import Order, OrderStatus
            u2row = (await db.execute(
                select(User).where(User.phone == "+998904445566")
            )).scalar_one()
            db.add(Order(
                user_id=u2row.id,
                category_id=ids["barber"],
                provider_id=ids["p1"],
                service_name="Soch olish",
                address="Toshkent, test",
                date=datetime.now(),
                price=50000,
                status=OrderStatus.completed,
            ))
            await db.commit()

        r = await c.post(f"/api/v1/campaigns/{strict_id}/vote", headers=u2_h,
                         json={"provider_id": ids["p1"]})
        check("yakunlangan buyurtmasi bor mijoz ovoz BERA OLADI",
              r.status_code == 201, f"{r.status_code} {r.text[:200]}")

        # Ammo BOSHQA provayderga baribir bera olmaydi (u yerda buyurtma yo'q).
        # u2 allaqachon ovoz bergani uchun 409, u1 bilan sinaymiz.
        r = await c.post(f"/api/v1/campaigns/{strict_id}/vote", headers=u1_h,
                         json={"provider_id": ids["p2"]})
        check("boshqa provayderga buyurtmasiz ovoz berib bo'lmaydi",
              r.status_code == 403, f"{r.status_code}")

        # ── update() False qiymatni SAQLAY oladimi ────────────────────
        # (`if v is not None` xatosi bo'lsa aksiyani to'xtatib bo'lmasdi)
        r = await c.patch(f"/api/v1/admin/campaigns/{strict_id}", headers=admin_h,
                          json={"require_completed_order": False})
        check("require_completed_order=False saqlanadi",
              r.status_code == 200 and r.json().get("require_completed_order") is False,
              f"{r.status_code} {str(r.json())[:200]}")

        # endi u1 buyurtmasiz ham bera oladi
        r = await c.post(f"/api/v1/campaigns/{strict_id}/vote", headers=u1_h,
                         json={"provider_id": ids["p2"]})
        check("himoya o'chirilgach buyurtmasiz ovoz beriladi",
              r.status_code == 201, f"{r.status_code} {r.text[:150]}")

        # ── Admin panel sahifasi yuklanadimi ──────────────────────────
        r = await c.get("/admin")
        check("admin panel sahifasi ochiladi",
              r.status_code == 200 and 'data-page="campaigns"' in r.text,
              f"{r.status_code}, sovrinli reyting nav'da="
              f"{('data-page=' + chr(34) + 'campaigns' + chr(34)) in r.text}")

        # ── O'chirish ─────────────────────────────────────────────────
        r = await c.delete(f"/api/v1/admin/campaigns/{past_id}", headers=admin_h)
        check("admin aksiyani o'chirdi", r.status_code == 204, f"{r.status_code}")
        r = await c.get(f"/api/v1/campaigns/{past_id}")
        check("o'chirilgan aksiya 404", r.status_code == 404, f"{r.status_code}")

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
