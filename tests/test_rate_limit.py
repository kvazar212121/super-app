"""Rate-limit (so'rov chegarasi) ishga tushganda 429 qaytishi.

Nega bu test bor: chegara oshganda ishlovchining O'ZI qulardi —
`RateLimitExceeded` obyektida `retry_after` maydoni yo'q edi va
`AttributeError` chiqardi. Natijada foydalanuvchi 429 o'rniga
500 ("Ichki server xatoligi") olardi.

Bu jimgina o'tib ketadigan xato: chegaraga yetmaguncha bilinmaydi,
yetgach esa butunlay boshqa (va noto'g'ri) javob beradi. Ko'p
so'rov yuboradigan foydalanuvchi "server buzildi" deb o'ylaydi.

Xato serverdagi testlar ketma-ket ishlaganda topildi: bitta test
ko'p login qilib chegarani to'ldirgan, keyingisi 500 olgan.
"""
import asyncio
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

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


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

    async with async_session() as db:
        db.add(User(name="Test", surname="Chegara",
                    phone="+998900000901",
                    hashed_password=hash_password("parol123")))
        await db.commit()

    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app),
                           base_url="http://test") as c:

        async def login():
            return await c.post("/api/v1/auth/login",
                                json={"phone": "+998900000901",
                                      "password": "parol123"})

        r = await login()
        check("oddiy login ishlaydi", r.status_code == 200,
              f"{r.status_code}: {r.text[:150]}")

        # Chegarani ataylab to'ldiramiz.
        kodlar = []
        for _ in range(60):
            kodlar.append((await login()).status_code)
            if kodlar[-1] == 429:
                break

        chegara_ishladi = 429 in kodlar
        check("chegara ishga tushdi", chegara_ishladi,
              f"60 ta so'rovda ham chegara chiqmadi: {set(kodlar)}")

        # ENG MUHIMI: chegara 500 emas, 429 berishi kerak.
        check("chegara 500 BERMAYDI (ishlovchi qulamaydi)",
              500 not in kodlar,
              f"500 chiqdi — xato ishlovchisi qulagan: {set(kodlar)}")

        if chegara_ishladi:
            # 429 javobining mazmuni to'g'rimi.
            r429 = None
            for _ in range(5):
                r = await login()
                if r.status_code == 429:
                    r429 = r
                    break
            if r429 is not None:
                check("Retry-After sarlavhasi bor",
                      "retry-after" in {k.lower() for k in r429.headers},
                      str(dict(r429.headers))[:150])
                qiymat = r429.headers.get("retry-after", "")
                check("Retry-After son (mijoz o'qiy oladi)",
                      qiymat.isdigit(), repr(qiymat))
                check("tushunarli xabar bor",
                      "detail" in (r429.json() or {}),
                      r429.text[:150])

        # Chegara o'tgach tizim ishlashda davom etadimi (boshqa yo'l).
        r = await c.get("/api/v1/health")
        check("chegara boshqa yo'llarni bloklamaydi",
              r.status_code == 200, f"{r.status_code}")

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
