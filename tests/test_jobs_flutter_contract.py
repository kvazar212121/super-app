"""Flutter modeli backend javobiga MOS kelishini jonli tekshirish.

Flutter'da yo'q maydonni o'qish jimgina null beradi (masalan e'lon
kartasida "0 taklif" yoki usta nomi bo'sh ko'rinadi), analyze ham,
backend testi ham buni ushlamaydi. Shuning uchun haqiqiy javob
kalitlarini Dart modeli kutayotgan kalitlar bilan solishtiramiz.
"""
import asyncio, os, re, sys
DB = os.environ["SUPERAPP_TEST_DB"]

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJ, "backend"))
os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

from datetime import datetime, timedelta, timezone
from httpx import AsyncClient, ASGITransport
from app.main import create_app
from app.db.base import Base
from app.db.session import async_session, engine
from app.core.security import hash_password
from app.models.user import User
from app.models.category import Category
from app.models.provider import Provider
from sqlalchemy import text

ok, fail = [], []
def check(n, c, d=""):
    (ok if c else fail).append(f"{n}{'' if c else ': ' + d}")

def dart_keys(cls):
    src = open(os.path.join(PROJ, "lib/models/job.dart")).read()
    i = src.index(f"factory {cls}.fromJson")
    j = src.index("\n      );", i)
    return set(re.findall(r"json\['([a-z_]+)'\]", src[i:j]))

async def main():
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)
    app = create_app()
    async with async_session() as db:
        cat = Category(key="electrician", title_uz="Elektrik", icon="e")
        u = User(name="Mijoz", surname="T", phone="+998900000011",
                 hashed_password=hash_password("parol123"))
        pu = User(name="Usta", surname="T", phone="+998900000012",
                  hashed_password=hash_password("parol123"))
        db.add_all([cat, u, pu]); await db.flush()
        p = Provider(category_id=cat.id, name="Usta A", address="T",
                     phone="+998900000013", owner_user_id=pu.id)
        db.add(p); await db.commit()
        cid, pid = cat.id, p.id

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as c:
        async def login(ph):
            r = await c.post("/api/v1/auth/login", json={"phone": ph, "password": "parol123"})
            return {"Authorization": f"Bearer {r.json()['access_token']}"}
        h, ph_ = await login("+998900000011"), await login("+998900000012")

        r = await c.post("/api/v1/jobs", headers=h, json={
            "category_id": cid, "title": "Rozetka almashtirish",
            "description": "Uchta rozetka kuyib qolgan",
            "address": "Toshkent, Chilonzor 5", "budget": 200000,
            "needed_at": (datetime.now(timezone.utc)+timedelta(days=2)).isoformat(),
        })
        check("e'lon yaratildi", r.status_code == 201, f"{r.status_code} {r.text[:200]}")
        job = r.json(); jid = job.get("id")

        missing = dart_keys("JobPost") - set(job.keys())
        check("JobPost: Dart kutgan barcha maydon javobda bor",
              not missing, f"yetishmaydi: {sorted(missing)}")

        r = await c.get("/api/v1/jobs/my", headers=h)
        check("/jobs/my ro'yxatida ham to'liq maydon",
              r.status_code == 200 and r.json()
              and not (dart_keys("JobPost") - set(r.json()[0].keys())),
              f"{r.status_code}")

        r = await c.get(f"/api/v1/jobs/feed?category_id={cid}", headers=ph_)
        check("usta lentasida e'lon ko'rinadi",
              r.status_code == 200 and any(x["id"] == jid for x in r.json()),
              f"{r.status_code} {r.text[:150]}")
        check("lenta elementi Dart modeliga mos",
              r.status_code == 200 and r.json()
              and not (dart_keys("JobPost") - set(r.json()[0].keys())),
              "maydon yetishmaydi")

        r = await c.post(f"/api/v1/jobs/{jid}/offers", headers=ph_, json={
            "provider_id": pid, "price": 180000, "duration_text": "2 soat",
            "message": "Bugun kelaman",
        })
        check("usta taklif berdi", r.status_code == 201, f"{r.status_code} {r.text[:200]}")
        off = r.json() if r.status_code == 201 else {}

        r = await c.get(f"/api/v1/jobs/{jid}/offers", headers=h)
        offers = r.json() if r.status_code == 200 else []
        check("mijoz takliflarni ko'radi", len(offers) == 1, f"{r.status_code} {offers}")
        if offers:
            miss = dart_keys("JobOffer") - set(offers[0].keys())
            check("JobOffer: Dart kutgan barcha maydon javobda bor",
                  not miss, f"yetishmaydi: {sorted(miss)}")
            # Chat uchun ENG MUHIM maydon: ustaning user_id si.
            # Bu null bo'lsa "Yozish" tugmasi jim ishlamay qoladi.
            check("provider_owner_user_id to'ldirilgan (chat uchun shart)",
                  offers[0].get("provider_owner_user_id") is not None,
                  f"{offers[0].get('provider_owner_user_id')}")
            check("offers_count Dart kutganidek yangilanadi",
                  (await c.get("/api/v1/jobs/my", headers=h)).json()[0]["offers_count"] == 1,
                  "offers_count noto'g'ri")

        r = await c.get("/api/v1/jobs/offers/my", headers=ph_)
        mine = r.json() if r.status_code == 200 else []
        check("usta o'z takliflarini ko'radi", len(mine) == 1, f"{r.status_code}")
        # jobs_feed_screen.dart aynan shu kalitni o'qiydi
        check("offers/my javobida 'job_id' kaliti bor (lenta shuni o'qiydi)",
              mine and "job_id" in mine[0], f"{list(mine[0].keys()) if mine else []}")

        oid = off.get("id")
        r = await c.post(f"/api/v1/jobs/{jid}/offers/{oid}/accept", headers=h)
        check("taklif qabul qilindi", r.status_code == 200, f"{r.status_code} {r.text[:150]}")
        if r.status_code == 200:
            check("qabul qilingach assigned_provider_id to'ldiriladi",
                  r.json().get("assigned_provider_id") == pid,
                  f"{r.json().get('assigned_provider_id')}")

        # ── Dart'da bor, lekin sinalmagan 4 metod ──────────────────────
        # api_service.dart: completeJob, cancelJob, withdrawJobOffer,
        # uploadJobPhoto. Ular ham JobPost/JobOffer qaytaradi, ya'ni
        # javob shakli buzilsa ekranda jimgina null chiqadi.

        r = await c.post(f"/api/v1/jobs/{jid}/complete", headers=h)
        check("completeJob ishlaydi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        if r.status_code == 200:
            miss = dart_keys("JobPost") - set(r.json().keys())
            check("completeJob javobi Dart modeliga mos",
                  not miss, f"yetishmaydi: {sorted(miss)}")
            check("yakunlangach status 'completed'",
                  r.json().get("status") == "completed",
                  f"{r.json().get('status')}")

        # withdrawJobOffer uchun yangi e'lon + taklif
        r = await c.post("/api/v1/jobs", headers=h, json={
            "category_id": cid, "title": "Lampa almashtirish",
            "description": "Yotoqxonada lampa yonmayapti",
            "address": "Toshkent, Yunusobod 12",
        })
        jid2 = r.json().get("id") if r.status_code == 201 else None
        check("ikkinchi e'lon yaratildi", jid2 is not None, f"{r.status_code}")

        if jid2:
            r = await c.post(f"/api/v1/jobs/{jid2}/offers", headers=ph_, json={
                "provider_id": pid, "price": 50000,
            })
            oid2 = r.json().get("id") if r.status_code == 201 else None
            check("ikkinchi taklif berildi", oid2 is not None, f"{r.status_code}")

            # Taklif berilgach sanoq 1 bo'lishi kerak
            r = await c.get("/api/v1/jobs/my", headers=h)
            j2 = [x for x in r.json() if x["id"] == jid2]
            check("taklif berilgach offers_count=1",
                  j2 and j2[0]["offers_count"] == 1,
                  f"{j2[0]['offers_count'] if j2 else '?'}")

            if oid2:
                r = await c.delete(f"/api/v1/jobs/offers/{oid2}", headers=ph_)
                check("withdrawJobOffer ishlaydi", r.status_code == 200,
                      f"{r.status_code} {r.text[:150]}")
                if r.status_code == 200:
                    miss = dart_keys("JobOffer") - set(r.json().keys())
                    check("withdrawJobOffer javobi Dart modeliga mos",
                          not miss, f"yetishmaydi: {sorted(miss)}")

                # Qaytarib olingach mijoz uni KO'RMASLIGI kerak
                r = await c.get(f"/api/v1/jobs/{jid2}/offers", headers=h)
                check("qaytarib olingan taklif ro'yxatdan chiqadi",
                      r.status_code == 200 and len(r.json()) == 0,
                      f"{r.status_code} {len(r.json()) if r.status_code==200 else '?'}")

                # Sanoq ham kamayishi kerak, aks holda mijoz "1 taklif"
                # ko'rib ochganda bo'sh ro'yxat topadi
                r = await c.get("/api/v1/jobs/my", headers=h)
                j2 = [x for x in r.json() if x["id"] == jid2]
                check("qaytarib olingach offers_count=0",
                      j2 and j2[0]["offers_count"] == 0,
                      f"{j2[0]['offers_count'] if j2 else '?'}")

            r = await c.delete(f"/api/v1/jobs/{jid2}", headers=h)
            check("cancelJob ishlaydi", r.status_code == 200,
                  f"{r.status_code} {r.text[:150]}")
            if r.status_code == 200:
                miss = dart_keys("JobPost") - set(r.json().keys())
                check("cancelJob javobi Dart modeliga mos",
                      not miss, f"yetishmaydi: {sorted(miss)}")

            r = await c.get(f"/api/v1/jobs/feed?category_id={cid}", headers=ph_)
            check("bekor qilingan e'lon lentadan yo'qoladi",
                  r.status_code == 200
                  and all(x["id"] != jid2 for x in r.json()),
                  "hali ko'rinyapti")

        # uploadJobPhoto — Dart response.data['url'] ni o'qiydi
        import io
        from PIL import Image
        buf = io.BytesIO()
        Image.new("RGB", (64, 48), (200, 120, 60)).save(buf, "PNG")
        buf.seek(0)
        r = await c.post("/api/v1/jobs/photo", headers=h,
                         files={"file": ("test.png", buf, "image/png")})
        check("uploadJobPhoto ishlaydi", r.status_code == 200,
              f"{r.status_code} {r.text[:150]}")
        if r.status_code == 200:
            check("uploadJobPhoto 'url' kalitini qaytaradi (Dart shuni o'qiydi)",
                  isinstance(r.json().get("url"), str) and r.json()["url"],
                  f"{r.json()}")

    print()
    for x in ok: print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail: print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta shartnoma tekshiruvi o'tdi")

asyncio.run(main())
