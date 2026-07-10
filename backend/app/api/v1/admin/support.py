"""Admin qo'llab-quvvatlash inbox — foydalanuvchi chatlarini ko'rish va javob berish."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User
from app.models.support import SupportTicket, SupportMessage
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


@router.get("/support/tickets")
async def list_tickets(
    status: str | None = Query(None),  # open | closed | None(barchasi)
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Barcha chatlar ro'yxati (oxirgi xabar bo'yicha, yangi o'qilmaganlar tepada)."""
    q = select(SupportTicket).options(selectinload(SupportTicket.messages))
    if status in ("open", "closed"):
        q = q.where(SupportTicket.status == status)
    q = q.order_by(desc(SupportTicket.unread_admin > 0), desc(SupportTicket.last_message_at))
    tickets = (await db.execute(q)).scalars().all()

    # Foydalanuvchi nomlarini bitta so'rovda olamiz
    user_ids = [t.user_id for t in tickets]
    users = {}
    if user_ids:
        rows = (await db.execute(select(User).where(User.id.in_(user_ids)))).scalars().all()
        users = {u.id: u for u in rows}

    out = []
    for t in tickets:
        u = users.get(t.user_id)
        out.append({
            "id": t.id,
            "user_id": t.user_id,
            "user_name": (u.name if u else None) or f"#{t.user_id}",
            "user_phone": (u.phone if u else None) or "",
            "status": t.status,
            "last_message": t.last_message or "",
            "unread": t.unread_admin or 0,
            "last_message_at": t.last_message_at.isoformat() if t.last_message_at else None,
        })
    return {"tickets": out}


@router.get("/support/unread-total")
async def unread_total(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Inbox badge — o'qilmagan chatlar soni (unread_admin > 0 bo'lgan ticketlar)."""
    cnt = await db.scalar(
        select(func.count()).select_from(SupportTicket).where(SupportTicket.unread_admin > 0)
    )
    return {"unread": int(cnt or 0)}


@router.get("/support/tickets/{ticket_id}/messages")
async def get_messages(
    ticket_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Bitta chatning barcha xabarlari. Admin o'qidi — unread_admin nolga tushadi."""
    ticket = (await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))).scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Chat topilmadi")
    msgs = (
        await db.execute(
            select(SupportMessage)
            .where(SupportMessage.ticket_id == ticket_id)
            .order_by(SupportMessage.created_at.asc())
        )
    ).scalars().all()
    if ticket.unread_admin:
        ticket.unread_admin = 0
        await db.commit()
    return {
        "ticket_id": ticket.id,
        "status": ticket.status,
        "messages": [
            {
                "id": m.id, "sender": m.sender, "admin_name": m.admin_name,
                "text": m.text, "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in msgs
        ],
    }


class ReplyIn(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)


@router.post("/support/tickets/{ticket_id}/reply")
async def reply(
    ticket_id: int,
    data: ReplyIn,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Operator javobi. Foydalanuvchi uchun unread_user oshadi."""
    ticket = (await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))).scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Chat topilmadi")
    text = data.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Bo'sh xabar")
    now = datetime.now(timezone.utc)
    msg = SupportMessage(
        ticket_id=ticket.id, sender="admin",
        admin_name=admin.name or "Operator", text=text,
    )
    db.add(msg)
    ticket.last_message = text[:300]
    ticket.last_message_at = now
    ticket.unread_user = (ticket.unread_user or 0) + 1
    ticket.unread_admin = 0
    if ticket.status == "closed":
        ticket.status = "open"
    await db.commit()
    await db.refresh(msg)
    return {
        "id": msg.id, "sender": "admin", "admin_name": msg.admin_name,
        "text": msg.text, "created_at": msg.created_at.isoformat() if msg.created_at else None,
    }


@router.post("/support/tickets/{ticket_id}/close")
async def close_ticket(
    ticket_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Chatni yopiq deb belgilash."""
    ticket = (await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))).scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status_code=404, detail="Chat topilmadi")
    ticket.status = "closed"
    await db.commit()
    return {"status": "closed"}
