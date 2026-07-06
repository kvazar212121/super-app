from sqlalchemy import Float, Integer, String, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Provider(Base):
    __tablename__ = "providers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("categories.id"), index=True
    )
    name: Mapped[str] = mapped_column(String(300))
    address: Mapped[str] = mapped_column(String(500))
    phone: Mapped[str] = mapped_column(String(20))
    lat: Mapped[float] = mapped_column(Float, default=41.2995)
    lng: Mapped[float] = mapped_column(Float, default=69.2401)
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    review_count: Mapped[int] = mapped_column(Integer, default=0)
    cover_image: Mapped[str | None] = mapped_column(String(500), nullable=True)
    metadata_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)
    is_paused: Mapped[bool] = mapped_column(default=False)
    # Moderatsiya: tasdiqlangan / bloklangan
    is_verified: Mapped[bool] = mapped_column(default=False)
    is_blocked: Mapped[bool] = mapped_column(default=False)
    owner_user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=True, index=True
    )
    balance: Mapped[float] = mapped_column(Float, default=0.0)
    lead_fee: Mapped[float | None] = mapped_column(Float, nullable=True)
    completed_orders_count: Mapped[int] = mapped_column(Integer, default=0)
    cancelled_orders_count: Mapped[int] = mapped_column(Integer, default=0)

    category = relationship("Category", back_populates="providers")
    orders = relationship("Order", back_populates="provider", lazy="selectin")
    reviews = relationship("Review", back_populates="provider", lazy="selectin")
    owner = relationship("User", foreign_keys=[owner_user_id], lazy="selectin")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "category_id": self.category_id,
            "category_key": self.category.key if self.category else None,
            "name": self.name,
            "address": self.address,
            "phone": self.phone,
            "lat": self.lat,
            "lng": self.lng,
            "rating": self.rating,
            "review_count": self.review_count,
            "cover_image": self.cover_image,
            "metadata": self.metadata_json,
            "is_active": self.is_active,
            "is_paused": self.is_paused,
            "is_verified": self.is_verified,
            "is_blocked": self.is_blocked,
            "balance": self.balance,
            "lead_fee": self.lead_fee,
            "completed_orders_count": self.completed_orders_count,
            "cancelled_orders_count": self.cancelled_orders_count,
        }