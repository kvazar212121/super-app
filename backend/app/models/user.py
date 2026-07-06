from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, Boolean, ForeignKey, func
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
    premium_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    # RBAC: super admin barcha ruxsatga ega; oddiy adminга rol biriktiriladi
    is_super_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    admin_role_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("admin_roles.id", ondelete="SET NULL"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    reminder_offset_minutes: Mapped[int] = mapped_column(Integer, default=10)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    payment_cards = relationship("PaymentCard", back_populates="user", lazy="selectin")
    orders = relationship("Order", back_populates="user", lazy="selectin")
    reviews = relationship("Review", back_populates="user", lazy="selectin")
    notifications = relationship("Notification", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    todos = relationship("Todo", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    plans = relationship("Plan", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    finance_records = relationship("FinanceRecord", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    planned_payments = relationship("PlannedPayment", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    shopping_lists = relationship("ShoppingList", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    workout_plans = relationship("WorkoutPlan", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    workout_logs = relationship("WorkoutLog", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    meal_logs = relationship("MealLog", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    nutrition_profile = relationship("NutritionProfile", back_populates="user", uselist=False, lazy="selectin", cascade="all, delete-orphan")
    alarms = relationship("Alarm", back_populates="user", lazy="selectin", cascade="all, delete-orphan")
    providers = relationship("Provider", primaryjoin="User.id==Provider.owner_user_id", lazy="selectin")

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
            "is_active": self.is_active,
            "reminder_offset_minutes": self.reminder_offset_minutes,
            "created_at": self.created_at,
            "is_provider": len(self.providers) > 0 if hasattr(self, "providers") and self.providers else False,
        }