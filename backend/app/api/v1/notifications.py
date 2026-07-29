from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.device_token import DeviceToken
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


class TokenIn(BaseModel):
    token: str = Field(..., min_length=10, max_length=512)
    platform: str | None = Field(default=None, max_length=20)


@router.post("/register-token", status_code=204)
async def register_token(
    data: TokenIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Qurilmaning FCM push token'ini saqlaydi (ilova yopiq bo'lsa ham push kelishi uchun).

    Login'da va token yangilanganda ilova chaqiradi. Bir token faqat bitta userga bog'lanadi.
    """
    existing = (
        await db.execute(select(DeviceToken).where(DeviceToken.token == data.token))
    ).scalar_one_or_none()
    if existing:
        # Token boshqa/shu userга bog'langan bo'lsa — joriy userга ko'chiramiz
        existing.user_id = current_user.id
        existing.platform = data.platform or existing.platform
        # updated_at'ni ATAYLAB yangilaymiz: bu "qurilma oxirgi marta qachon
        # o'zini tasdiqlagan" degani. Aks holda hech bir maydon o'zgarmasa
        # SQLAlchemy UPDATE yubormaydi va onupdate ishlamay, sana eskirib qoladi.
        existing.updated_at = datetime.now(timezone.utc)
    else:
        db.add(DeviceToken(user_id=current_user.id, token=data.token, platform=data.platform))
    await db.commit()
    return None


@router.delete("/register-token", status_code=204)
async def unregister_token(
    data: TokenIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Logout'da token'ni o'chiradi (bu qurilmaga endi push kelmaydi)."""
    await db.execute(
        DeviceToken.__table__.delete().where(
            DeviceToken.token == data.token, DeviceToken.user_id == current_user.id
        )
    )
    await db.commit()
    return None


@router.get("")
async def get_notifications(
    current_user: User = Depends(get_current_user),
):
    """Foydalanuvchining bildirishnomalarini olish."""
    notifications = NotificationService.get_notifications(current_user.id)
    return {
        "notifications": notifications,
        "total": len(notifications),
    }


@router.post("/{notification_id}/read", status_code=204)
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
):
    """Bildirishnomani o'qilgan deb belgilash."""
    NotificationService.mark_read(notification_id, current_user.id)


@router.post("/read-all")
async def mark_all_read(current_user: User = Depends(get_current_user)):
    """Barcha bildirishnomalarni o'qilgan deb belgilash."""
    n = NotificationService.mark_all_read(current_user.id)
    return {"marked": n}


@router.delete("/{notification_id}", status_code=204)
async def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
):
    """Bitta bildirishnomani o'chirish."""
    NotificationService.delete_one(notification_id, current_user.id)


@router.delete("")
async def clear_notifications(current_user: User = Depends(get_current_user)):
    """Barcha bildirishnomalarni tozalash."""
    n = NotificationService.clear_all(current_user.id)
    return {"cleared": n}


@router.get("/unread-count")
async def unread_count(
    current_user: User = Depends(get_current_user),
):
    """O'qilmagan bildirishnomalar sonini olish."""
    count = NotificationService.unread_count(current_user.id)
    return {"count": count}
