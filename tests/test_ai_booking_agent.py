"""AI agentning BRON BOSHQARUVI tool'lari.

Foydalanuvchi talabi: "agent to'liq bron tizimlariga va ichki ishlarga
aralasha olishi, o'zgartirish, bronlar qila olishi kerak".

Bu testlar agent haqiqatan boshqara olishini VA xavfsiz ekanini
tekshiradi:
  * boshqa odamning bronini o'zgartira olmasligi (eng muhim),
  * tasdiqsiz hech narsa o'zgarmasligi,
  * band vaqtga ko'chirmasligi,
  * yakunlangan bronga tegmasligi,
  * ustaning telefon raqami chiqib ketmasligi.

Haqiqiy PostgreSQL kerak. Bo'lmasa SKIP.
"""
import asyncio
import json
import os
import sys
from datetime import datetime, timedelta

BACKEND = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend"
)
sys.path.insert(0, BACKEND)

# ⚠️ ISHCHI BAZAGA TEGMASLIK QO'RIQCHISI.
# Bu test `DROP SCHEMA public CASCADE` qiladi. Xato baza
# ko'rsatilsa butun ishchi ma'lumot o'chib ketardi (bu bir
# marta haqiqatan sodir bo'lgan).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_guard import guard as _db_guard  # noqa: E402
_db_guard(DB)

DB = os.environ.get("SUPERAPP_TEST_DB")
if not DB:
    print("SKIP: SUPERAPP_TEST_DB berilmagan (haqiqiy PostgreSQL kerak)")
    sys.exit(0)

os.environ["DATABASE_URL"] = DB
os.environ["DATABASE_SYNC_URL"] = DB.replace("+asyncpg", "")
os.environ["REQUIRE_OTP_AUTH"] = "false"

USTA_RAQAMI = "+998911114455"
ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


async def main():
    from sqlalchemy import text
    from app.core.security import hash_password
    from app.db.base import Base
    from app.db.session import async_session, engine
    from app.models.category import Category
    from app.models.order import Order, OrderStatus
    from app.models.provider import Provider
    from app.models.user import User
    from app.services.ai_agent.dispatcher import HANDLERS
    from app.services.ai_agent.tools_schema import TOOLS

    # ── Sxema butunligi (bazasiz ham muhim) ──────────────────────────
    nomlar = {t["function"]["name"] for t in TOOLS}
    yangi = {"next_booking", "get_booking_details", "check_availability",
             "reschedule_booking", "update_booking", "get_provider_info"}
    check("6 ta yangi bron tool'i sxemada bor", yangi <= nomlar,
          f"yetishmayapti: {yangi - nomlar}")
    check("har sxemaga handler bor", nomlar <= set(HANDLERS),
          f"handlersiz: {nomlar - set(HANDLERS)}")
    check("ortiqcha handler yo'q", set(HANDLERS) <= nomlar,
          f"sxemasiz: {set(HANDLERS) - nomlar}")

    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)

    ertaga = (datetime.now() + timedelta(days=1)).replace(
        hour=10, minute=0, second=0, microsecond=0)

    async with async_session() as db:
        cat = Category(key="barber", title_uz="Sartarosh", icon="scissors")
        egasi = User(name="Mijoz", surname="A", phone="+998900000401",
                     hashed_password=hash_password("x"))
        begona = User(name="Begona", surname="B", phone="+998900000402",
                      hashed_password=hash_password("x"))
        usta_u = User(name="Usta", surname="C", phone="+998900000403",
                      hashed_password=hash_password("x"))
        db.add_all([cat, egasi, begona, usta_u])
        await db.flush()

        prov = Provider(name="Salon Zebo", category_id=cat.id,
                        address="Toshkent, Chilonzor", phone=USTA_RAQAMI,
                        owner_user_id=usta_u.id, lat=41.2756, lng=69.2035,
                        metadata_json={"time_slots": ["10:00", "11:00", "12:00"]})
        db.add(prov)
        await db.flush()

        bron = Order(user_id=egasi.id, category_id=cat.id, provider_id=prov.id,
                     service_name="Soch olish", address="Chilonzor 5",
                     date=ertaga, price=50000, status=OrderStatus.pending)
        # Boshqa mijozning 11:00 dagi broni — o'sha vaqt BAND bo'ladi
        band = Order(user_id=begona.id, category_id=cat.id, provider_id=prov.id,
                     service_name="Soqol", address="Yunusobod",
                     date=ertaga.replace(hour=11), price=30000,
                     status=OrderStatus.pending)
        # Yakunlangan bron — o'zgartirib bo'lmasligi kerak
        eski = Order(user_id=egasi.id, category_id=cat.id, provider_id=prov.id,
                     service_name="Eski xizmat", address="Chilonzor 5",
                     date=datetime.now() - timedelta(days=5), price=40000,
                     status=OrderStatus.completed)
        db.add_all([bron, band, eski])
        await db.commit()
        ids = dict(egasi=egasi.id, begona=begona.id, prov=prov.id,
                   bron=bron.id, band=band.id, eski=eski.id)

    async def call(tool, uid, args):
        out, action = await HANDLERS[tool](
            (await _session()), uid, args, None)
        return json.loads(out), action

    # Har chaqiruv uchun toza sessiya (endpoint kabi)
    _cache = {}

    async def _session():
        if "s" not in _cache:
            _cache["s"] = async_session()
            _cache["db"] = await _cache["s"].__aenter__()
        return _cache["db"]

    # ── 1. next_booking ──────────────────────────────────────────────
    r, _ = await call("next_booking", ids["egasi"], {})
    b = r.get("booking") or {}
    check("next_booking eng yaqin bronni topadi", b.get("order_id") == ids["bron"],
          str(r)[:150])
    check("next_booking ustani ko'rsatadi", b.get("provider_name") == "Salon Zebo",
          str(b)[:120])

    # ── 2. get_booking_details ───────────────────────────────────────
    r, _ = await call("get_booking_details", ids["egasi"],
                      {"order_id": ids["bron"]})
    d = r.get("booking") or {}
    check("tafsilotda manzil va narx bor",
          d.get("address") == "Chilonzor 5" and d.get("price") == 50000,
          str(d)[:150])
    check("tafsilotda ustaning RAQAMI yo'q (maxfiylik)",
          USTA_RAQAMI not in json.dumps(r, ensure_ascii=False),
          "raqam tarqaldi!")
    check("o'zgartirish mumkinligi ko'rsatilgan", d.get("can_modify") is True)

    # ── 3. BEGONA bronni ko'ra olmaydi (xavfsizlik) ──────────────────
    r, _ = await call("get_booking_details", ids["begona"],
                      {"order_id": ids["bron"]})
    check("BEGONA boshqa odamning bronini KO'RA OLMAYDI",
          r.get("status") == "error", str(r)[:120])

    # ── 4. check_availability ────────────────────────────────────────
    r, _ = await call("check_availability", ids["egasi"],
                      {"provider_id": ids["prov"],
                       "date": ertaga.date().isoformat()})
    check("band vaqt 'busy' da ko'rinadi", "11:00" in (r.get("busy_slots") or []),
          str(r)[:180])
    check("bo'sh vaqt taklif qilinadi", "12:00" in (r.get("free_slots") or []),
          str(r)[:180])

    # ── 5. reschedule: TASDIQSIZ o'zgarmaydi ─────────────────────────
    yangi_vaqt = ertaga.replace(hour=12)
    r, _ = await call("reschedule_booking", ids["egasi"],
                      {"order_id": ids["bron"],
                       "new_date": yangi_vaqt.isoformat()})
    check("tasdiqsiz — avval xulosa so'raydi",
          r.get("status") == "needs_confirmation", str(r)[:150])

    async with async_session() as db:
        o = await db.get(Order, ids["bron"])
        check("tasdiqsiz bron HAQIQATAN o'zgarmadi", o.date == ertaga,
              f"{o.date} != {ertaga}")

    # ── 6. reschedule: BAND vaqtga ko'chirmaydi ──────────────────────
    r, _ = await call("reschedule_booking", ids["egasi"],
                      {"order_id": ids["bron"],
                       "new_date": ertaga.replace(hour=11).isoformat(),
                       "confirm": True})
    check("BAND vaqtga ko'chirmaydi", r.get("status") == "slot_busy",
          str(r)[:150])
    check("band bo'lsa bo'sh vaqtlarni taklif qiladi",
          "12:00" in (r.get("free_slots") or []), str(r)[:150])

    # ── 7. reschedule: tasdiq bilan ISHLAYDI ─────────────────────────
    r, action = await call("reschedule_booking", ids["egasi"],
                           {"order_id": ids["bron"],
                            "new_date": yangi_vaqt.isoformat(),
                            "confirm": True})
    check("tasdiq bilan ko'chiriladi", r.get("status") == "success",
          str(r)[:150])
    check("ilovaga yangilanish signali boradi",
          (action or {}).get("type") == "orders_changed", str(action))

    async with async_session() as db:
        o = await db.get(Order, ids["bron"])
        check("bron bazada HAQIQATAN ko'chdi", o.date == yangi_vaqt,
              f"{o.date}")

    # ── 8. BEGONA o'zgartira olmaydi (eng muhim xavfsizlik) ──────────
    r, _ = await call("reschedule_booking", ids["begona"],
                      {"order_id": ids["bron"],
                       "new_date": ertaga.replace(hour=10).isoformat(),
                       "confirm": True})
    check("BEGONA boshqa odamning bronini KO'CHIRA OLMAYDI",
          r.get("status") == "error", str(r)[:150])

    async with async_session() as db:
        o = await db.get(Order, ids["bron"])
        check("begona urinishidan keyin bron o'zgarmagan",
              o.date == yangi_vaqt, str(o.date))

    # ── 9. Yakunlangan bronga tegmaydi ───────────────────────────────
    r, _ = await call("reschedule_booking", ids["egasi"],
                      {"order_id": ids["eski"],
                       "new_date": (datetime.now() + timedelta(days=3)).isoformat(),
                       "confirm": True})
    check("yakunlangan bronni o'zgartirmaydi", r.get("status") == "error",
          str(r)[:150])

    # ── 10. O'tgan vaqtga ko'chirmaydi ───────────────────────────────
    r, _ = await call("reschedule_booking", ids["egasi"],
                      {"order_id": ids["bron"],
                       "new_date": (datetime.now() - timedelta(days=1)).isoformat(),
                       "confirm": True})
    check("O'TGAN vaqtga ko'chirmaydi", r.get("status") == "error",
          str(r)[:150])

    # ── 11. update_booking ───────────────────────────────────────────
    r, _ = await call("update_booking", ids["egasi"],
                      {"order_id": ids["bron"], "address": "Yunusobod 12"})
    check("manzil o'zgarishi ham tasdiq so'raydi",
          r.get("status") == "needs_confirmation", str(r)[:150])

    r, _ = await call("update_booking", ids["egasi"],
                      {"order_id": ids["bron"], "address": "Yunusobod 12",
                       "notes": "Eshik kodi 45", "confirm": True})
    check("tasdiq bilan manzil yangilanadi", r.get("status") == "success",
          str(r)[:150])

    async with async_session() as db:
        o = await db.get(Order, ids["bron"])
        check("manzil bazada yangilandi", o.address == "Yunusobod 12", o.address)
        check("izoh bazada saqlandi", o.notes == "Eshik kodi 45", str(o.notes))

    # ── 12. get_provider_info ────────────────────────────────────────
    r, _ = await call("get_provider_info", ids["egasi"],
                      {"provider_id": ids["prov"]})
    p = r.get("provider") or {}
    check("usta ma'lumoti keladi", p.get("name") == "Salon Zebo", str(p)[:120])
    check("usta ma'lumotida RAQAM yo'q (maxfiylik)",
          USTA_RAQAMI not in json.dumps(r, ensure_ascii=False),
          "raqam tarqaldi!")

    # ── 13. Noto'g'ri kirish qulatmaydi ──────────────────────────────
    for tool, args in [
        ("get_booking_details", {"order_id": "yo'q"}),
        ("get_booking_details", {}),
        ("check_availability", {"provider_id": 999999}),
        ("reschedule_booking", {"order_id": ids["bron"], "new_date": "buzuq"}),
        ("get_provider_info", {"provider_id": 999999}),
    ]:
        try:
            r, _ = await call(tool, ids["egasi"], args)
            check(f"{tool} noto'g'ri kirishda qulamaydi",
                  r.get("status") in ("error", "success"), str(r)[:100])
        except Exception as exc:
            check(f"{tool} noto'g'ri kirishda qulamaydi", False,
                  f"{type(exc).__name__}: {exc}")

    if "s" in _cache:
        await _cache["s"].__aexit__(None, None, None)
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
