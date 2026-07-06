"""Bildirishnoma servisi — DB'ga (notifications jadvali) yozadi.

Ilgari xotiradagi dict ishlatilardi; bu ko'p worker/protsessда ishlamas va restartда
yo'qolardi. Endi doimiy DB'ga yoziladi. Chaqiruv joylari sinxron bo'lgani uchun
sync engine (sync_session) ishlatiladi — yozuvlar kichik, chaqiruvlarni async qilish shart emas.
"""
import logging

from app.db.session import sync_session
from app.models.notification import Notification as NotificationModel

logger = logging.getLogger(__name__)


def _to_dict(row: NotificationModel) -> dict:
    return {
        "id": row.id,
        "user_id": row.user_id,
        "type": row.type,
        "title": row.title,
        "message": row.message,
        "is_read": row.is_read,
        "created_at": row.created_at.isoformat() if row.created_at else None,
    }


class NotificationService:

    @staticmethod
    def send_notification(user_id: int, ntype: str, title: str, message: str) -> dict | None:
        """Yangi bildirishnoma yaratib DB'ga yozadi."""
        try:
            with sync_session() as db:
                row = NotificationModel(
                    user_id=user_id, type=ntype, title=title, message=message
                )
                db.add(row)
                db.commit()
                db.refresh(row)
                return _to_dict(row)
        except Exception as e:
            logger.error(f"send_notification failed (user={user_id}): {e}")
            return None

    @staticmethod
    def get_notifications(user_id: int, limit: int = 100) -> list[dict]:
        """Foydalanuvchining bildirishnomalari (yangidan eskiga)."""
        try:
            with sync_session() as db:
                rows = (
                    db.query(NotificationModel)
                    .filter(NotificationModel.user_id == user_id)
                    .order_by(NotificationModel.created_at.desc())
                    .limit(limit)
                    .all()
                )
                return [_to_dict(r) for r in rows]
        except Exception as e:
            logger.error(f"get_notifications failed (user={user_id}): {e}")
            return []

    @staticmethod
    def get_unread(user_id: int) -> list[dict]:
        """O'qilmagan bildirishnomalar."""
        try:
            with sync_session() as db:
                rows = (
                    db.query(NotificationModel)
                    .filter(NotificationModel.user_id == user_id, NotificationModel.is_read.is_(False))
                    .order_by(NotificationModel.created_at.desc())
                    .all()
                )
                return [_to_dict(r) for r in rows]
        except Exception as e:
            logger.error(f"get_unread failed (user={user_id}): {e}")
            return []

    @staticmethod
    def unread_count(user_id: int) -> int:
        """O'qilmagan bildirishnomalar soni."""
        try:
            with sync_session() as db:
                return (
                    db.query(NotificationModel)
                    .filter(NotificationModel.user_id == user_id, NotificationModel.is_read.is_(False))
                    .count()
                )
        except Exception as e:
            logger.error(f"unread_count failed (user={user_id}): {e}")
            return 0

    @staticmethod
    def mark_read(notification_id, user_id: int) -> None:
        """Bildirishnomani o'qilgan deb belgilash."""
        from fastapi import HTTPException, status

        try:
            nid = int(notification_id)
        except (TypeError, ValueError):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bildirishnoma topilmadi")

        with sync_session() as db:
            row = (
                db.query(NotificationModel)
                .filter(NotificationModel.id == nid, NotificationModel.user_id == user_id)
                .first()
            )
            if not row:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bildirishnoma topilmadi")
            row.is_read = True
            db.commit()

    # ── Yordamchi (semantik) bildirishnomalar ─────────────────────────────

    @staticmethod
    def notify_order_status(user_id: int, order_id: int, status_label: str):
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="order_status_changed",
            title="Buyurtma holati o'zgardi",
            message=f"Sizning #{order_id} raqamli buyurtmangiz holati '{status_label}' ga o'zgardi.",
        )

    @staticmethod
    def notify_new_order_for_provider(user_id: int, order_id: int):
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="new_order",
            title="Yangi buyurtma",
            message=f"Sizga #{order_id} raqamli yangi buyurtma keldi.",
        )

    @staticmethod
    def notify_order_shifted(user_id: int, order_id: int, new_time_label: str):
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="order_time_shifted",
            title="Navbatingiz surildi!",
            message=(
                f"Soha egasi vaqtidan oldin bo'shadi! Sizning #{order_id} raqamli "
                f"buyurtmangiz vaqti oldinga surildi. Yangi vaqt: {new_time_label}. "
                f"Iltimos, belgilangan vaqtda yetib keling."
            ),
        )

    @staticmethod
    def notify_booking_time_arrived(user_id: int, order_id: int, provider_name: str):
        return NotificationService.send_notification(
            user_id=user_id,
            ntype="booking_time_arrived",
            title="Navbatingiz keldi! 🕐",
            message=f"#{order_id} — {provider_name} da vaqtingiz keldi. Joyga boring va ilovadan tasdiqlang.",
        )

    @staticmethod
    def notify_provider_booking_time(provider_user_id: int, order_id: int, client_name: str):
        return NotificationService.send_notification(
            user_id=provider_user_id,
            ntype="booking_time_arrived",
            title=f"Mijoz {client_name} ning vaqti keldi 📋",
            message=f"#{order_id} buyurtma vaqti keldi. Mijoz kelganini tasdiqlang.",
        )
