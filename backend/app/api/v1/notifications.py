from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user
from app.models.user import User
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
async def get_notifications(
    current_user: User = Depends(get_current_user),
):
    """Foydalanuvchining bildirishnomalarini olish."""
    notifications = NotificationService.get_notifications(current_user.id)
    return {
        "notifications": [n.to_dict() for n in notifications],
        "total": len(notifications),
    }


@router.post("/{notification_id}/read", status_code=204)
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
):
    """Bildirishnomani o'qilgan deb belgilash."""
    NotificationService.mark_read(notification_id, current_user.id)


@router.get("/unread-count")
async def unread_count(
    current_user: User = Depends(get_current_user),
):
    """O'qilmagan bildirishnomalar sonini olish."""
    count = NotificationService.unread_count(current_user.id)
    return {"count": count}
