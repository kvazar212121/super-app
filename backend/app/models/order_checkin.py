"""
Ikki tomonlama tasdiqlash (two-way checkin) modeli.
Har bir buyurtma uchun mijoz va usta alohida checkin qiladi.
"""
from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Integer, String, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class CheckinSide(str, Enum):
    user = "user"
    provider = "provider"


class CheckinResponse(str, Enum):
    arrived = "arrived"          # Keldim / Keldi
    delayed = "delayed"          # Kechikaman
    cant_come = "cant_come"      # Bora olmayman
    no_show = "no_show"          # Kelmadi (usta tomonidan)


class OrderCheckin(Base):
    __tablename__ = "order_checkins"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("orders.id"), index=True
    )
    side: Mapped[CheckinSide] = mapped_column(SAEnum(CheckinSide))
    response: Mapped[CheckinResponse] = mapped_column(SAEnum(CheckinResponse))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default="now()"
    )

    order = relationship("Order")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "order_id": self.order_id,
            "side": self.side.value,
            "response": self.response.value,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
