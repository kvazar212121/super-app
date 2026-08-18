"""Firibgarlikdan ogohlantirish va shikoyat.

Foydalanuvchi MAJBURIY talab qildi: sotuvchi bilan aloqa
boshlanishidan OLDIN ogohlantirish chiqadi. Matn bitta joyda
turadi — ilova ham, AI ham shuni ishlatadi, ikki xil gap bo'lmasin.

Shikoyat mavjud `support` (ticket) tizimiga tushadi: adminlar allaqachon
shu qutini kuzatadi, yangi kanal yaratish murojaatlarni yo'qotardi.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.support import SupportMessage, SupportTicket

WARNING_UZ = (
    "⚠️ Ehtiyot bo'ling\n\n"
    "Maklerlar va firibgarlardan saqlaning. Oldindan pul o'tkazmang.\n\n"
    "Agar sotuvchi e'londa yozilganidan boshqa gap aytsa yoki shubhali "
    "taklif qilsa — darhol AI yordamchiga murojaat qiling."
)

WARNING_RU = (
    "⚠️ Будьте осторожны\n\n"
    "Остерегайтесь посредников и мошенников. Не переводите деньги заранее.\n\n"
    "Если продавец говорит не то, что указано в объявлении, или предлагает "
    "подозрительную схему — сразу обратитесь к AI-помощнику."
)


def warning_text(lang: str = "uz") -> str:
    return WARNING_RU if lang == "ru" else WARNING_UZ


def warning_payload(listing_id: int | None = None, lang: str = "uz") -> dict:
    """Ilovaga yuboriladigan ogohlantirish (dialog uchun)."""
    return {
        "text": warning_text(lang),
        "listing_id": listing_id,
        "buttons": (
            [{"key": "ok", "label": "Понятно"},
             {"key": "report", "label": "Пожаловаться"}]
            if lang == "ru" else
            [{"key": "ok", "label": "Tushunarli"},
             {"key": "report", "label": "Shikoyat qilish"}]
        ),
    }


async def report_listing(db: AsyncSession, user_id: int, listing_id: int,
                         reason: str, lang: str = "uz") -> int:
    """Shikoyatni support ticketiga yozadi. Ticket ID qaytaradi."""
    ticket = (
        await db.execute(
            select(SupportTicket)
            .where(SupportTicket.user_id == user_id,
                   SupportTicket.status == "open")
            .order_by(SupportTicket.last_message_at.desc())
        )
    ).scalars().first()
    if ticket is None:
        ticket = SupportTicket(user_id=user_id, status="open",
                               subject="Savdo: shikoyat")
        db.add(ticket)
        await db.flush()

    matn = (f"🚩 E'lon #{listing_id} bo'yicha shikoyat:\n"
            f"{(reason or '').strip() or 'Sabab ko\'rsatilmadi'}")
    db.add(SupportMessage(ticket_id=ticket.id, sender="user", text=matn))
    ticket.last_message = matn[:300]
    ticket.unread_admin = (ticket.unread_admin or 0) + 1
    await db.commit()
    return ticket.id
