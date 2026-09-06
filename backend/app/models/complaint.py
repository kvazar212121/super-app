"""Foydalanuvchi shikoyati.

NEGA KERAK
----------
Ilgari mijoz chatda «bu usta meni aldadi» desa, bu HECH QAYERGA
yozilmasdi. `provider_fraud_stats` faqat check-in'dagi `no_show` va
tomonlar ziddiyatidan o'sardi, ya'ni odamning o'z og'zidan chiqqan
shikoyat tizimga umuman kirmasdi.

QAT'IY CHEGARA
--------------
Bu jadval — FAQAT YOZUV. Jazo tayinlamaydi va hech kimni bloklamaydi.
AI shikoyatni shu yerga yozadi, xolos; qaror admin qo'lida.

Nega shunday: AI ni gap bilan aldash mumkin, u bir xil kirishga har xil
javob beradi, jazo esa qaytarib bo'lmaydigan narsa. Shu sababli AI uchun
jazo yozadigan tool UMUMAN mavjud emas — prompt bilan ham unga yetib
bo'lmaydi (ARXITEKTURA.md §20.4).
"""
from datetime import datetime

from sqlalchemy import (
    Boolean, DateTime, ForeignKey, Index, Integer, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Complaint(Base):
    __tablename__ = "complaints"
    __table_args__ = (
        # Admin ro'yxati: yangi shikoyatlar, yangisidan eskisiga.
        Index("ix_complaints_status_created", "status", "created_at"),
        # "Shu provayder ustidan nechta shikoyat bor?"
        Index("ix_complaints_provider_status", "target_provider_id", "status"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # Kim shikoyat qildi. Shikoyatchining o'zi ham javobgar: asossiz
    # shikoyat yozaverish namunasi ko'rinib turishi kerak (§20.8).
    reporter_user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )

    # Kim haqida. Provayder yoki oddiy foydalanuvchi (savdoda sotuvchi ham
    # oddiy foydalanuvchi bo'ladi) — kamida bittasi to'ldiriladi.
    target_provider_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("providers.id", ondelete="SET NULL"), nullable=True
    )
    target_user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    # Dalil: qaysi buyurtma haqida. Bo'lmasligi ham mumkin.
    order_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("orders.id", ondelete="SET NULL"), nullable=True
    )

    # no_show | quality | price | rude | fraud | other
    kind: Mapped[str] = mapped_column(String(20), default="other", index=True)
    text: Mapped[str] = mapped_column(Text)

    # AI ning qisqa tasnifi. Bu MASLAHAT, qaror emas — admin o'qiydi.
    ai_summary: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Shikoyatchi bilan shikoyat qilinayotgan o'rtasida HAQIQIY buyurtma
    # bo'lganmi. Yozuvni BLOKLAMAYDI (savdo yoki chatdagi holat uchun
    # buyurtma bo'lmasligi mumkin), lekin adminga eng muhim signal:
    # aloqasi bo'lmagan odamdan kelgan shikoyat shubhaliroq.
    has_interaction: Mapped[bool] = mapped_column(Boolean, default=False)

    # new | reviewing | upheld | rejected — FAQAT admin o'zgartiradi.
    status: Mapped[str] = mapped_column(String(20), default="new", index=True)
    admin_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolved_by: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "reporter_user_id": self.reporter_user_id,
            "target_provider_id": self.target_provider_id,
            "target_user_id": self.target_user_id,
            "order_id": self.order_id,
            "kind": self.kind,
            "text": self.text,
            "ai_summary": self.ai_summary,
            "has_interaction": self.has_interaction,
            "status": self.status,
            "admin_note": self.admin_note,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "resolved_at": self.resolved_at.isoformat() if self.resolved_at else None,
        }
