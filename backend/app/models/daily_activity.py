"""Kunlik faollik — qadamlar va ulardan yoqilgan kaloriya (fitnes ↔ kaloriya integratsiyasi).

Har foydalanuvchi uchun har kunga bitta yozuv. Qadamlar telefon pedometeridan
(client) keladi; kaloriya server-side foydalanuvchi vazniga qarab hisoblanadi.
"""
from datetime import date as date_type, datetime

from sqlalchemy import Integer, Float, Date, DateTime, ForeignKey, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class DailyActivity(Base):
    __tablename__ = "daily_activity"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    date: Mapped[date_type] = mapped_column(Date, index=True)
    steps: Mapped[int] = mapped_column(Integer, default=0)
    calories: Mapped[float] = mapped_column(Float, default=0.0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        UniqueConstraint("user_id", "date", name="uq_daily_activity_user_date"),
    )
