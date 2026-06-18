"""
Ikki tomonlama tasdiqlash (checkin) API endpointlari.

POST /orders/{id}/checkin     — Mijoz yoki usta javob beradi
GET  /orders/{id}/checkin-status — Checkin holati
"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.services.checkin_service import CheckinService

router = APIRouter(prefix="/orders", tags=["checkin"])


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
    return await CheckinService.get_checkin_status(db, order_id)
