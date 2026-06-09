from datetime import datetime
from sqlalchemy import DateTime, Integer, Float, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

class ProductCatalog(Base):
    __tablename__ = "product_catalog"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), index=True)
    unit: Mapped[str] = mapped_column(String(50)) # kg, dona, litr
    average_price: Mapped[float] = mapped_column(Float, default=0.0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
