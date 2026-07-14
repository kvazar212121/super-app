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
        """Yangi bildirishnoma yaratib DB'ga yozadi VA qurilmaga FCM push yuboradi.

        Push tufayli ilova YOPIQ bo'lsa ham bildirishnoma keladi (ovoz bilan).
        """
        try:
            with sync_session() as db:
                row = NotificationModel(
                    user_id=user_id, type=ntype, title=title, message=message
                )
                db.add(row)
                db.commit()
                db.refresh(row)
                result = _to_dict(row)
        except Exception as e:
            logger.error(f"send_notification failed (user={user_id}): {e}")
            return None

        # FCM push (DB yozuvi muvaffaqiyatli bo'lgach) — xato bo'lsa ham DB yozuvi qoladi
        try:
            NotificationService._push_to_user(user_id, title, message, {"type": ntype})
        except Exception as e:
            logger.error(f"FCM push failed (user={user_id}): {e}")
        return result

    @staticmethod
    def _push_to_user(user_id: int, title: str, body: str, data: dict | None = None) -> None:
        """Foydalanuvchining barcha qurilmalariga oddiy bildirishnoma push qiladi. Yaroqsiz token'larni tozalaydi."""
        from app.services import fcm_service
        from app.models.device_token import DeviceToken

        with sync_session() as db:
            tokens = [t.token for t in db.query(DeviceToken.token).filter(DeviceToken.user_id == user_id).all()]
            if not tokens:
                return
            invalid = fcm_service.send_notification_to_tokens(tokens, title, body, data)
            if invalid:
                db.query(DeviceToken).filter(DeviceToken.token.in_(invalid)).delete(synchronize_session=False)
                db.commit()

    @staticmethod
    def push_data_to_user(user_id: int, data: dict) -> None:
        """Faqat-data (silent) push — qo'ng'iroq/CallKit kabi holatlar uchun."""
        from app.services import fcm_service
        from app.models.device_token import DeviceToken

        try:
            with sync_session() as db:
                tokens = [t.token for t in db.query(DeviceToken.token).filter(DeviceToken.user_id == user_id).all()]
                if not tokens:
                    return
                invalid = fcm_service.send_data_to_tokens(tokens, data)
                if invalid:
                    db.query(DeviceToken).filter(DeviceToken.token.in_(invalid)).delete(synchronize_session=False)
                    db.commit()
        except Exception as e:
            logger.error(f"push_data_to_user failed (user={user_id}): {e}")

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

    @staticmethod
    def mark_all_read(user_id: int) -> int:
        """Foydalanuvchining barcha bildirishnomalarini o'qilgan deb belgilaydi."""
        with sync_session() as db:
            n = (
                db.query(NotificationModel)
                .filter(NotificationModel.user_id == user_id, NotificationModel.is_read == False)
                .update({NotificationModel.is_read: True}, synchronize_session=False)
            )
            db.commit()
            return int(n or 0)

    @staticmethod
    def delete_one(notification_id, user_id: int) -> None:
        """Foydalanuvchining bitta bildirishnomasini o'chiradi."""
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
            db.delete(row)
            db.commit()

    @staticmethod
    def clear_all(user_id: int) -> int:
        """Foydalanuvchining BARCHA bildirishnomalarini o'chiradi."""
        with sync_session() as db:
            n = (
                db.query(NotificationModel)
                .filter(NotificationModel.user_id == user_id)
                .delete(synchronize_session=False)
            )
            db.commit()
            return int(n or 0)

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
