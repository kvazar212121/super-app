"""Buyurtma nizolari (dispute) va refund.

Mijoz buyurtma bo'yicha nizo ochadi (open). Admin ko'rib chiqib hal qiladi:
resolved (kerak bo'lsa refund mijoz balansiga) yoki rejected.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Float, Text, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Dispute(Base):
    __tablename__ = "disputes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    reason: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="open", index=True)  # open|resolved|rejected
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)
    refund_amount: Mapped[float] = mapped_column(Float, default=0.0)
    resolved_by: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
