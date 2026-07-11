"""Oilaviy moliya guruhi — er-xotin (yoki oila a'zolari) bitta hisobda.

Bir foydalanuvchi guruh yaratadi (yoki taklif qiladi), ikkinchisi QR/kod orqali
qo'shiladi. Guruhga a'zo bo'lgan har kimning kirim/chiqimlari umumiy hisobda
ko'rinadi. Kim qaysi yozuvni qo'shgani `FinanceRecord.user_id` orqali saqlanadi.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FinanceGroup(Base):
    __tablename__ = "finance_groups"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(120), default="Oilaviy byudjet")
    owner_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    invite_code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
