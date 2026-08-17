"""Ish e'lonlari (mijoz -> ustalar) va ustalarning takliflari.

OQIM (Uzum Tezkor / YouDo / Profi.ru kabi platformalar mantig'i):
  1. Mijoz e'lon beradi: nima qilinishi kerak, RASM, taxminiy summa,
     qachon kerakligi, manzil.
  2. E'lon tegishli soha ustalariga ko'rinadi (kategoriya bo'yicha).
  3. Usta TAKLIF beradi: o'z narxi, muddati, izohi.
  4. Mijoz takliflarni ko'rib, bittasini QABUL qiladi.
  5. Qabul qilingach: qolgan takliflar avtomatik rad etiladi, e'lon
     "ish boshlandi" holatiga o'tadi, ikkalasi chatda yozishadi.
  6. Ish tugagach mijoz yakunlaydi va ustani baholaydi.

CHAT: alohida jadval yaratilmaydi — mavjud DirectMessage ishlatiladi
(mijoz <-> usta). Xabarlar SMS bo'limida va bildirishnomalarda chiqadi.
"""

from datetime import datetime
from enum import Enum

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SAEnum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class JobStatus(str, Enum):
    """E'lon holati."""

    open = "open"              # takliflar qabul qilinmoqda
    assigned = "assigned"      # usta tanlandi, ish boshlandi
    completed = "completed"    # ish yakunlandi
    cancelled = "cancelled"    # mijoz bekor qildi
    expired = "expired"        # muddati o'tdi, hech kim tanlanmadi


class OfferStatus(str, Enum):
    """Usta taklifining holati."""

    pending = "pending"      # mijoz hali ko'rmagan/qaror qilmagan
    accepted = "accepted"    # qabul qilindi
    rejected = "rejected"    # rad etildi (yoki boshqasi tanlandi)
    withdrawn = "withdrawn"  # usta o'zi qaytarib oldi


class JobPost(Base):
    """Mijozning ish e'loni."""

    __tablename__ = "job_posts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    # Qaysi soha ustalari ko'radi
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("categories.id"), index=True
    )

    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)

    # "Ish qilinadigan joyni rasmga olib" — 1..N rasm, vergul bilan
    # ajratilgan URL'lar (upload orqali olinadi).
    photos: Mapped[str | None] = mapped_column(Text, nullable=True)

    address: Mapped[str] = mapped_column(String(500))
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Mijoz taklif qilayotgan summa (kelishilishi mumkin).
    # NULL = "narxni ustalar aytsin".
    budget: Mapped[float | None] = mapped_column(Float, nullable=True)

    # "qachon qilinish kerakligini yozib"
    needed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    # Shu vaqtdan keyin yangi taklif qabul qilinmaydi
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )

    status: Mapped[JobStatus] = mapped_column(
        SAEnum(JobStatus), default=JobStatus.open, index=True
    )

    # Qabul qilingan taklif egasi (usta). Tanlangach to'ldiriladi.
    assigned_provider_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("providers.id", ondelete="SET NULL"),
        nullable=True, index=True,
    )
    assigned_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    user = relationship("User", foreign_keys=[user_id])
    category = relationship("Category")
    assigned_provider = relationship("Provider", foreign_keys=[assigned_provider_id])
    offers = relationship(
        "JobOffer", back_populates="job",
        cascade="all, delete-orphan", lazy="selectin",
    )

    @property
    def photo_list(self) -> list[str]:
        return [p for p in (self.photos or "").split(",") if p.strip()]

    def is_open(self, now: datetime | None = None) -> bool:
        """Yangi taklif qabul qilinadimi?"""
        if self.status != JobStatus.open:
            return False
        if self.expires_at:
            now = now or datetime.now(self.expires_at.tzinfo)
            if now > self.expires_at:
                return False
        return True

    def to_dict(self, offers_count: int | None = None) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "category_id": self.category_id,
            "title": self.title,
            "description": self.description,
            "photos": self.photo_list,
            "address": self.address,
            "lat": self.lat,
            "lng": self.lng,
            "budget": self.budget,
            "needed_at": self.needed_at.isoformat() if self.needed_at else None,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "status": self.status.value if self.status else None,
            "assigned_provider_id": self.assigned_provider_id,
            "assigned_at": self.assigned_at.isoformat() if self.assigned_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "offers_count": offers_count,
        }


class JobOffer(Base):
    """Ustaning e'longa bergan taklifi."""

    __tablename__ = "job_offers"
    __table_args__ = (
        # Bitta usta bitta e'longa faqat BITTA taklif beradi.
        # DB darajasida: bir vaqtda kelgan ikkita so'rovni faqat DB
        # to'g'ri hal qiladi.
        UniqueConstraint("job_id", "provider_id", name="uq_job_offer_once"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    job_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("job_posts.id", ondelete="CASCADE"), index=True
    )
    provider_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("providers.id", ondelete="CASCADE"), index=True
    )

    price: Mapped[float] = mapped_column(Float)
    # Necha kunda/soatda bajaradi (erkin matn: "2 kun", "bugun kechqurun")
    duration_text: Mapped[str | None] = mapped_column(String(200), nullable=True)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[OfferStatus] = mapped_column(
        SAEnum(OfferStatus), default=OfferStatus.pending, index=True
    )
    # Mijoz taklifni ko'rdimi (UI'da "yangi" belgisi uchun)
    is_seen: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    job = relationship("JobPost", back_populates="offers")
    provider = relationship("Provider")

    def to_dict(self, provider: object | None = None) -> dict:
        """Taklif ma'lumoti mijozga.

        DIQQAT: ustaning HAQIQIY TELEFON RAQAMI bu yerda QAYTMAYDI.
        Aloqa faqat ilova ichida: chat (DirectMessage) yoki WebRTC
        qo'ng'irog'i. Sabab: raqam tarqalib ketsa biz o'rtadan chiqib
        qolamiz (lead fee yo'qoladi) va foydalanuvchi himoyasiz qoladi.
        Raqam kerak bo'lsa uni bu yerga QAYTA QO'SHMANG.
        """
        p = provider if provider is not None else self.provider
        return {
            "id": self.id,
            "job_id": self.job_id,
            "provider_id": self.provider_id,
            "provider_name": getattr(p, "name", None),
            "provider_rating": getattr(p, "rating", None),
            "provider_review_count": getattr(p, "review_count", None),
            "provider_owner_user_id": getattr(p, "owner_user_id", None),
            "price": self.price,
            "duration_text": self.duration_text,
            "message": self.message,
            "status": self.status.value if self.status else None,
            "is_seen": self.is_seen,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
