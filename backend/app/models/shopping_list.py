from datetime import datetime
from sqlalchemy import DateTime, Integer, Float, Boolean, String, ForeignKey, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(255), default="Bozorlik")
    items: Mapped[list | dict] = mapped_column(JSONB, default=list)
    # items format: [{"name": "Olma", "qty": 2, "unit": "kg", "estimated_price": 20000, "actual_price": null, "is_bought": false}]
    total_estimated_price: Mapped[float] = mapped_column(Float, default=0.0)
    total_actual_price: Mapped[float] = mapped_column(Float, default=0.0)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    is_ordered: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", back_populates="shopping_lists")
