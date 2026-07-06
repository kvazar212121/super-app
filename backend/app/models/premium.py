"""Premium obuna to'lovlari.

Foydalanuvchi premium obunaga so'rov beradi (pending). Admin (yoki avtomatik) to'lovni
tasdiqlaydi (confirmed) — shunda foydalanuvchining premium'i belgilangan muddatga ochiladi.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Float, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PremiumPayment(Base):
    __tablename__ = "premium_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    amount: Mapped[float] = mapped_column(Float, default=0.0)
    duration_days: Mapped[int] = mapped_column(Integer, default=30)
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)  # pending|confirmed|rejected
    method: Mapped[str] = mapped_column(String(30), default="balance")  # balance|manual|card
    note: Mapped[str | None] = mapped_column(String(300), nullable=True)
    confirmed_by: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
