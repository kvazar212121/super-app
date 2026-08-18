"""E'lon rasmlari.

Alohida jadval, chunki bitta e'londa bir nechta rasm bo'ladi
(foydalanuvchi talabi: kamida 3, ko'pi 6). Tartib muhim —
birinchi rasm kartada asosiy bo'lib ko'rinadi.
"""
from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class ListingPhoto(Base):
    """E'longa biriktirilgan bitta rasm."""

    __tablename__ = "listing_photos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True,
                                    autoincrement=True)
    listing_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("listings.id", ondelete="CASCADE"), index=True
    )
    url: Mapped[str] = mapped_column(String(500))
    # 0 — asosiy rasm (kartada ko'rinadigan).
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    listing = relationship("Listing", back_populates="photos")
