"""Foydalanuvchi uchun nizo (dispute) API."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.models.dispute import Dispute

router = APIRouter(prefix="/disputes", tags=["disputes"])


class DisputeCreate(BaseModel):
    order_id: int
    reason: str = Field(..., min_length=3, max_length=1000)


@router.post("", status_code=201)
async def create_dispute(
    data: DisputeCreate,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    order = (await db.execute(
        select(Order).where(Order.id == data.order_id, Order.user_id == current.id)
    )).scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    # Ochiq nizo bormi
    existing = (await db.execute(
        select(Dispute).where(Dispute.order_id == data.order_id, Dispute.status == "open")
    )).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Bu buyurtma bo'yicha ochiq nizo mavjud")

    dispute = Dispute(order_id=order.id, user_id=current.id, reason=data.reason, status="open")
    db.add(dispute)
    try:
        order.status = OrderStatus.disputed
    except Exception:
        pass
    await db.commit()
    await db.refresh(dispute)
    return {"id": dispute.id, "status": "open", "message": "Nizo qabul qilindi. Admin ko'rib chiqadi."}


@router.get("/my")
async def my_disputes(current: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(
        select(Dispute).where(Dispute.user_id == current.id).order_by(desc(Dispute.created_at))
    )).scalars().all()
    return [
        {
            "id": d.id, "order_id": d.order_id, "reason": d.reason, "status": d.status,
            "resolution": d.resolution, "refund_amount": d.refund_amount,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in rows
    ]
