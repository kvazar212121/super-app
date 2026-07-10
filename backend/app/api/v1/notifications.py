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
