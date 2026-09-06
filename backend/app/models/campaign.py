"""Sezonli reyting (aksiya) modellari.

MAQSAD: doimiy o'rtacha reyting (Provider.rating) yonida VAQT BILAN
CHEGARALANGAN musobaqa. Masalan "Eng yaxshi sartarosh — Sentabr 2026":
belgilangan sanadan boshlanadi, foydalanuvchilar ovoz beradi, g'olibga
sovrin.

DOIMIY REYTINGDAN FARQI:
- Yulduz soni AHAMIYATSIZ: 1 yulduz ham, 5 yulduz ham 1 ta OVOZ.
  Musobaqada "kim ko'proq mijoz yig'gan" muhim, "kim chiroyliroq
  baholangan" emas.
- Bir foydalanuvchi bitta aksiyada FAQAT BIR MARTA ovoz beradi. Bu DB
  darajasida UNIQUE cheklov bilan ta'minlanadi (ilova mantig'i emas) —
  bir vaqtda ikkita so'rov kelsa ham ikkinchisi DB tomonidan rad etiladi.
- Natija aksiya tugagach ham saqlanib qoladi (arxiv).
"""

from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Campaign(Base):
    """Sovrinli reyting aksiyasi (bitta sezon)."""

    __tablename__ = "campaigns"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Qaysi yo'nalish bo'yicha musobaqa (sartaroshlar, futbol maydonlari...).
    # NULL = barcha kategoriyalar qatnashadi.
    category_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True, index=True,
    )

    # Aksiya oynasi. Ovoz faqat shu oraliqda qabul qilinadi.
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    # Sovrin tavsifi (erkin matn: "1-o'rin: 5 000 000 so'm")
    prize: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Admin aksiyani vaqtincha to'xtatib turishi mumkin (sanani
    # o'zgartirmasdan). Faol bo'lishi uchun is_active=True VA hozirgi
    # vaqt [starts_at, ends_at] oralig'ida bo'lishi kerak.
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)

    # SOXTA OVOZGA QARSHI: True bo'lsa faqat o'sha provayderda YAKUNLANGAN
    # buyurtmasi bor foydalanuvchi ovoz bera oladi.
    #
    # Sovrin pul bo'lgani uchun bu jiddiy: aks holda soxta akkauntlar
    # bilan ovoz yig'ish mumkin. Loyihaning sharh tizimi ham xuddi shu
    # qoidani qo'llaydi (provider_service.add_review) va provider_fraud_stats
    # modeli bor — demak soxta baho bu yerda tanilgan muammo.
    #
    # False qilish mumkin: masalan ochiq "xalq ovozi" tanlovi uchun.
    require_completed_order: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    category = relationship("Category")
    votes = relationship(
        "CampaignVote", back_populates="campaign",
        cascade="all, delete-orphan", lazy="selectin",
    )

    def status(self, now: datetime | None = None) -> str:
        """upcoming | running | finished | disabled"""
        if not self.is_active:
            return "disabled"
        now = now or datetime.now(self.starts_at.tzinfo)
        if now < self.starts_at:
            return "upcoming"
        if now > self.ends_at:
            return "finished"
        return "running"

    def to_dict(self, now: datetime | None = None) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "category_id": self.category_id,
            "starts_at": self.starts_at.isoformat() if self.starts_at else None,
            "ends_at": self.ends_at.isoformat() if self.ends_at else None,
            "prize": self.prize,
            "is_active": self.is_active,
            "require_completed_order": self.require_completed_order,
            "status": self.status(now),
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class CampaignVote(Base):
    """Bitta ovoz: foydalanuvchi -> provayder, ma'lum aksiya doirasida."""

    __tablename__ = "campaign_votes"
    __table_args__ = (
        # ENG MUHIM CHEKLOV: bitta aksiyada bitta foydalanuvchi = bitta ovoz.
        # Ilova mantig'iga tayanmaymiz -- bir vaqtda kelgan ikkita so'rovni
        # faqat DB to'g'ri hal qiladi (race condition).
        UniqueConstraint("campaign_id", "user_id", name="uq_campaign_vote_once"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    campaign_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("campaigns.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    provider_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("providers.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    campaign = relationship("Campaign", back_populates="votes")
    provider = relationship("Provider")
    user = relationship("User")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "campaign_id": self.campaign_id,
            "user_id": self.user_id,
            "provider_id": self.provider_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
