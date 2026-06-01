import uuid
from datetime import datetime, timezone
from typing import Optional

from pydantic import BaseModel


class Notification(BaseModel):
    id: str
    user_id: int
    type: str
    title: str
    message: str
    is_read: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "type": self.type,
            "title": self.title,
            "message": self.message,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat(),
        }


# Xotirada saqlash — {user_id: [Notification, ...]}
_notification_store: dict[int, list[Notification]] = {}


class NotificationService:

    @staticmethod
    def send_notification(
        user_id: int,
        ntype: str,
        title: str,
        message: str,
    ) -> Notification:
        """Yangi bildirishnoma yuborish."""
        notification = Notification(
            id=uuid.uuid4().hex,
            user_id=user_id,
            type=ntype,
            title=title,
            message=message,
            created_at=datetime.now(timezone.utc),
        )
        if user_id not in _notification_store:
            _notification_store[user_id] = []
        _notification_store[user_id].append(notification)
        return notification

    @staticmethod
    def get_notifications(user_id: int) -> list[Notification]:
        """Foydalanuvchining barcha bildirishnomalarini qaytarish (yangi eski tartibda)."""
        items = _notification_store.get(user_id, [])
        return sorted(items, key=lambda n: n.created_at, reverse=True)

    @staticmethod
    def get_unread(user_id: int) -> list[Notification]:
        """O'qilmagan bildirishnomalarni qaytarish."""
        items = _notification_store.get(user_id, [])
        return [n for n in items if not n.is_read]

    @staticmethod
    def mark_read(notification_id: str, user_id: int) -> None:
        """Bildirishnomani o'qilgan deb belgilash."""
        items = _notification_store.get(user_id, [])
        for n in items:
            if n.id == notification_id:
                n.is_read = True
                return
        # Agar topilmasa — 404 xatolik
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bildirishnoma topilmadi",
        )

    @staticmethod
    def unread_count(user_id: int) -> int:
        """O'qilmagan bildirishnomalar soni."""
        items = _notification_store.get(user_id, [])
        return sum(1 for n in items if not n.is_read)

    @staticmethod
    def notify_order_status(user_id: int, order_id: int, status_label: str) -> Notification:
        """Mijozga buyurtma holati o'zgarganda xabar."""
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="order_status_changed",
            title="Buyurtma holati o'zgardi",
            message=(
                f"Sizning #{order_id} raqamli buyurtmangiz holati "
                f"'{status_label}' ga o'zgardi."
            ),
        )

    @staticmethod
    def notify_new_order_for_provider(user_id: int, order_id: int) -> Notification:
        """Provayder egasiga yangi buyurtma haqida xabar."""
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="new_order",
            title="Yangi buyurtma",
            message=f"Sizga #{order_id} raqamli yangi buyurtma keldi.",
        )
