from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Numeric
from sqlalchemy.orm import relationship

from app.db.base import Base


class Transaction(Base):
    """Moliya: Foydalanuvchilar va platforma o'rtasidagi pul aylanmasi tarixi."""
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="SET NULL"), nullable=True, index=True)
    
    # income (tushum), expense (xarajat), cashback, commission, payout (provayderga)
    type = Column(String(50), nullable=False, index=True)
    amount = Column(Numeric(15, 2), nullable=False)  # Musbat yoki manfiy bo'lishi mumkin
    description = Column(String(300), nullable=True)
    
    # pending, completed, failed, cancelled
    status = Column(String(50), default="completed", nullable=False)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    user = relationship("User", back_populates="transactions")
    order = relationship("Order", back_populates="transactions")
