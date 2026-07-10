"""Foydalanuvchi qo'llab-quvvatlash chati (operator bilan yozishma)."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.support import SupportTicket, SupportMessage

router = APIRouter(prefix="/support", tags=["support"])


def _msg_out(m: SupportMessage) -> dict:
    return {
        "id": m.id,
        "sender": m.sender,
        "admin_name": m.admin_name,
        "text": m.text,
        "created_at": m.created_at.isoformat() if m.created_at else None,
    }


async def _get_or_create_ticket(db: AsyncSession, user_id: int) -> SupportTicket:
    ticket = (
        await db.execute(
            select(SupportTicket)
            .where(SupportTicket.user_id == user_id, SupportTicket.status == "open")
            .order_by(SupportTicket.last_message_at.desc())
        )
    ).scalars().first()
    if ticket is None:
        ticket = SupportTicket(user_id=user_id, status="open")
        db.add(ticket)
        await db.commit()
        await db.refresh(ticket)
    return ticket


@router.get("/thread")
async def get_thread(
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mening qo'llab-quvvatlash yozishmam (barcha xabarlar). O'qilganlarni belgilaydi."""
    ticket = await _get_or_create_ticket(db, current.id)
    msgs = (
        await db.execute(
            select(SupportMessage)
            .where(SupportMessage.ticket_id == ticket.id)
            .order_by(SupportMessage.created_at.asc())
        )
    ).scalars().all()
    # Foydalanuvchi ochdi — o'qilmagan (admin'dan kelgan) hisobini nolga tushiramiz
    if ticket.unread_user:
        ticket.unread_user = 0
        await db.commit()
    return {
        "ticket_id": ticket.id,
        "status": ticket.status,
        "messages": [_msg_out(m) for m in msgs],
    }


class SendIn(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)


@router.post("/messages")
async def send_message(
    data: SendIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Operatorga xabar yuborish."""
    text = data.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Bo'sh xabar")
    ticket = await _get_or_create_ticket(db, current.id)
    now = datetime.now(timezone.utc)
    msg = SupportMessage(ticket_id=ticket.id, sender="user", text=text)
    db.add(msg)
    ticket.last_message = text[:300]
    ticket.last_message_at = now
    ticket.status = "open"
    ticket.unread_admin = (ticket.unread_admin or 0) + 1  # admin uchun yangi o'qilmagan
    await db.commit()
    await db.refresh(msg)
    return _msg_out(msg)


@router.get("/unread")
async def unread_count(
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchi uchun operatordan kelgan o'qilmagan xabarlar soni (badge)."""
    total = await db.scalar(
        select(func.coalesce(func.sum(SupportTicket.unread_user), 0)).where(
            SupportTicket.user_id == current.id
        )
    )
    return {"unread": int(total or 0)}
