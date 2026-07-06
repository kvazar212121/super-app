from datetime import datetime
from sqlalchemy import DateTime, Integer, String, Boolean, ForeignKey, func, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Alarm(Base):
    """Majburlovchi budilnik. O'chirish uchun vazifa (math/photo/speech) bajarish shart."""

    __tablename__ = "alarms"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)

    label: Mapped[str] = mapped_column(String(100), default="Budilnik")
    hour: Mapped[int] = mapped_column(Integer, nullable=False)    # 0-23
    minute: Mapped[int] = mapped_column(Integer, nullable=False)  # 0-59
    # Takror kunlar: ISO weekday raqamlari CSV "1,2,3,4,5" (1=Dushanba). Bo'sh = bir martalik.
    repeat_days: Mapped[str] = mapped_column(String(20), default="")
    ringtone: Mapped[str] = mapped_column(String(50), default="default")

    # Vazifa turi: math | photo | speech
    mission_type: Mapped[str] = mapped_column(String(20), default="math")
    # Vazifa sozlamasi JSON:
    #   math   -> {"difficulty": "easy|medium|hard", "count": 1}
    #   photo  -> {"target_uz": "kran", "target_en": "bathroom sink / faucet"}
    #   speech -> {"phrase_uz": "..."} yoki {"random": true}
    mission_config: Mapped[dict] = mapped_column(JSON, default=dict)

    snooze_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    snooze_minutes: Mapped[int] = mapped_column(Integer, default=5)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="alarms")
    logs = relationship("AlarmLog", back_populates="alarm", cascade="all, delete-orphan")


class AlarmLog(Base):
    """Har bir jiringlash tarixi — statistika uchun (necha sekundda o'chirildi, snooze soni)."""

    __tablename__ = "alarm_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    alarm_id: Mapped[int] = mapped_column(Integer, ForeignKey("alarms.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)

    mission_type: Mapped[str] = mapped_column(String(20), default="math")
    fired_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    dismissed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Jiringlashdan to'liq o'chirilgunicha ketgan vaqt (sekund)
    dismiss_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    snooze_count: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    alarm = relationship("Alarm", back_populates="logs")
