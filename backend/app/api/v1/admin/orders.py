from datetime import date, datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_, desc, and_
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.dispute import Dispute
from app.schemas.order import OrderOut, OrderStatusUpdate
from app.schemas.common import PaginatedResponse
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


# ─────────────────────── NIZOLAR (disputes) ───────────────────────

class DisputeResolve(BaseModel):
    resolution: Optional[str] = None
    refund_amount: float = 0.0


@router.get("/orders/disputes")
async def list_disputes(
    status: Optional[str] = Query(None),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Dispute).order_by(desc(Dispute.created_at)).limit(300)
    if status:
        stmt = select(Dispute).where(Dispute.status == status).order_by(desc(Dispute.created_at)).limit(300)
    rows = (await db.execute(stmt)).scalars().all()
    out = []
    for d in rows:
        u = await db.get(User, d.user_id)
        o = await db.get(Order, d.order_id)
        out.append({
            "id": d.id, "order_id": d.order_id,
            "user_name": (f"{u.name} {u.surname}".strip() if u else None),
            "user_phone": (u.phone if u else None),
            "service_name": (o.service_name if o else None),
            "order_price": (o.price if o else None),
            "reason": d.reason, "status": d.status, "resolution": d.resolution,
            "refund_amount": d.refund_amount,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        })
    return {"disputes": out}


@router.post("/orders/disputes/{dispute_id}/resolve")
async def resolve_dispute(
    dispute_id: int,
    data: DisputeResolve,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    d = await db.get(Dispute, dispute_id)
    if not d:
        raise HTTPException(status_code=404, detail="Nizo topilmadi")
    if d.status != "open":
        raise HTTPException(status_code=400, detail="Nizo allaqachon hal qilingan")
    refund = max(0.0, float(data.refund_amount or 0))
    if refund > 0:
        user = await db.get(User, d.user_id)
        if user:
            user.balance = (user.balance or 0) + refund
        d.refund_amount = refund
    d.status = "resolved"
    d.resolution = data.resolution
    d.resolved_by = admin.id
    d.resolved_at = datetime.now(timezone.utc)
    order = await db.get(Order, d.order_id)
    if order:
        order.status = OrderStatus.cancelled if refund > 0 else OrderStatus.completed
    await db.commit()
    return {"status": "resolved", "refund_amount": refund}


@router.post("/orders/disputes/{dispute_id}/reject")
async def reject_dispute(
    dispute_id: int,
    data: DisputeResolve,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    d = await db.get(Dispute, dispute_id)
    if not d:
        raise HTTPException(status_code=404, detail="Nizo topilmadi")
    d.status = "rejected"
    d.resolution = data.resolution
    d.resolved_by = admin.id
    d.resolved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"status": "rejected"}


class OrderDetailOut(OrderOut):
    user_name: Optional[str] = None
    provider_name: Optional[str] = None
    category_title: Optional[str] = None


@router.get("/orders", response_model=PaginatedResponse)
async def list_all_orders(
    status: str | None = Query(None),
    category_id: int | None = Query(None),
    provider_id: int | None = Query(None),
    user_id: int | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Order).options(
        selectinload(Order.user),
        selectinload(Order.provider),
        selectinload(Order.category),
    )

    if status:
        query = query.where(Order.status == OrderStatus(status))
    if category_id:
        query = query.where(Order.category_id == category_id)
    if provider_id:
        query = query.where(Order.provider_id == provider_id)
    if user_id:
        query = query.where(Order.user_id == user_id)
    if date_from:
        query = query.where(func.date(Order.date) >= date.fromisoformat(date_from))
    if date_to:
        query = query.where(func.date(Order.date) <= date.fromisoformat(date_to))
    if search:
        query = query.where(
            or_(
                Order.service_name.ilike(f"%{search}%"),
                Order.address.ilike(f"%{search}%"),
            )
        )

    count_query = select(func.count()).select_from(Order)
    if status:
        count_query = count_query.where(Order.status == OrderStatus(status))
    if category_id:
        count_query = count_query.where(Order.category_id == category_id)
    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Order.created_at)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for o in items:
        d = o.to_dict()
        d["user_name"] = f"{o.user.name} {o.user.surname}" if o.user else None
        d["provider_name"] = o.provider.name if o.provider else None
        d["category_title"] = o.category.title_uz if o.category else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.get("/orders/{order_id}", response_model=OrderDetailOut)
async def get_order(
    order_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order)
        .options(selectinload(Order.user), selectinload(Order.provider), selectinload(Order.category))
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    d = order.to_dict()
    d["user_name"] = f"{order.user.name} {order.user.surname}" if order.user else None
    d["provider_name"] = order.provider.name if order.provider else None
    d["category_title"] = order.category.title_uz if order.category else None
    return d


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def admin_update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    
    old_status = order.status
    new_status = OrderStatus(data.status)
    order.status = new_status
    await db.flush()
    await db.refresh(order)

    if old_status != new_status:
        import asyncio
        from app.services.notification_service import NotificationService
        status_translations = {
            OrderStatus.pending: "kutilmoqda",
            OrderStatus.accepted: "qabul qilindi",
            OrderStatus.completed: "yakunlandi",
            OrderStatus.cancelled: "bekor qilindi"
        }
        status_str = status_translations.get(new_status, new_status.value)
        # Sync + FCM tarmoq chaqiruvi — event loop'ni bloklamaslik uchun thread'да
        await asyncio.to_thread(
            NotificationService.send_notification,
            order.user_id,
            "order_status_changed",
            "Buyurtma holati o'zgardi",
            f"Sizning #{order.id} raqamli buyurtmangiz holati '{status_str}' ga o'zgardi.",
        )
        if new_status == OrderStatus.completed:
            from app.services.order_service import OrderService
            await OrderService.process_commission(db, order)

    return order


@router.delete("/orders/{order_id}", status_code=204)
async def delete_order(
    order_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    await db.delete(order)
