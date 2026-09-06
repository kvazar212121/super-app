"""Foydalanuvchilararo xabarlar (SMS-uslub) — aloqa tarixidagi abonent bilan yozishish."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func, or_, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.direct_message import DirectMessage

router = APIRouter(prefix="/messages", tags=["messages"])


def _msg_out(m: DirectMessage, me_id: int, job: dict | None = None) -> dict:
    out = {
        "id": m.id,
        "text": m.text,
        "is_mine": m.sender_id == me_id,
        "is_read": m.is_read,
        "created_at": m.created_at.isoformat() if m.created_at else None,
        "job_id": m.job_id,
    }
    if job:
        # Mijoz chatda "bu e'lon bo'yicha kelgan" deb ko'rsatishi uchun
        out["job"] = job
    return out


class SendIn(BaseModel):
    recipient_id: int
    text: str = Field(..., min_length=1, max_length=2000)
    # Usta e'lon orqali yozganda shu yuboriladi. Mijoz chatida
    # "Bu e'lon bo'yicha: <nomi>" deb ko'rinadi.
    job_id: int | None = None


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
    # E'lon konteksti: usta e'lon orqali yozayotgan bo'lsa
    job_ctx = None
    job_id = data.job_id
    if job_id is not None:
        from app.models.job import JobPost
        job = await db.get(JobPost, job_id)
        if job is None:
            raise HTTPException(status_code=404, detail="E'lon topilmadi")
        # Faqat e'lon egasi yoki unga yozayotgan odam bog'lay oladi —
        # aks holda begona odam istalgan e'lon nomini chatga chiqara olardi
        if current.id != job.user_id and data.recipient_id != job.user_id:
            raise HTTPException(
                status_code=403,
                detail="Bu e'lon sizga aloqador emas",
            )
        job_ctx = {"id": job.id, "title": job.title, "status": job.status.value}
    else:
        job_id = None

    msg = DirectMessage(
        sender_id=current.id,
        recipient_id=data.recipient_id,
        text=text,
        job_id=job_id,
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)

    out = _msg_out(msg, current.id, job_ctx)

    # ── REAL VAQTDA yetkazish ────────────────────────────────────────
    # Ilgari xabar faqat bazaga yozilardi va qabul qiluvchi ilovani
    # qayta ochmaguncha ko'rmasdi. Endi onlayn bo'lsa darhol keladi.
    try:
        from app.core.call_manager import manager as call_manager
        payload = dict(out)
        payload["is_mine"] = False  # qabul qiluvchi uchun
        await call_manager.send_personal_message({
            "type": "direct_message",
            "message": payload,
            "sender_id": current.id,
            "sender_name": current.name or f"#{current.id}",
        }, data.recipient_id)
    except Exception as exc:  # WebSocket ishlamasa xabar baribir saqlangan
        import logging
        logging.getLogger(__name__).warning(f"DM realtime yuborilmadi: {exc}")

    return out


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

    # ── E'lon konteksti ──────────────────────────────────────────────
    # Yozishmada bog'langan e'lonlar bo'lsa, ularning nomini bir marta
    # o'qib olamiz (har xabar uchun alohida so'rov yubormaymiz).
    job_ids = {m.job_id for m in msgs if m.job_id}
    jobs_map: dict[int, dict] = {}
    if job_ids:
        from app.models.job import JobPost
        rows = (await db.execute(
            select(JobPost).where(JobPost.id.in_(job_ids))
        )).scalars().all()
        jobs_map = {
            j.id: {"id": j.id, "title": j.title, "status": j.status.value}
            for j in rows
        }

    # ── Suhbatdoshning usta profili ──────────────────────────────────
    # Foydalanuvchi talabi: "chatni o'zida taklif bergan ustalarni
    # yulduzchalari va malumotlar bo'lishi kerak". Mijoz kim bilan
    # gaplashayotganini va uning reytingini ko'rishi kerak.
    peer_provider = None
    if peer is not None:
        from app.models.provider import Provider
        prov = (await db.execute(
            select(Provider)
            .where(Provider.owner_user_id == peer_id)
            .order_by(Provider.id.asc())
            .limit(1)
        )).scalar_one_or_none()
        if prov is not None:
            peer_provider = {
                "id": prov.id,
                "name": prov.name,
                "rating": prov.rating,
                "review_count": prov.review_count,
                "category_id": prov.category_id,
                "address": prov.address,
            }

    return {
        "peer_id": peer_id,
        "peer_name": (peer.name if peer else None) or f"#{peer_id}",
        "peer_provider": peer_provider,
        "messages": [
            _msg_out(m, current.id, jobs_map.get(m.job_id) if m.job_id else None)
            for m in msgs
        ],
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
