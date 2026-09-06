"""Shikoyatlarni qabul qilish va admin uchun ro'yxatlash.

CHEGARA: bu servis JAZO TAYINLAMAYDI. U faqat yozadi va o'qiydi.
Bloklash, to'xtatish, ball qo'yish — bu yerda yo'q va bo'lmasligi kerak
(ARXITEKTURA.md §20.3).
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.complaint import Complaint
from app.models.order import Order
from app.models.provider import Provider

logger = logging.getLogger(__name__)

KINDS = ("no_show", "quality", "price", "rude", "fraud", "other")

# Bir foydalanuvchi bir kunda nechta shikoyat yoza oladi. Cheklov ataylab
# yumshoq: haqiqiy muammoga duch kelgan odam bir necha marta yozishi
# mumkin, lekin ommaviy tuhmatning oldi olinadi.
DAILY_LIMIT = 10


async def _has_interaction(
    db: AsyncSession,
    reporter_user_id: int,
    provider_id: int | None,
    target_user_id: int | None,
) -> bool:
    """Shikoyatchi bilan shikoyat qilinayotgan o'rtasida buyurtma bo'lganmi.

    Yozuvni bloklamaydi — adminga signal beradi. Aloqasi yo'q odamdan
    kelgan shikoyat shubhaliroq, lekin savdo yoki chatdagi holat uchun
    buyurtma bo'lmasligi ham normal.
    """
    if provider_id is not None:
        q = select(func.count(Order.id)).where(
            Order.user_id == reporter_user_id,
            Order.provider_id == provider_id,
        )
        return bool((await db.execute(q)).scalar() or 0)
    if target_user_id is not None:
        # Ikki oddiy foydalanuvchi: biri ikkinchisining provayderi
        # orqali buyurtma qilganmi.
        q = (
            select(func.count(Order.id))
            .join(Provider, Order.provider_id == Provider.id)
            .where(
                or_(
                    (Order.user_id == reporter_user_id)
                    & (Provider.owner_user_id == target_user_id),
                    (Order.user_id == target_user_id)
                    & (Provider.owner_user_id == reporter_user_id),
                )
            )
        )
        return bool((await db.execute(q)).scalar() or 0)
    return False


async def daily_count(db: AsyncSession, reporter_user_id: int) -> int:
    """Bugun shu odam nechta shikoyat yozgan."""
    boshi = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    q = select(func.count(Complaint.id)).where(
        Complaint.reporter_user_id == reporter_user_id,
        Complaint.created_at >= boshi,
    )
    return int((await db.execute(q)).scalar() or 0)


async def create(
    db: AsyncSession,
    *,
    reporter_user_id: int,
    text: str,
    kind: str = "other",
    provider_id: int | None = None,
    target_user_id: int | None = None,
    order_id: int | None = None,
    ai_summary: str | None = None,
) -> Complaint:
    """Shikoyatni yozadi. Hech kimga jazo qo'llamaydi."""
    if kind not in KINDS:
        kind = "other"

    aloqa = await _has_interaction(db, reporter_user_id, provider_id, target_user_id)

    row = Complaint(
        reporter_user_id=reporter_user_id,
        target_provider_id=provider_id,
        target_user_id=target_user_id,
        order_id=order_id,
        kind=kind,
        text=text.strip()[:4000],
        ai_summary=(ai_summary or None),
        has_interaction=aloqa,
        status="new",
    )
    db.add(row)
    await db.flush()

    # Admin darhol bilsin — aks holda shikoyat hech kim ko'rmaydigan
    # jadvalda yotib qoladi.
    try:
        from app.services.notification_service import NotificationService

        NotificationService.send_notification(
            user_id=1,
            ntype="complaint_new",
            title="📩 Yangi shikoyat",
            message=(
                f"#{row.id} ({kind})"
                + (f", provayder #{provider_id}" if provider_id else "")
                + ("" if aloqa else " — buyurtma tarixi YO'Q")
            ),
        )
    except Exception as exc:  # xabar ketmasa ham shikoyat saqlanib qoladi
        logger.warning("Shikoyat xabarnomasi yuborilmadi: %s", exc)

    return row


async def list_for_admin(
    db: AsyncSession,
    *,
    status: str | None = None,
    provider_id: int | None = None,
    page: int = 1,
    per_page: int = 20,
) -> tuple[list[Complaint], int]:
    base = select(Complaint)
    hisob = select(func.count(Complaint.id))
    if status:
        base = base.where(Complaint.status == status)
        hisob = hisob.where(Complaint.status == status)
    if provider_id is not None:
        base = base.where(Complaint.target_provider_id == provider_id)
        hisob = hisob.where(Complaint.target_provider_id == provider_id)

    jami = int((await db.execute(hisob)).scalar() or 0)
    base = (
        base.order_by(Complaint.created_at.desc(), Complaint.id.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    return list((await db.execute(base)).scalars().all()), jami


async def resolve(
    db: AsyncSession,
    complaint_id: int,
    *,
    status: str,
    admin_user_id: int,
    note: str | None = None,
) -> Complaint | None:
    """Admin qarori. Faqat holat va izoh o'zgaradi — matn va dalil emas."""
    if status not in ("reviewing", "upheld", "rejected"):
        raise ValueError("noto'g'ri status")
    row = await db.get(Complaint, complaint_id)
    if row is None:
        return None
    row.status = status
    row.admin_note = note
    row.resolved_by = admin_user_id
    row.resolved_at = datetime.now(timezone.utc)
    await db.flush()
    return row
