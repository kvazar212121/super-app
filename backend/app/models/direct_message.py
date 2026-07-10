"""Foydalanuvchilararo xabarlar (SMS-uslubidagi to'g'ridan-to'g'ri chat).

Aloqa tarixidagi abonent bilan yozishish uchun. Har xabar bitta jo'natuvchidan
bitta qabul qiluvchiga. Yozishma = ikki foydalanuvchi orasidagi barcha xabarlar.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, Text, Boolean, ForeignKey, func, Index
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class DirectMessage(Base):
    __tablename__ = "direct_messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    sender_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    recipient_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    text: Mapped[str] = mapped_column(Text)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    __table_args__ = (
        Index("ix_dm_pair", "sender_id", "recipient_id"),
        Index("ix_dm_recipient_unread", "recipient_id", "is_read"),
    )
