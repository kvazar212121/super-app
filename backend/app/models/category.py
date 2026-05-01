from sqlalchemy import Float, Integer, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    key: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    title_uz: Mapped[str] = mapped_column(String(200))
    subtitle_uz: Mapped[str | None] = mapped_column(String(300), nullable=True)
    icon: Mapped[str] = mapped_column(String(50))
    accent_color: Mapped[str] = mapped_column(String(7), default="#4285F4")

    variants = relationship(
        "CategoryVariant", back_populates="category", lazy="selectin",
        cascade="all, delete-orphan"
    )
    providers = relationship(
        "Provider", back_populates="category", lazy="selectin"
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "key": self.key,
            "title_uz": self.title_uz,
            "subtitle_uz": self.subtitle_uz,
            "icon": self.icon,
            "accent_color": self.accent_color,
            "variants": [v.to_dict() for v in self.variants],
        }


class CategoryVariant(Base):
    __tablename__ = "category_variants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("categories.id", ondelete="CASCADE"), index=True
    )
    label_uz: Mapped[str] = mapped_column(String(200))
    base_price: Mapped[float] = mapped_column(Float, default=0.0)

    category = relationship("Category", back_populates="variants")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "category_id": self.category_id,
            "label_uz": self.label_uz,
            "base_price": self.base_price,
        }