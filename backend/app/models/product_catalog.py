from datetime import datetime
from sqlalchemy import DateTime, Integer, Float, String, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

class ProductCatalog(Base):
    __tablename__ = "product_catalog"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), index=True)
    unit: Mapped[str] = mapped_column(String(50)) # kg, dona, litr
    average_price: Mapped[float] = mapped_column(Float, default=0.0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    price_entries = relationship("ProductPriceEntry", back_populates="product", cascade="all, delete-orphan", lazy="selectin")


class ProductPriceEntry(Base):
    __tablename__ = "product_price_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    product_id: Mapped[int] = mapped_column(Integer, ForeignKey("product_catalog.id", ondelete="CASCADE"), index=True)
    source_type: Mapped[str] = mapped_column(String(50))  # 'admin', 'ai', 'user'
    price: Mapped[float] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    product = relationship("ProductCatalog", back_populates="price_entries")

