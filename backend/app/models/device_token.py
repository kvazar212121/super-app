"""Foydalanuvchi qurilmalarining FCM push token'lari.

Bir foydalanuvchида bir nechta qurilma bo'lishi mumkin — har biri alohida token.
Push yuborilганда shu jadvaldan foydalanuvchining barcha token'lari olinadi.
"""
from datetime import datetime, timezone

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index

from app.db.base import Base


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(512), nullable=False, unique=True, index=True)
    platform = Column(String(20), nullable=True)  # android | ios | web
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    __table_args__ = (Index("ix_device_tokens_user_id_token", "user_id", "token"),)
