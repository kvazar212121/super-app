"""
Soxa egasi fraud statistikasi — til biriktirish va no_show patternlarni aniqlash.
"""
from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Integer, String, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FraudFlagLevel(str, Enum):
    normal = "normal"
    warning = "warning"       # 5+ no_show oyiga
    alert = "alert"           # 10+ no_show oyiga
    suspended = "suspended"   # 3+ disputed — tekshiruv


class ProviderFraudStats(Base):
    __tablename__ = "provider_fraud_stats"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    provider_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("providers.id"), index=True
    )
    month: Mapped[str] = mapped_column(String(7), index=True)  # "2025-06"
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    no_show_count: Mapped[int] = mapped_column(Integer, default=0)
    disputed_count: Mapped[int] = mapped_column(Integer, default=0)
    flexible_skip_pattern: Mapped[int] = mapped_column(Integer, default=0)
    flag_level: Mapped[FraudFlagLevel] = mapped_column(
        SAEnum(FraudFlagLevel), default=FraudFlagLevel.normal
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default="now()"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "provider_id": self.provider_id,
            "month": self.month,
            "total_orders": self.total_orders,
            "no_show_count": self.no_show_count,
            "disputed_count": self.disputed_count,
            "flexible_skip_pattern": self.flexible_skip_pattern,
            "flag_level": self.flag_level.value,
        }
