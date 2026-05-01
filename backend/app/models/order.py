from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Float, Integer, String, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class OrderStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), index=True
    )
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("categories.id"), index=True
    )
    provider_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("providers.id"), index=True
    )
    variant_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("category_variants.id"), nullable=True
    )
    service_name: Mapped[str] = mapped_column(String(300))
    service_icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    address: Mapped[str] = mapped_column(String(500))
    notes: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    date: Mapped[datetime] = mapped_column(DateTime)
    price: Mapped[float] = mapped_column(Float)
    cashback_earned: Mapped[float] = mapped_column(Float, default=0.0)
    status: Mapped[OrderStatus] = mapped_column(
        SAEnum(OrderStatus), default=OrderStatus.pending
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default="now()"
    )

    user = relationship("User", back_populates="orders")
    provider = relationship("Provider", back_populates="orders")
    category = relationship("Category")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "category_id": self.category_id,
            "provider_id": self.provider_id,
            "variant_id": self.variant_id,
            "service_name": self.service_name,
            "service_icon": self.service_icon,
            "address": self.address,
            "notes": self.notes,
            "date": self.date.isoformat() if self.date else None,
            "price": self.price,
            "cashback_earned": self.cashback_earned,
            "status": self.status.value,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }