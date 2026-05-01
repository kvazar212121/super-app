from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100))
    surname: Mapped[str] = mapped_column(String(100))
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    telegram_username: Mapped[str | None] = mapped_column(
        String(100), nullable=True
    )
    balance: Mapped[float] = mapped_column(Float, default=0.0)
    cashback: Mapped[float] = mapped_column(Float, default=0.0)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    payment_cards = relationship("PaymentCard", back_populates="user", lazy="selectin")
    orders = relationship("Order", back_populates="user", lazy="selectin")
    reviews = relationship("Review", back_populates="user", lazy="selectin")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "surname": self.surname,
            "phone": self.phone,
            "avatar_url": self.avatar_url,
            "telegram_username": self.telegram_username,
            "balance": self.balance,
            "cashback": self.cashback,
            "is_premium": self.is_premium,
            "is_admin": self.is_admin,
            "created_at": self.created_at,
        }