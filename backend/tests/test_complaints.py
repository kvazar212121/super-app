"""Shikoyat oqimi va uning QAT'IY CHEGARALARI.

Eng muhim tekshiruv: AI shikoyat orqali jazo tizimiga TEGA OLMAYDI.
Bu ARXITEKTURA.md §20.4 dagi qaror — himoya promptda emas, KODDA
bo'lishi kerak.
"""
import asyncio
import json
import os
import sys
from datetime import datetime as DT

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/db")
os.environ.setdefault("DATABASE_SYNC_URL", "postgresql+psycopg2://u:p@localhost/db")

from sqlalchemy.dialects.postgresql import JSONB  # noqa: E402
from sqlalchemy.ext.compiler import compiles  # noqa: E402


@compiles(JSONB, "sqlite")
def _c(e, c, **k):  # noqa: D103
    return "JSON"


from sqlalchemy import select  # noqa: E402
from sqlalchemy.ext.asyncio import (  # noqa: E402
    AsyncSession, async_sessionmaker, create_async_engine,
)

import app.models  # noqa: E402,F401
from app.db.base import Base  # noqa: E402
from app.models.category import Category  # noqa: E402
from app.models.complaint import Complaint  # noqa: E402
from app.models.order import Order  # noqa: E402
from app.models.provider import Provider  # noqa: E402
from app.models.user import User  # noqa: E402
from app.services import complaint_service  # noqa: E402
from app.services.ai_agent import handle_tool_call  # noqa: E402

xato = 0


def check(nom, shart, sabab=""):
    global xato
    if shart:
        print(f"  ✓ {nom}")
    else:
        xato += 1
        print(f"  ✗ {nom}" + (f" — {sabab}" if sabab else ""))


def tc(name, args):
    return {"id": "x", "function": {"name": name, "arguments": json.dumps(args)}}


async def main() -> int:
    NOW = DT(2026, 1, 1, 12, 0)
    eng = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with eng.begin() as c:
        await c.run_sync(Base.metadata.create_all)
    S = async_sessionmaker(eng, class_=AsyncSession, expire_on_commit=False)

    async with S() as db:
        mijoz = User(name="M", surname="M", phone="+1", hashed_password="x", created_at=NOW)
        begona = User(name="B", surname="B", phone="+2", hashed_password="x", created_at=NOW)
        usta_ega = User(name="U", surname="U", phone="+3", hashed_password="x", created_at=NOW)
        db.add_all([mijoz, begona, usta_ega])
        await db.flush()

        cat = Category(key="e", title_uz="E", icon="e")
        db.add(cat)
        await db.flush()

        prov = Provider(category_id=cat.id, name="Usta", address="A", phone="+9",
                        owner_user_id=usta_ega.id)
        db.add(prov)
        await db.flush()

        # Mijozning shu ustada BUYURTMASI bor, begonada yo'q.
        db.add(Order(user_id=mijoz.id, category_id=cat.id, provider_id=prov.id,
                     service_name="s", address="a", date=NOW, price=1000.0,
                     created_at=NOW))
        await db.commit()

        print("\n=== Shikoyat yoziladi va aloqa aniqlanadi ===")
        c1 = await complaint_service.create(
            db, reporter_user_id=mijoz.id, text="Kelmadi va pulni qaytarmadi",
            kind="no_show", provider_id=prov.id)
        await db.commit()
        check("shikoyat saqlandi", c1.id is not None)
        check("buyurtmasi bor mijozda has_interaction=True", c1.has_interaction is True)
        check("holat 'new'", c1.status == "new")

        c2 = await complaint_service.create(
            db, reporter_user_id=begona.id, text="Yomon usta", provider_id=prov.id)
        await db.commit()
        check("aloqasi yo'q odamda has_interaction=False",
              c2.has_interaction is False,
              "admin uchun eng muhim signal yo'qoldi")
        check("lekin shikoyat baribir YOZILADI", c2.id is not None,
              "aloqasiz shikoyatni bloklash haqiqiy holatlarni ham to'sadi")

        print("\n=== Noto'g'ri tur 'other' ga tushadi ===")
        c3 = await complaint_service.create(
            db, reporter_user_id=mijoz.id, text="x", kind="qandaydir_narsa",
            provider_id=prov.id)
        await db.commit()
        check("noma'lum kind -> other", c3.kind == "other")

        print("\n=== AI tool: tasdiqsiz YOZMAYDI ===")
        natija, _ = await handle_tool_call(
            db, mijoz.id, tc("report_complaint", {"text": "aldadi"}))
        d = json.loads(natija)
        check("confirm'siz needs_confirmation", d.get("status") == "needs_confirmation",
              str(d)[:120])
        oldin = (await db.execute(select(Complaint))).scalars().all()
        check("tasdiqsiz bazaga yozilmadi", len(oldin) == 3, f"{len(oldin)} ta yozuv")

        print("\n=== AI tool: tasdiq bilan yozadi ===")
        natija, action = await handle_tool_call(
            db, mijoz.id, tc("report_complaint", {
                "text": "Pulni oldi, ishlamadi", "kind": "fraud",
                "provider_id": prov.id, "confirm": True}))
        d = json.loads(natija)
        check("confirm bilan success", d.get("status") == "success", str(d)[:120])
        check("action qaytardi", (action or {}).get("type") == "complaint_created")
        yangi = await db.get(Complaint, d.get("complaint_id"))
        check("shikoyat mijoz nomiga yozildi", yangi.reporter_user_id == mijoz.id)
        check("kind saqlandi", yangi.kind == "fraud")

        print("\n=== CHEGARA: AI jazo tizimiga tega olmaydi ===")
        from app.services.ai_agent.dispatcher import HANDLERS
        # ODAMGA qarshi chora ko'radigan tool bo'lmasligi kerak.
        # `provider_block_time` bunga kirmaydi — u kalendarda VAQT
        # oralig'ini band qiladi, hech kimni bloklamaydi.
        taqiqli = [n for n in HANDLERS
                   if any(k in n for k in ("block_user", "ban_", "_ban",
                                           "punish", "suspend", "penalty",
                                           "resolve_complaint",
                                           "delete_complaint",
                                           "update_complaint"))]
        check("odamga chora ko'radigan tool YO'Q", not taqiqli, f"topildi: {taqiqli}")

        # AI status yubormoqchi bo'lsa ham — e'tiborsiz qoladi.
        natija, _ = await handle_tool_call(
            db, mijoz.id, tc("report_complaint", {
                "text": "test", "provider_id": prov.id, "confirm": True,
                "status": "upheld", "has_interaction": True}))
        d = json.loads(natija)
        yangi2 = await db.get(Complaint, d.get("complaint_id"))
        check("AI yuborgan status E'TIBORSIZ qoladi", yangi2.status == "new",
              f"status={yangi2.status} — AI qaror qabul qildi!")
        check("AI yuborgan has_interaction E'TIBORSIZ, o'zi hisoblanadi",
              yangi2.has_interaction is True)

        print("\n=== Kunlik chegara ===")
        for i in range(complaint_service.DAILY_LIMIT):
            await complaint_service.create(
                db, reporter_user_id=begona.id, text=f"spam {i}", provider_id=prov.id)
        await db.commit()
        natija, _ = await handle_tool_call(
            db, begona.id, tc("report_complaint", {
                "text": "yana", "provider_id": prov.id, "confirm": True}))
        d = json.loads(natija)
        check("chegaradan oshsa rad etiladi", d.get("status") == "error", str(d)[:120])

        print("\n=== Admin qarori ===")
        r = await complaint_service.resolve(
            db, c1.id, status="rejected", admin_user_id=99, note="asossiz")
        await db.commit()
        check("holat o'zgardi", r.status == "rejected")
        check("matn O'ZGARMADI", r.text == "Kelmadi va pulni qaytarmadi")
        check("kim hal qilgani yozildi", r.resolved_by == 99)
        try:
            await complaint_service.resolve(db, c1.id, status="new", admin_user_id=99)
            check("'new' ga qaytarib bo'lmaydi", False, "qabul qilindi")
        except ValueError:
            check("'new' ga qaytarib bo'lmaydi", True)

    await eng.dispose()
    print()
    if xato:
        print(f"YIQILDI: {xato} ta tekshiruv o'tmadi")
        return 1
    print("BARCHA TEKSHIRUVLAR O'TDI ✅")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
