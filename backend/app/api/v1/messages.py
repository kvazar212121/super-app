"""Foydalanuvchilararo xabarlar (SMS-uslub) — aloqa tarixidagi abonent bilan yozishish."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func, or_, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.direct_message import DirectMessage

router = APIRouter(prefix="/messages", tags=["messages"])


def _msg_out(m: DirectMessage, me_id: int) -> dict:
    return {
        "id": m.id,
        "text": m.text,
        "is_mine": m.sender_id == me_id,
        "is_read": m.is_read,
        "created_at": m.created_at.isoformat() if m.created_at else None,
    }


class SendIn(BaseModel):
    recipient_id: int
    text: str = Field(..., min_length=1, max_length=2000)


@router.post("/send")
async def send_message(
    data: SendIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Abonentga xabar yuborish."""
    if data.recipient_id == current.id:
        raise HTTPException(status_code=400, detail="O'zingizga xabar yubora olmaysiz")
    text = data.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Bo'sh xabar")
    peer = (await db.execute(select(User).where(User.id == data.recipient_id))).scalar_one_or_none()
    if peer is None:
        raise HTTPException(status_code=404, detail="Abonent topilmadi")
    msg = DirectMessage(sender_id=current.id, recipient_id=data.recipient_id, text=text)
    db.add(msg)
    await db.commit()
    await db.refresh(msg)
    return _msg_out(msg, current.id)


@router.get("/thread/{peer_id}")
async def get_thread(
    peer_id: int,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Abonent bilan yozishma (barcha xabarlar). Kelgan xabarlarni o'qilgan qiladi."""
    msgs = (
        await db.execute(
            select(DirectMessage)
            .where(
                or_(
                    and_(DirectMessage.sender_id == current.id,
                         DirectMessage.recipient_id == peer_id),
                    and_(DirectMessage.sender_id == peer_id,
                         DirectMessage.recipient_id == current.id),
                )
            )
            .order_by(DirectMessage.created_at.asc())
        )
    ).scalars().all()
    # Kelgan (o'qilmagan) xabarlarni o'qilgan deb belgilaymiz
    changed = False
    for m in msgs:
        if m.recipient_id == current.id and not m.is_read:
            m.is_read = True
            changed = True
    if changed:
        await db.commit()
    peer = (await db.execute(select(User).where(User.id == peer_id))).scalar_one_or_none()
    return {
        "peer_id": peer_id,
        "peer_name": (peer.name if peer else None) or f"#{peer_id}",
        "messages": [_msg_out(m, current.id) for m in msgs],
    }


@router.get("/conversations")
async def list_conversations(
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Barcha yozishmalar ro'yxati (har abonent uchun oxirgi xabar + o'qilmagan soni)."""
    me = current.id
    rows = (
        await db.execute(
            select(DirectMessage)
            .where(or_(DirectMessage.sender_id == me, DirectMessage.recipient_id == me))
            .order_by(desc(DirectMessage.created_at))
        )
    ).scalars().all()

    # Peer bo'yicha guruhlash (birinchi uchragan — eng yangi)
    convos: dict[int, dict] = {}
    for m in rows:
        peer_id = m.recipient_id if m.sender_id == me else m.sender_id
        c = convos.get(peer_id)
        if c is None:
            c = {"peer_id": peer_id, "last_message": m.text, "last_at": m.created_at, "unread": 0}
            convos[peer_id] = c
        if m.recipient_id == me and not m.is_read:
            c["unread"] += 1

    if not convos:
        return {"conversations": []}

    users = {
        u.id: u
        for u in (await db.execute(select(User).where(User.id.in_(list(convos.keys()))))).scalars().all()
    }
    out = []
    for pid, c in convos.items():
        u = users.get(pid)
        out.append({
            "peer_id": pid,
            "peer_name": (u.name if u else None) or f"#{pid}",
            "peer_phone": (u.phone if u else None) or "",
            "last_message": c["last_message"],
            "last_at": c["last_at"].isoformat() if c["last_at"] else None,
            "unread": c["unread"],
        })
    out.sort(key=lambda x: x["last_at"] or "", reverse=True)
    return {"conversations": out}


@router.get("/unread-count")
async def unread_count(
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """O'qilmagan xabarlar soni (badge uchun)."""
    n = await db.scalar(
        select(func.count()).select_from(DirectMessage).where(
            DirectMessage.recipient_id == current.id, DirectMessage.is_read == False
        )
    )
    return {"unread": int(n or 0)}


@router.delete("/thread/{peer_id}")
async def delete_thread(
    peer_id: int,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Abonent bilan yozishmani o'chirish (faqat o'z ko'rinishida — ikki tomon xabarlari)."""
    from sqlalchemy import delete as sql_delete
    await db.execute(
        sql_delete(DirectMessage).where(
            or_(
                and_(DirectMessage.sender_id == current.id, DirectMessage.recipient_id == peer_id),
                and_(DirectMessage.sender_id == peer_id, DirectMessage.recipient_id == current.id),
            )
        )
    )
    await db.commit()
    return {"deleted": True}
