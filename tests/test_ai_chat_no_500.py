"""AI chat 500 bermasligi — haqiqiy chiqarishda uchragan xatolar.

Foydalanuvchi e'lonni tasdiqladi va "javob olishda xatolik" oldi,
holbuki e'lon YARATILGAN edi. Uch sabab topildi va shu yerda
qo'riqlanadi:

  1. Tool ichida `db.commit()`/`rollback()` bo'lgach `current_user`
     obyekti EXPIRED bo'lardi; endpoint keyin `current_user.id` ni
     o'qib "greenlet_spawn has not been called" bilan 500 qaytarardi.
  2. LLM buzuq argument yuborsa `_parse_args` ValueError ko'tarardi,
     dispatcher esa rollback qilib yuqoridagi zanjirni boshlab
     berardi.
  3. Yangi jadval qo'shilgach asyncpg prepared statement keshi
     eskirib `InvalidCachedStatementError` bilan tasodifiy 500
     berardi.
"""
import asyncio
import json
import os
import re
import sys
import tempfile

DB = os.environ.get("SUPERAPP_TEST_DB")

# ⚠️ ISHCHI BAZAGA TEGMASLIK QO'RIQCHISI.
# Bu test `DROP SCHEMA public CASCADE` qiladi. Xato baza
# ko'rsatilsa butun ishchi ma'lumot o'chib ketardi (bu bir
# marta haqiqatan sodir bo'lgan).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_guard import guard as _db_guard  # noqa: E402
_db_guard(DB)

if not DB:
    _tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    _tmp.close()
    DB = f"sqlite+aiosqlite:///{_tmp.name}"

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJ, "backend"))

os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "").replace(
    "+aiosqlite", ""
)
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from sqlalchemy import text
    from sqlalchemy.dialects.postgresql import JSONB

    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.models.marketplace import Listing
    from app.models.user import User
    from app.services.ai_agent.dispatcher import _parse_args, handle_tool_call
    from app.services.ai_agent.market_tools import clear_draft
    from app.services.marketplace import currency

    currency.set_rates({"USD": 12000.0})

    # ── 1. Buzuq argument XATO KO'TARMAYDI ───────────────────────────
    # Ilgari ValueError -> dispatcher rollback -> current_user expired
    # -> butun chat 500. Endi bo'sh lug'at qaytadi va handler o'zi
    # nima yetishmayotganini aytadi.
    for buzuq in ('', 'salom', '{"a": ', '<<<>>>', 'null', '[1,2,3]'):
        try:
            natija = _parse_args(buzuq)
            check(f"buzuq argument xato bermaydi ({buzuq!r})",
                  isinstance(natija, dict), f"{type(natija)}")
        except Exception as exc:
            check(f"buzuq argument xato bermaydi ({buzuq!r})", False,
                  f"{type(exc).__name__}: {exc}")

    check("to'g'ri JSON hamon o'qiladi",
          _parse_args('{"title": "iPhone"}') == {"title": "iPhone"})
    check("qisman buzuq JSON tiklanadi",
          _parse_args('{"title": "iPhone", "price": 100').get("title") == "iPhone")

    async with engine.begin() as conn:
        if engine.dialect.name == "postgresql":
            await conn.execute(text("DROP SCHEMA public CASCADE"))
            await conn.execute(text("CREATE SCHEMA public"))
            await conn.run_sync(Base.metadata.create_all)
        else:
            mumkin = [
                t for t in Base.metadata.sorted_tables
                if not any(isinstance(c.type, JSONB) for c in t.columns)
            ]
            await conn.run_sync(Base.metadata.drop_all, tables=mumkin)
            await conn.run_sync(Base.metadata.create_all, tables=mumkin)

    async with async_session() as db:
        u = User(name="Sotuvchi", surname="Test", phone="+998900007777",
                 hashed_password=hash_password("parol123"))
        db.add(u)
        await db.commit()
        uid = u.id

    # ── 2. Buzuq argumentli TOOL CHAQIRUVI ham 500 bermaydi ──────────
    async with async_session() as db:
        raw, _ = await handle_tool_call(db, uid, {
            "id": "1",
            "function": {"name": "update_listing_draft",
                         "arguments": "bu umuman JSON emas"},
        })
        res = json.loads(raw)
        check("buzuq argumentli tool xato holatiga tushmaydi",
              res.get("status") != "error", f"{res}")
        check("tool foydalanuvchidan ma'lumot so'raydi",
              res.get("status") == "collecting", f"{res}")

    # ── 3. E'lon yaratilgach FOYDALANUVCHI obyekti ishlatilaveradi ───
    # Aynan shu joy chiqarishda 500 bergan: publish_listing ichida
    # commit bo'lgach endpoint `current_user.id` ni o'qiydi.
    RASMLAR = ["/uploads/listings/a.jpg", "/uploads/listings/b.jpg",
               "/uploads/listings/c.jpg"]
    async with async_session() as db:
        user = await db.get(User, uid)
        clear_draft(uid)
        await handle_tool_call(db, uid, {
            "id": "1",
            "function": {"name": "start_listing_draft", "arguments": json.dumps({
                "category": "telefon", "title": "iPhone 13 Pro 256GB",
                "price": 4500000, "condition": "ideal",
                "address": "Toshkent, Chilonzor",
                "attributes": {"model": "iPhone 13 Pro", "xotira": "256GB"},
                "photos": RASMLAR,
            })},
        })
        raw, action = await handle_tool_call(db, uid, {
            "id": "2",
            "function": {"name": "publish_listing",
                         "arguments": '{"confirm": true}'},
        })
        res = json.loads(raw)
        check("e'lon yaratildi", res.get("status") == "success", f"{res}")

        # ⚠️ ASOSIY TEKSHIRUV: commit'dan keyin obyektni o'qish
        # yashirin DB so'roviga aylanmasligi kerak.
        try:
            _ = user.id
            _ = user.name
            check("commit'dan keyin foydalanuvchi obyekti ishlatiladi", True)
        except Exception as exc:
            check("commit'dan keyin foydalanuvchi obyekti ishlatiladi",
                  False, f"{type(exc).__name__}: {exc}")

    # ── 4. Endpoint ID ni OLDINDAN o'qiydi (manba kodi) ──────────────
    src = open(os.path.join(PROJ, "backend/app/api/v1/ai_chat.py")).read()
    gavda = src[src.index("async def ai_chat("):src.index("@router.post(\"/job-photo\")")]
    check("ai_chat tool chaqiruvida current_user.id ishlatmaydi",
          "current_user.id, tool_call" not in gavda, "expired obyekt xavfi")
    check("ai_chat user_id ni oldindan o'qib qo'yadi",
          "user_id = current_user.id" in gavda, "topilmadi")

    # ── 5. asyncpg kesh o'chirilgan ──────────────────────────────────
    sess = open(os.path.join(PROJ, "backend/app/db/session.py")).read()
    check("asyncpg prepared statement keshi o'chirilgan",
          "statement_cache_size" in sess,
          "yangi jadval qo'shilganda 500 qaytishi mumkin")

    if engine.dialect.name == "postgresql":
        # Sxema o'zgargach eski reja ishlatilmasligini HAQIQATAN sinaymiz.
        async with async_session() as db:
            await db.execute(text("SELECT 1"))
            await db.execute(text("CREATE TABLE kesh_sinov (id int)"))
            await db.commit()
            try:
                await db.execute(text("SELECT 1"))
                await db.execute(text("DROP TABLE kesh_sinov"))
                await db.commit()
                check("sxema o'zgargach ham so'rov ishlaydi", True)
            except Exception as exc:
                check("sxema o'zgargach ham so'rov ishlaydi", False,
                      f"{type(exc).__name__}")

    # ── 6. Rasm endpointi ikki xil e'lonni ajratadi ──────────────────
    check("rasm endpointida kind parametri bor",
          "kind: str = Form(" in src, "savdo rasmi ish e'loniga tushadi")
    check("savdo rasmi alohida papkaga saqlanadi",
          "upload_listing_photo" in src, "topilmadi")
    check("savdo rasmi vision bilan tahlil qilinmaydi",
          "if not savdo:" in src, "vision savdoni chalg'itadi")

    vision = open(
        os.path.join(PROJ, "backend/app/services/ai_job/vision.py")
    ).read()
    kutish = re.search(r"AsyncClient\(timeout=([\d.]+)\)", vision)
    check("vision kutish vaqti 30s dan kam (chat qotib qolmasin)",
          kutish is not None and float(kutish.group(1)) <= 30,
          f"{kutish.group(1) if kutish else 'topilmadi'}")

    # ── 6b. Qoralama KO'P WORKER orasida yo'qolmaydi ─────────────────
    # Prodda bir necha worker ishlaydi: foydalanuvchi ma'lumotni bir
    # workerga yozib, "ha" ni boshqasiga yuborishi mumkin. Ilgari
    # qoralama faqat jarayon xotirasida edi va BO'SH bo'lib chiqardi.
    mt = open(
        os.path.join(PROJ, "backend/app/services/ai_agent/market_tools.py")
    ).read()
    check("savdo qoralamasi Redis'da ham saqlanadi",
          "_save_draft" in mt and "ai_draft:market" in mt, "topilmadi")
    jt = open(
        os.path.join(PROJ, "backend/app/services/ai_agent/job_tools.py")
    ).read()
    check("ish qoralamasi ham Redis'da",
          "ai_draft:job" in jt, "topilmadi")

    # Xotira keshi tozalangach Redis'dan tiklanishini SINAB ko'ramiz.
    from app.services.ai_agent import market_tools

    async with async_session() as db:
        clear_draft(uid)
        await handle_tool_call(db, uid, {
            "id": "1",
            "function": {"name": "start_listing_draft", "arguments": json.dumps({
                "category": "mebel", "title": "Yumshoq divan",
                "condition": "yaxshi", "address": "Toshkent",
            })},
        })
        # "Boshqa worker" ni taqlid qilamiz: xotira keshini tozalaymiz.
        market_tools._DRAFTS.clear()
        raw, _ = await handle_tool_call(db, uid, {
            "id": "2",
            "function": {"name": "update_listing_draft",
                         "arguments": '{"price": 2000000}'},
        })
        res2 = json.loads(raw)
        # Qoralama tiklanganini TOIFA bo'yicha tekshiramiz: `summary`
        # faqat hamma maydon to'lgandagina bo'ladi, bu yerda esa
        # `tur` ataylab berilmagan. Muhimi — oldin yozilgan ma'lumot
        # yo'qolmagani.
        tiklandi = (res2.get("category") == "mebel"
                    and "title" not in (res2.get("missing") or [])
                    and "condition" not in (res2.get("missing") or []))
        # Redis bo'lmasa bu tekshiruv o'tkazib yuboriladi (lokal muhit).
        try:
            from app.core.redis_client import get_redis
            get_redis().ping()
            redis_bor = True
        except Exception:
            redis_bor = False
        if redis_bor:
            check("boshqa workerda qoralama tiklanadi", tiklandi, f"{res2}")
        else:
            check("Redis yo'q — qoralama xotirada ishlaydi (o'tkazildi)", True)

    # ── 6c. Bo'sh javob "xatolik" bo'lib ko'rinmaydi ─────────────────
    check("tool bajarilгач bo'sh javob o'rniga xabar yoziladi",
          "E'lon joylandi" in src and "turlar = {" in src,
          "bo'sh javob foydalanuvchiga xatolik bo'lib ko'rinadi")

    # ── 7. Tavsif bo'sh qolmaydi ─────────────────────────────────────
    async with async_session() as db:
        item = (await db.get(Listing, res.get("listing_id")))
        check("e'lon tavsifi bo'sh emas",
              item is not None and len(item.description or "") > 10,
              f"{item.description if item else ''}")
        check("tavsifda buyum nomi bor",
              item and "iPhone" in item.description, f"{item.description}")

    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi ({engine.dialect.name})")


asyncio.run(main())
