from typing import Optional
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, distinct, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.models.notification import Notification
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class NotificationSend(BaseModel):
    type: str = Field(default="system", pattern="^(push|email|sms|in_app|system)$")
    title: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., min_length=1, max_length=1000)
    target: str = Field(..., pattern="^(all|users|providers|user|provider)$")
    target_id: Optional[int] = None


async def _resolve_target_ids(db: AsyncSession, data: NotificationSend) -> list[int]:
    if data.target in ("user", "provider") and data.target_id:
        return [data.target_id]
    if data.target == "providers":
        rows = await db.execute(
            select(distinct(Provider.owner_user_id)).where(Provider.owner_user_id.isnot(None))
        )
        return [r for r in rows.scalars().all() if r]
    # all / users → barcha faol (users = admin bo'lmaganlar)
    stmt = select(User.id).where(User.is_active == True)
    if data.target == "users":
        stmt = stmt.where(User.is_admin == False)
    rows = await db.execute(stmt)
    return list(rows.scalars().all())


@router.post("/notifications/send")
async def send_notification(
    data: NotificationSend,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Broadcast — target foydalanuvchilarga bildirishnoma yaratadi (ilovada ko'rinadi)."""
    user_ids = await _resolve_target_ids(db, data)
    ntype = "system" if data.type in ("push", "in_app") else data.type
    for uid in user_ids:
        db.add(Notification(user_id=uid, type=ntype, title=data.title, message=data.message))
    await db.commit()
    return {
        "message": "Bildirishnoma yuborildi",
        "sent_count": len(user_ids),
        "target": data.target,
    }


@router.get("/notifications")
async def list_notifications(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """So'nggi yuborilgan bildirishnomalar (audit/ko'rish uchun)."""
    offset = (page - 1) * per_page
    rows = await db.execute(
        select(Notification).order_by(desc(Notification.created_at)).offset(offset).limit(per_page)
    )
    items = [
        {
            "id": n.id, "user_id": n.user_id, "type": n.type,
            "title": n.title, "message": n.message, "is_read": n.is_read,
            "created_at": n.created_at.isoformat() if n.created_at else None,
        }
        for n in rows.scalars().all()
    ]
    total = (await db.execute(select(Notification))).scalars().all()
    return {"items": items, "total": len(total), "page": page, "per_page": per_page}
