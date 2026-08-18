"""Foydalanuvchi ko'rgan AYNAN oqim: rasm -> suhbat -> "ha" -> e'lon.

Nega bu test bor: foydalanuvchi chatda "ha" deganda 500 oldi. Sabab
ikki bosqichli edi (buzuq JSON -> rollback -> MissingGreenlet) va
ikkalasi ALOHIDA tuzatildi. Lekin komponentlarni alohida sinash
yetarli emas: xato aynan ular BIRIKKANDA yuzaga kelgan edi.

Shuning uchun bu yerda haqiqiy `/api/v1/ai/chat` endpointi HTTP
orqali chaqiriladi. LLM javobi soxtalashtiriladi (tashqi xizmatga
bog'lanib qolmaslik uchun), qolgan hamma narsa haqiqiy: FastAPI,
middleware, autentifikatsiya, sessiya, tool dispatcher, baza.

Eng muhim holat: model BUZUQ JSON qaytarganda ham foydalanuvchi 500
emas, tushunarli javob olishi kerak.
"""
import asyncio
import json
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
if not DB:
    print("SKIP: SUPERAPP_TEST_DB berilmagan (haqiqiy PostgreSQL kerak)")
    sys.exit(0)

os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"
# LLM chaqiruvi soxtalashtiriladi, lekin endpoint kalit YO'Q bo'lsa
# umuman urinmay zaxira javobga o'tadi. Shuning uchun soxta kalit.
os.environ.setdefault("GROQ_API_KEY", "test-kalit")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def _llm_javobi(tool_calls=None, matn=""):
    """Groq/OpenAI javobining haqiqiy shakli."""
    msg = {"role": "assistant", "content": matn}
    if tool_calls:
        msg["tool_calls"] = tool_calls
    return {"choices": [{"message": msg}]}


class _SoxtaJavob:
    """httpx.Response o'rniga — faqat kerakli qismi."""

    def __init__(self, data, status=200):
        self._data = data
        self.status_code = status

    def json(self):
        return self._data


async def main():
    import httpx
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy import select, text

    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.main import create_app
    from app.models.category import Category
    from app.models.job import JobPost
    from app.models.user import User

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as db:
        db.add_all([
            Category(key="kompyuterUsta", title_uz="Kompyuter ustasi",
                     icon="cpu"),
            User(name="Mijoz", surname="T", phone="+998900000601",
                 hashed_password=hash_password("parol123")),
        ])
        await db.commit()

    app = create_app()

    # ── LLM ni soxtalashtiramiz ──────────────────────────────────────
    # Har chaqiruvda navbatdagi javob beriladi.
    navbat: list = []
    yuborilgan: list = []

    class _SoxtaClient:
        def __init__(self, *a, **kw):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *a):
            return False

        async def post(self, url, **kw):
            yuborilgan.append(kw.get("json"))
            if not navbat:
                return _SoxtaJavob(_llm_javobi(matn="Tayyor."))
            return navbat.pop(0)

    asl_client = httpx.AsyncClient
    httpx.AsyncClient = _SoxtaClient  # type: ignore

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport,
                               base_url="http://test") as c:
            # httpx.AsyncClient ni almashtirgach ham test mijozi
            # ishlashi kerak — u allaqachon yaratilgan.
            r = await c.post("/api/v1/auth/login",
                             json={"phone": "+998900000601",
                                   "password": "parol123"})
            check("login ishladi", r.status_code == 200, r.text[:150])
            h = {"Authorization": f"Bearer {r.json()['access_token']}"}

            # ── 1) BUZUQ JSON: aynan foydalanuvchi ko'rgan holat ─────
            buzuq = ('{"category":"kompyuterUsta",'
                     '"title":"Kompyuterga "sistema" qilish",'
                     '"description":"Sistema o\'rnatish kerak",'
                     '"address":"Olmazor, Beruniy metro"}')
            navbat.append(_SoxtaJavob(_llm_javobi(tool_calls=[{
                "id": "c1", "type": "function",
                "function": {"name": "start_job_draft", "arguments": buzuq},
            }])))
            navbat.append(_SoxtaJavob(_llm_javobi(
                matn="E'lon tayyor, tasdiqlaysizmi?")))

            r = await c.post("/api/v1/ai/chat", headers=h, json={
                "messages": [{"role": "user",
                              "content": "Kompyuterga sistema qilish kerak"}],
            })
            check("BUZUQ JSON da ham 500 EMAS (asosiy shikoyat)",
                  r.status_code == 200, f"status {r.status_code}: {r.text[:200]}")
            check("foydalanuvchi javob oladi",
                  bool((r.json() or {}).get("reply")), r.text[:150])

            # Tool natijasi modelga qaytganini tekshiramiz
            oxirgi = yuborilgan[-1] if yuborilgan else {}
            tool_xabarlari = [m for m in (oxirgi.get("messages") or [])
                              if m.get("role") == "tool"]
            check("buzuq argument tiklanib, tool BAJARILDI",
                  len(tool_xabarlari) > 0, "tool natijasi modelga bormadi")
            if tool_xabarlari:
                natija = json.loads(tool_xabarlari[0]["content"])
                check("tool JSON xatosi bermadi",
                      "delimiter" not in str(natija), str(natija)[:150])
                check("qoralama tiklangan ma'lumot bilan ishladi",
                      natija.get("status") in ("ready", "needs_more_info"),
                      str(natija)[:150])

            # ── 2) "ha" -> e'lon HAQIQATAN yaratiladi ────────────────
            navbat.append(_SoxtaJavob(_llm_javobi(tool_calls=[{
                "id": "c2", "type": "function",
                "function": {"name": "publish_job",
                             "arguments": '{"confirm": true, "lang": "uz"}'},
            }])))
            navbat.append(_SoxtaJavob(_llm_javobi(matn="E'lon berildi!")))

            r = await c.post("/api/v1/ai/chat", headers=h, json={
                "messages": [
                    {"role": "user",
                     "content": "Kompyuterga sistema qilish kerak"},
                    {"role": "assistant", "content": "Tasdiqlaysizmi?"},
                    {"role": "user", "content": "ha"},
                ],
                "lat": 41.3266, "lng": 69.2264,
            })
            check("'ha' deganda 500 EMAS (foydalanuvchi skrinshoti)",
                  r.status_code == 200, f"status {r.status_code}: {r.text[:200]}")

            body = r.json()
            actions = body.get("actions") or []
            check("ilovaga 'e'lonlar o'zgardi' signali bordi",
                  any(a.get("type") == "jobs_changed" for a in actions),
                  str(actions)[:150])

        # ── 3) E'lon HAQIQATAN bazada bormi ──────────────────────────
        async with async_session() as db:
            jobs = (await db.execute(select(JobPost))).scalars().all()
            check("e'lon BAZADA yaratildi", len(jobs) == 1,
                  f"{len(jobs)} ta e'lon")
            if jobs:
                j = jobs[0]
                check("e'lon sarlavhasi tiklangan matndan olindi",
                      "sistema" in (j.title or "").lower(), str(j.title))
                check("manzil saqlandi",
                      "olmazor" in (j.address or "").lower(), str(j.address))
                check("muddat avtomatik qo'yildi (5 kun)",
                      j.expires_at is not None, "expires_at bo'sh")
                check("koordinata saqlandi (hudud filtri uchun)",
                      j.lat is not None and j.lng is not None,
                      f"{j.lat},{j.lng}")

        # ── 4) LLM butunlay yiqilsa ham 500 bo'lmasin ────────────────
        async with AsyncClient(transport=ASGITransport(app=app),
                               base_url="http://test") as c:
            r = await c.post("/api/v1/auth/login",
                             json={"phone": "+998900000601",
                                   "password": "parol123"})
            h = {"Authorization": f"Bearer {r.json()['access_token']}"}

            navbat.append(_SoxtaJavob({"xato": "buzuq javob"}, status=500))
            r = await c.post("/api/v1/ai/chat", headers=h, json={
                "messages": [{"role": "user", "content": "salom"}]})
            check("LLM yiqilsa ham 500 EMAS (zaxira javob)",
                  r.status_code == 200,
                  f"status {r.status_code}: {r.text[:200]}")
            check("zaxira javob bo'sh emas",
                  bool((r.json() or {}).get("reply")), r.text[:150])

    finally:
        httpx.AsyncClient = asl_client  # type: ignore
        await engine.dispose()

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
