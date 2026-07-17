"""CallDeal — zakaz qo'ng'irog'idan keyingi "kelishuv" muzokarasi.

MAQSAD (nega kerak):
    Mijoz provider'ga ZAKAZ qo'ng'irog'i qilib, telefonda narx/vaqt bo'yicha
    gaplashadi. Qo'ng'iroq tugagach IKKALA tomon ham "Kelishdingizmi?" degan
    savolga javob beradi. Bu yozuv ikki tomonning javobini bir joyda ushlab
    turadi va NIZONI (bir tomon "ha", ikkinchisi "yo'q" desa) hal qiladi.

    Bu — platformadan "aylanib o'tish"ga (zakazni yashirin kelishib, tizimga
    yozmaslikka) qarshi asosiy vosita: provider "kelishdik" desa, mijoz uni
    jimgina inkor qila olmaydi — tizim mijozdan qayta so'raydi.

IDENTIFIKATSIYA:
    `call_id` — mijoz (qo'ng'iroq boshlovchi) tomonidan yaratilgan UUID; u
    `call_init` signali orqali ikkala qurilmaga ham yetadi. Shuning uchun
    caller va callee AYNAN BIR yozuvga javob yozadi (backend `call_id` bo'yicha
    topadi yoki yaratadi).

HOLAT (status) — ikki javobdan kelib chiqadi (app/api/v1/calls.py:_evaluate_deal):
    await_provider — mijoz javob berdi, provider hali yo'q
    await_client   — provider javob berdi, mijoz hali yo'q (2.3'da: "pending bron")
    agreed         — ikkalasi "kelishdik" (yoki nizo mijoz foydasiga hal bo'ldi)
    client_recheck — provider "ha", mijoz "yo'q" → mijozdan QAYTA so'raladi
    declined       — kelishuv bo'lmadi (ikkalasi yo'q, yoki provider "yo'q")
"""
from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Integer, String, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class CallDealStatus(str, Enum):
    await_provider = "await_provider"
    await_client = "await_client"
    agreed = "agreed"
    client_recheck = "client_recheck"
    declined = "declined"


class CallDeal(Base):
    __tablename__ = "call_deals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # Ikkala qurilmada bir xil bo'lgan qo'ng'iroq identifikatori (mijoz yaratadi).
    call_id: Mapped[str] = mapped_column(String(64), unique=True, index=True)

    # Mijoz (xizmatni oluvchi) va provider (soha egasi) — HAR IKKALASI ham User.
    # provider_user_id = soha egasining USER id'si (Provider.id EMAS).
    client_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), index=True
    )
    provider_user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), index=True
    )
    category_key: Mapped[str | None] = mapped_column(String(80), nullable=True)

    # Har tomonning javobi: 'agreed' | 'declined' | None (hali javob bermagan).
    provider_response: Mapped[str | None] = mapped_column(String(16), nullable=True)
    client_response: Mapped[str | None] = mapped_column(String(16), nullable=True)

    status: Mapped[str] = mapped_column(
        String(24), default=CallDealStatus.await_provider.value, index=True
    )

    # 2.3'da to'ldiriladi: kelishuv bo'lsa yaratilgan bron (Order) id'si.
    order_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("orders.id"), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "call_id": self.call_id,
            "client_id": self.client_id,
            "provider_user_id": self.provider_user_id,
            "category_key": self.category_key,
            "provider_response": self.provider_response,
            "client_response": self.client_response,
            "status": self.status,
            "order_id": self.order_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
