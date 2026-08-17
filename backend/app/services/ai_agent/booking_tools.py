"""Bron (buyurtma) boshqaruvi — agentning haqiqiy "qo'li".

Ilgari AI faqat bron YARATA olardi va bekor qila olardi. Foydalanuvchi
talabi: agent bron tizimining ICHIGA to'liq kira olsin — mavjud
bronlarni ko'rsin, vaqtini/manzilini o'zgartirsin, bo'sh vaqtlarni
aytsin, usta haqida ma'lumot bersin.

Muhim qoidalar (loyihaning mavjud uslubi):
  * O'ZGARTIRUVCHI amal — HAR DOIM `confirm` darvozasi orqali. Avval
    xulosa qaytariladi, foydalanuvchi tasdiqlagach bajariladi. Sabab:
    AI xato tushunsa, mijozning haqiqiy bronini buzib qo'ymasin.
  * Har amal FAQAT so'rovchining o'z bronlariga ta'sir qiladi
    (`Order.user_id == user_id` majburiy).
  * Yakunlangan/bekor qilingan bronga tegilmaydi.
"""
import json
from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# Ustaga xabar bermaydigan (o'zgarmas) holatlar
_YOPIQ_HOLATLAR = ("completed", "cancelled", "no_show")


def _err(msg: str) -> tuple[str, None]:
    return json.dumps({"status": "error", "message": msg},
                      ensure_ascii=False), None


def _parse_dt(raw: str | None) -> datetime | None:
    """ISO sanani o'qiydi. Vaqt mintaqasi olib tashlanadi.

    Order.date bazada `DateTime` (tzsiz), shuning uchun tz bilan
    solishtirilsa TypeError bo'ladi.
    """
    if not raw:
        return None
    try:
        return datetime.fromisoformat(
            str(raw).replace("Z", "+00:00")
        ).replace(tzinfo=None)
    except Exception:
        return None


async def _own_order(db: AsyncSession, user_id: int, order_id_raw):
    """Foydalanuvchining o'z buyurtmasini oladi (yoki None)."""
    from app.models.order import Order
    try:
        oid = int(order_id_raw)
    except (TypeError, ValueError):
        return None
    return (await db.execute(
        select(Order).where(Order.id == oid, Order.user_id == user_id)
    )).scalar_one_or_none()


# ── 1. Bron tafsilotlari ─────────────────────────────────────────────
async def get_booking_details(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Bitta bronning to'liq ma'lumoti: usta, vaqt, manzil, narx, holat."""
    from app.models.provider import Provider

    o = await _own_order(db, user_id, args.get("order_id"))
    if not o:
        return _err("Bunday buyurtma topilmadi.")

    prov = await db.get(Provider, o.provider_id)
    return json.dumps({
        "status": "success",
        "booking": {
            "order_id": o.id,
            "service_name": o.service_name,
            "provider_name": prov.name if prov else None,
            "provider_id": o.provider_id,
            "provider_rating": getattr(prov, "rating", None),
            # Ustaning telefon raqami ATAYLAB berilmaydi — aloqa ilova
            # ichida (chat/qo'ng'iroq) bo'lishi kerak.
            "date": o.date.isoformat() if o.date else None,
            "address": o.address,
            "price": o.price,
            "notes": o.notes,
            "status": o.status.value if o.status else None,
            "can_modify": (o.status.value if o.status else "") not in _YOPIQ_HOLATLAR,
        },
    }, ensure_ascii=False), None


# ── 2. Bo'sh vaqtlar ─────────────────────────────────────────────────
async def check_availability(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Ustaning ma'lum kundagi BO'SH vaqtlari.

    Agent bronni ko'chirishdan oldin shuni chaqirishi kerak, aks holda
    band vaqtga ko'chirmoqchi bo'lib xato oladi.
    """
    from app.services.provider_service import ProviderService

    try:
        provider_id = int(args.get("provider_id"))
    except (TypeError, ValueError):
        return _err("provider_id kiritilmagan.")

    day_raw = (args.get("date") or "").strip()
    if day_raw:
        dt = _parse_dt(day_raw)
        if dt is None:
            try:
                day = date.fromisoformat(day_raw[:10])
            except Exception:
                return _err("Sana formati noto'g'ri (YYYY-MM-DD kutiladi).")
        else:
            day = dt.date()
    else:
        day = date.today()

    try:
        data = await ProviderService.get_availability(db, provider_id, day)
    except Exception as exc:
        return _err(f"Bo'sh vaqtlarni olishda xato: {exc}")

    slots = data.get("slots") or []
    booked = set(data.get("booked") or [])
    free = [s for s in slots if s not in booked]

    return json.dumps({
        "status": "success",
        "date": day.isoformat(),
        "free_slots": free,
        "busy_slots": sorted(booked),
        "message": (
            f"{day.isoformat()} kuni {len(free)} ta bo'sh vaqt bor."
            if free else
            f"{day.isoformat()} kuni bo'sh vaqt qolmagan, boshqa kunni taklif qiling."
        ),
    }, ensure_ascii=False), None


# ── 3. Bronni ko'chirish (vaqtini o'zgartirish) ──────────────────────
async def reschedule_booking(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Bron vaqtini o'zgartiradi. Tasdiqsiz bajarilmaydi."""
    from app.models.order import Order, OrderStatus
    from app.models.provider import Provider
    from app.services.provider_service import ProviderService

    o = await _own_order(db, user_id, args.get("order_id"))
    if not o:
        return _err("Bunday buyurtma topilmadi.")

    holat = o.status.value if o.status else ""
    if holat in _YOPIQ_HOLATLAR:
        return _err("Bu buyurtma yakunlangan yoki bekor qilingan — "
                    "vaqtini o'zgartirib bo'lmaydi.")

    yangi = _parse_dt(args.get("new_date"))
    if yangi is None:
        return _err("Yangi sana/vaqt (new_date) ISO formatda kerak, "
                    "masalan '2026-08-20T15:00:00'.")
    if yangi < datetime.now():
        return _err("O'tgan vaqtga ko'chirib bo'lmaydi.")

    # Yangi vaqt bo'shligini TEKSHIRAMIZ — aks holda ikki mijoz bir
    # vaqtga tushib qoladi va usta muammoga qoladi.
    try:
        avail = await ProviderService.get_availability(
            db, o.provider_id, yangi.date()
        )
        slot = f"{yangi.hour:02d}:{yangi.minute:02d}"
        if slot in (avail.get("booked") or []):
            free = [s for s in (avail.get("slots") or [])
                    if s not in (avail.get("booked") or [])]
            return json.dumps({
                "status": "slot_busy",
                "message": f"{slot} band. Bo'sh vaqtlar: "
                           f"{', '.join(free) if free else 'yo`q'}",
                "free_slots": free,
            }, ensure_ascii=False), None
    except Exception:
        # Bo'sh vaqtni aniqlay olmasak ham ko'chirishga to'sqinlik
        # qilmaymiz: usta o'zi ko'radi va kerak bo'lsa rad etadi.
        pass

    prov = await db.get(Provider, o.provider_id)
    eski = o.date

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": {
                "order_id": o.id,
                "service": o.service_name,
                "provider": prov.name if prov else None,
                "old_date": eski.isoformat() if eski else None,
                "new_date": yangi.isoformat(),
            },
            "message": "Foydalanuvchiga eski va yangi vaqtni ko'rsatib "
                       "tasdiq so'rang, keyin confirm=true bilan qayta chaqiring.",
        }, ensure_ascii=False), None

    o.date = yangi
    # Usta allaqachon tasdiqlagan bo'lsa, o'zgarishdan keyin qayta
    # ko'rib chiqishi kerak.
    if o.status == OrderStatus.confirmed:
        o.status = OrderStatus.pending
    await db.commit()

    if prov and prov.owner_user_id:
        try:
            from app.services.notification_service import NotificationService
            NotificationService.send_notification(
                user_id=prov.owner_user_id,
                ntype="order_rescheduled",
                title="Bron vaqti o'zgardi",
                message=(
                    f"#{o.id} — {o.service_name}. Mijoz vaqtni "
                    f"{yangi.strftime('%d.%m.%Y %H:%M')} ga ko'chirdi. "
                    f"Iltimos tasdiqlang."
                ),
            )
        except Exception:
            pass

    return json.dumps({
        "status": "success",
        "order_id": o.id,
        "new_date": yangi.isoformat(),
        "message": f"Bron {yangi.strftime('%d.%m.%Y %H:%M')} ga ko'chirildi.",
    }, ensure_ascii=False), {"type": "orders_changed", "order_id": o.id}


# ── 4. Manzil / izohni yangilash ─────────────────────────────────────
async def update_booking(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Bron manzili yoki izohini o'zgartiradi (vaqtdan tashqari)."""
    o = await _own_order(db, user_id, args.get("order_id"))
    if not o:
        return _err("Bunday buyurtma topilmadi.")

    holat = o.status.value if o.status else ""
    if holat in _YOPIQ_HOLATLAR:
        return _err("Yakunlangan yoki bekor qilingan bronni o'zgartirib bo'lmaydi.")

    yangi_manzil = (args.get("address") or "").strip() or None
    yangi_izoh = args.get("notes")
    if yangi_manzil is None and yangi_izoh is None:
        return _err("O'zgartirish uchun address yoki notes bering.")

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": {
                "order_id": o.id,
                "old_address": o.address,
                "new_address": yangi_manzil or o.address,
                "new_notes": yangi_izoh if yangi_izoh is not None else o.notes,
            },
            "message": "O'zgarishni ko'rsatib tasdiq so'rang.",
        }, ensure_ascii=False), None

    if yangi_manzil:
        o.address = yangi_manzil
    if yangi_izoh is not None:
        o.notes = str(yangi_izoh)[:1000]
    await db.commit()

    return json.dumps({
        "status": "success",
        "order_id": o.id,
        "address": o.address,
        "message": "Bron ma'lumotlari yangilandi.",
    }, ensure_ascii=False), {"type": "orders_changed", "order_id": o.id}


# ── 5. Keyingi bron (eng yaqin) ──────────────────────────────────────
async def next_booking(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Eng yaqin kelayotgan bron. "Keyingi bronim qachon?" savoliga."""
    from app.models.order import Order, OrderStatus
    from app.models.provider import Provider

    hozir = datetime.now()
    o = (await db.execute(
        select(Order)
        .where(
            Order.user_id == user_id,
            Order.date >= hozir,
            Order.status.notin_([
                OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show,
            ]),
        )
        .order_by(Order.date.asc())
        .limit(1)
    )).scalar_one_or_none()

    if not o:
        return json.dumps({
            "status": "success",
            "booking": None,
            "message": "Kelayotgan bron yo'q.",
        }, ensure_ascii=False), None

    prov = await db.get(Provider, o.provider_id)
    qolgan = o.date - hozir
    return json.dumps({
        "status": "success",
        "booking": {
            "order_id": o.id,
            "service_name": o.service_name,
            "provider_name": prov.name if prov else None,
            "date": o.date.isoformat(),
            "address": o.address,
            "price": o.price,
            "status": o.status.value if o.status else None,
            "in_days": qolgan.days,
            "in_hours": int(qolgan.total_seconds() // 3600),
        },
    }, ensure_ascii=False), None


# ── 6. Usta haqida ma'lumot ──────────────────────────────────────────
async def get_provider_info(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Usta/xizmat haqida: reyting, manzil, narxlar, ish vaqti."""
    from app.models.provider import Provider

    try:
        provider_id = int(args.get("provider_id"))
    except (TypeError, ValueError):
        return _err("provider_id kiritilmagan.")

    prov = await db.get(Provider, provider_id)
    if not prov:
        return _err("Usta topilmadi.")

    meta = prov.metadata_json or {}
    return json.dumps({
        "status": "success",
        "provider": {
            "provider_id": prov.id,
            "name": prov.name,
            "address": getattr(prov, "address", None),
            "rating": getattr(prov, "rating", None),
            "review_count": getattr(prov, "review_count", None),
            # Telefon raqami ATAYLAB berilmaydi (biznes qoidasi).
            "time_slots": meta.get("time_slots"),
            "services": meta.get("services") or meta.get("prices"),
            "lat": prov.lat,
            "lng": prov.lng,
        },
    }, ensure_ascii=False), None


HANDLERS = {
    "get_booking_details": get_booking_details,
    "check_availability": check_availability,
    "reschedule_booking": reschedule_booking,
    "update_booking": update_booking,
    "next_booking": next_booking,
    "get_provider_info": get_provider_info,
}
