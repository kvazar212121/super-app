"""USTA (provayder) tomoni tool'lari.

NEGA KERAK
----------
Loyihada 18 ta provayder portali moduli bor, lekin agentda ular uchun
bironta ham tool yo'q edi. Ikki tomonlama bozorda AI faqat mijozga
xizmat qilardi: usta buyurtmalarini ko'ra olmasdi, e'longa taklif bera
olmasdi, hisobotini so'rayolmasdi (ARXITEKTURA.md §20.1).

NIMA UCHUN BUYURTMA HOLATI YO'Q
-------------------------------
Buyurtmani "bajarildi" qilish mantig'i `api/v1/provider_portal.py`
endpointi ICHIDA: ikki tomonlama tasdiq (usta belgilasa mijoz tasdig'i
kutiladi) va 30 daqiqalik qoida. Uni bu yerga ko'chirsak mantiq ikkiga
bo'linadi va vaqt o'tib bir-biridan uzoqlashadi — bu haqiqiy xatolar
manbai. Shu sabab agent ustani o'sha ekranga YO'NALTIRADI
(`open_app_section`), o'zi holat o'zgartirmaydi.

Bu yerdagi yozuvchi tool'lar faqat TOZA servis metodi bor joyda:
`JobService.make_offer` barcha tekshiruvni o'zi qiladi.
"""
import json
import logging
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.order import Order, OrderStatus
from app.models.provider import Provider
from app.models.provider_blocked_time import ProviderBlockedTime

logger = logging.getLogger(__name__)


async def _my_provider(db: AsyncSession, user_id: int) -> Provider | None:
    """Shu foydalanuvchining provayder profili (birinchisi)."""
    return (await db.execute(
        select(Provider).where(Provider.owner_user_id == user_id)
        .order_by(Provider.id.asc()).limit(1)
    )).scalar_one_or_none()


def _emas_provayder() -> tuple[str, None]:
    return json.dumps({
        "status": "error",
        "message": ("Sizda provayder (usta) profili yo'q. Bu amal faqat "
                    "ro'yxatdan o'tgan ustalar uchun."),
    }, ensure_ascii=False), None


def _parse_dt(value) -> datetime | None:
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return None


async def provider_my_orders(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Ustaga kelgan buyurtmalar."""
    prov = await _my_provider(db, user_id)
    if prov is None:
        return _emas_provayder()

    q = select(Order).where(Order.provider_id == prov.id)
    holat = str(args.get("status") or "").strip().lower()
    if holat:
        try:
            q = q.where(Order.status == OrderStatus(holat))
        except ValueError:
            pass  # noma'lum holat — filtrsiz beramiz
    q = q.order_by(Order.date.desc()).limit(
        max(1, min(int(args.get("limit") or 10), 30))
    )
    rows = (await db.execute(q)).scalars().all()

    return json.dumps({
        "status": "success",
        "provider": prov.name,
        "count": len(rows),
        "orders": [{
            "order_id": o.id,
            "service": o.service_name,
            "date": o.date.isoformat() if o.date else None,
            "price": o.price,
            "address": o.address,
            "order_status": o.status.value if o.status else None,
        } for o in rows],
        # Holat o'zgartirish ekranda — sabab modul izohida.
        "note": ("Buyurtma holatini o'zgartirish uchun foydalanuvchini "
                 "«Buyurtmalarim» bo'limiga yo'naltiring (open_app_section)."),
    }, ensure_ascii=False), None


async def provider_stats(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Ustaning qisqa ko'rsatkichlari."""
    prov = await _my_provider(db, user_id)
    if prov is None:
        return _emas_provayder()

    async def _son(*shartlar) -> int:
        q = select(func.count(Order.id)).where(Order.provider_id == prov.id, *shartlar)
        return int((await db.execute(q)).scalar() or 0)

    return json.dumps({
        "status": "success",
        "provider": prov.name,
        "rating": prov.rating,
        "review_count": prov.review_count,
        "balance": prov.balance,
        "orders_total": await _son(),
        "orders_pending": await _son(Order.status == OrderStatus.pending),
        "orders_completed": prov.completed_orders_count,
        "orders_cancelled": prov.cancelled_orders_count,
        "is_active": prov.is_active,
        "is_paused": prov.is_paused,
    }, ensure_ascii=False), None


async def provider_open_jobs(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Ustaning sohasidagi ochiq e'lonlar — taklif berish uchun."""
    prov = await _my_provider(db, user_id)
    if prov is None:
        return _emas_provayder()

    from app.services.job_service import JobService

    jobs = await JobService.list_for_providers(
        db, prov.category_id, max(1, min(int(args.get("limit") or 10), 30)), prov
    )
    return json.dumps({
        "status": "success",
        "count": len(jobs),
        "jobs": jobs,
    }, ensure_ascii=False, default=str), None


async def provider_send_offer(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """E'longa taklif yuborish. IKKI QADAMLI tasdiq."""
    prov = await _my_provider(db, user_id)
    if prov is None:
        return _emas_provayder()

    try:
        job_id = int(args["job_id"])
        price = float(args["price"])
    except (KeyError, TypeError, ValueError):
        return json.dumps({
            "status": "needs_more_info",
            "ask_user": "Qaysi e'longa va qancha narxda taklif berasiz?",
        }, ensure_ascii=False), None

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": {"job_id": job_id, "price": price,
                        "message": args.get("message")},
            "message": ("Taklif tafsilotlarini ko'rsatib «Shu taklifni "
                        "yuborayinmi?» deb so'rang. «Yuborildi» deb YOZMANG."),
        }, ensure_ascii=False), None

    from app.services.job_service import JobService

    # Barcha tekshiruv (soha mosligi, e'lon ochiqligi, o'z e'loni emasligi,
    # narx musbatligi) `make_offer` ichida — bu yerda takrorlanmaydi.
    offer = await JobService.make_offer(db, job_id, user_id, {
        "provider_id": prov.id,
        "price": price,
        "message": args.get("message"),
        "duration_text": args.get("duration_text"),
    })
    await db.commit()

    return json.dumps({
        "status": "success",
        "offer_id": offer.id,
        "message": "Taklif yuborildi. Mijoz ko'rib chiqadi.",
    }, ensure_ascii=False), {"type": "jobs_changed"}


async def provider_block_time(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Band vaqt qo'shish («ertaga 14:00-18:00 bandman»). IKKI QADAMLI."""
    prov = await _my_provider(db, user_id)
    if prov is None:
        return _emas_provayder()

    boshi = _parse_dt(args.get("start_time"))
    oxiri = _parse_dt(args.get("end_time"))
    if boshi is None or oxiri is None:
        return json.dumps({
            "status": "needs_more_info",
            "ask_user": "Qaysi kun va qaysi soatlardan qaysi soatgacha bandsiz?",
        }, ensure_ascii=False), None
    if oxiri <= boshi:
        return json.dumps({
            "status": "error",
            "message": "Tugash vaqti boshlanish vaqtidan keyin bo'lishi kerak.",
        }, ensure_ascii=False), None

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": {"start": boshi.isoformat(), "end": oxiri.isoformat(),
                        "reason": args.get("reason")},
            "message": ("Vaqtni ko'rsatib tasdiq so'rang. Bu vaqtda sizga "
                        "bron TUSHMAYDI."),
        }, ensure_ascii=False), None

    db.add(ProviderBlockedTime(
        provider_id=prov.id, start_time=boshi, end_time=oxiri,
        reason=(args.get("reason") or None),
    ))
    await db.commit()
    return json.dumps({
        "status": "success",
        "message": "Band vaqt qo'shildi — bu oraliqda bron qabul qilinmaydi.",
    }, ensure_ascii=False), {"type": "provider_calendar_changed"}


HANDLERS = {
    "provider_my_orders": provider_my_orders,
    "provider_stats": provider_stats,
    "provider_open_jobs": provider_open_jobs,
    "provider_send_offer": provider_send_offer,
    "provider_block_time": provider_block_time,
}
