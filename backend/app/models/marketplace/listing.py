"""E'lon (mahsulot) modeli — OLX uslubidagi savdo.

Nega `jobs` dan alohida: `job_posts` — bu ISH e'loni (mijoz usta
qidiradi). Bu yerda esa BUYUM sotiladi. Ikkalasining maydonlari,
qoidalari va oqimi boshqacha, aralashtirilsa ikkalasi ham chalkashadi.
"""
from datetime import datetime, timezone
import enum

from sqlalchemy import (
    JSON, DateTime, Enum, Float, ForeignKey, Integer, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class ListingStatus(str, enum.Enum):
    """E'lon holati."""

    active = "active"        # Faol, qidiruvda ko'rinadi
    sold = "sold"            # Sotildi
    expired = "expired"      # Muddati tugadi (uzaytirish mumkin)
    hidden = "hidden"        # Egasi vaqtincha yashirdi


class ListingCondition(str, enum.Enum):
    """Buyum holati — xaridor uchun eng muhim ma'lumotlardan biri."""

    new = "new"              # Yangi, ishlatilmagan
    like_new = "like_new"    # Ideal holatda
    good = "good"            # Yaxshi
    used = "used"            # Ishlatilgan
    parts = "parts"          # Ehtiyot qismga


class Listing(Base):
    """Sotuvga qo'yilgan buyum."""

    __tablename__ = "listings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True,
                                    autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), index=True
    )

    # Toifa — `marketplace/fields.py` dagi kalit (telefon, avto...).
    # Category jadvaliga BOG'LANMAYDI: u xizmatlar uchun.
    category_key: Mapped[str] = mapped_column(String(50), index=True)

    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)

    # Narx. `price = None` — "Kelishamiz" (foydalanuvchi so'ragan).
    price: Mapped[float | None] = mapped_column(Float, nullable=True)
    # Sotuvchi qaysi valyutada kiritgani. Xaridorga DOIM so'mda
    # ko'rsatiladi (currency.py konvertatsiya qiladi).
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    is_negotiable: Mapped[bool] = mapped_column(default=False)

    condition: Mapped[ListingCondition] = mapped_column(
        Enum(ListingCondition, native_enum=False, length=20),
        default=ListingCondition.used,
    )

    # Toifaga xos maydonlar: xotira, yil, probeg, o'lcham...
    # Har toifa uchun ro'yxat `fields.py` da.
    attributes: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    address: Mapped[str] = mapped_column(String(500))
    # Koordinata ixtiyoriy: bo'lsa "yaqindagilar" saralanadi.
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)

    status: Mapped[ListingStatus] = mapped_column(
        Enum(ListingStatus, native_enum=False, length=20),
        default=ListingStatus.active,
        index=True,
    )
    views: Mapped[int] = mapped_column(Integer, default=0)

    # Muddat: oddiy foydalanuvchiga qisqa, premiumga uzoq.
    # Tugagach e'lon o'chmaydi — "Mening e'lonlarim" da uzaytiriladi.
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    sold_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    photos = relationship(
        "ListingPhoto",
        back_populates="listing",
        lazy="selectin",
        cascade="all, delete-orphan",
        order_by="ListingPhoto.sort_order",
    )

    def is_open(self, now: datetime | None = None) -> bool:
        """E'lon hozir xaridorlarga ko'rinadimi."""
        if self.status != ListingStatus.active:
            return False
        if self.expires_at is None:
            return True
        hozir = now or datetime.now(timezone.utc)
        muddat = self.expires_at
        # Bazadan tz'siz kelishi mumkin — solishtirishda TypeError
        # bo'lmasligi uchun UTC deb qaraymiz.
        if muddat.tzinfo is None:
            muddat = muddat.replace(tzinfo=timezone.utc)
        return muddat > hozir

    def to_dict(self, *, distance_km: float | None = None,
                price_uzs: float | None = None) -> dict:
        """Mijozga yuboriladigan ko'rinish.

        DIQQAT: sotuvchining TELEFON RAQAMI bu yerda YO'Q va
        qo'shilmasligi kerak. Aloqa faqat ilova ichida (chat/qo'ng'iroq).
        Raqam tarqalsa firibgarlik oshadi va biz oqimdan chiqib qolamiz.
        """
        return {
            "id": self.id,
            "user_id": self.user_id,
            "category_key": self.category_key,
            "title": self.title,
            "description": self.description,
            "price": self.price,
            "currency": self.currency,
            # Xaridor doim so'mda ko'radi (chalg'imasin).
            "price_uzs": price_uzs,
            "is_negotiable": self.is_negotiable,
            "condition": self.condition.value if self.condition else None,
            "attributes": self.attributes or {},
            "address": self.address,
            "lat": self.lat,
            "lng": self.lng,
            "status": self.status.value if self.status else None,
            "views": self.views,
            "photos": [p.url for p in (self.photos or [])],
            "expires_at": (self.expires_at.isoformat()
                           if self.expires_at else None),
            "created_at": (self.created_at.isoformat()
                           if self.created_at else None),
            "distance_km": distance_km,
        }
