"""
Ikki tomonlama tasdiqlash (checkin) API endpointlari.

POST /orders/{id}/checkin     — Mijoz yoki usta javob beradi
GET  /orders/{id}/checkin-status — Checkin holati
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.order import Order
from app.services.checkin_service import CheckinService

router = APIRouter(prefix="/orders", tags=["checkin"])


async def _get_order_for_party(db: AsyncSession, order_id: int, user: User) -> tuple[Order, bool, bool]:
    """Buyurtmani yuklaydi va foydalanuvchi unga aloqadorligini tekshiradi.

    (order, is_customer, is_provider_owner) qaytaradi. Aloqasiz bo'lsa 403.
    """
    order = (
        await db.execute(
            select(Order).options(selectinload(Order.provider)).where(Order.id == order_id)
        )
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    is_customer = order.user_id == user.id
    is_provider_owner = bool(order.provider and order.provider.owner_user_id == user.id)
    if not (is_customer or is_provider_owner):
        raise HTTPException(status_code=403, detail="Bu buyurtmaga ruxsatingiz yo'q")
    return order, is_customer, is_provider_owner


class CheckinRequest(BaseModel):
    side: str = Field(
        ...,
        pattern=r"^(user|provider)$",
        description="Kim javob beryapti: 'user' yoki 'provider'",
    )
    response: str = Field(
        ...,
        pattern=r"^(arrived|delayed|cant_come|no_show)$",
        description="Javob: 'arrived', 'delayed', 'cant_come', 'no_show'",
    )


@router.post("/{order_id}/checkin")
async def submit_checkin(
    order_id: int,
    data: CheckinRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Ikki tomonlama tasdiqlash javobini yuborish."""
    _order, is_customer, is_provider_owner = await _get_order_for_party(db, order_id, user)
    # 'side' faqat o'sha tomon nomidan yuborilishi mumkin
    if data.side == "user" and not is_customer:
        raise HTTPException(status_code=403, detail="Faqat buyurtma egasi 'user' javobini bera oladi")
    if data.side == "provider" and not is_provider_owner:
        raise HTTPException(status_code=403, detail="Faqat usta 'provider' javobini bera oladi")
    result = await CheckinService.process_checkin(
        db=db,
        order_id=order_id,
        side=data.side,
        response=data.response,
    )
    await db.commit()
    return result


@router.get("/{order_id}/checkin-status")
async def get_checkin_status(
    order_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Buyurtmaning checkin holatini olish."""
    await _get_order_for_party(db, order_id, user)  # faqat mijoz yoki usta ko'ra oladi
    return await CheckinService.get_checkin_status(db, order_id)
