from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select

from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class FinanceStatsOut(BaseModel):
    total_revenue: float
    total_commission: float
    total_cashback_given: float
    total_payouts: float
    platform_balance: float
    commission_rate: float


class CommissionUpdate(BaseModel):
    rate: float = Field(..., ge=0, le=50)


class PayoutRequest(BaseModel):
    provider_id: int
    amount: float = Field(..., gt=0)
    note: Optional[str] = None


@router.get("/finance/stats", response_model=FinanceStatsOut)
async def finance_stats(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    total_revenue = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                Order.status == OrderStatus.completed
            )
        ) or 0
    )

    from app.models.transaction import Transaction
    total_commission = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.type == "lead_fee",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_cashback_given = 0.0
    commission_rate = 0.0

    return FinanceStatsOut(
        total_revenue=total_revenue,
        total_commission=round(total_commission, 2),
        total_cashback_given=total_cashback_given,
        total_payouts=0.0,
        platform_balance=round(total_commission - total_cashback_given, 2),
        commission_rate=commission_rate,
    )


@router.patch("/finance/commission")
async def update_commission_rate(
    data: CommissionUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return {"message": "Komissiya yangilandi", "rate": data.rate}


@router.post("/finance/payout")
async def create_payout(
    data: PayoutRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == data.provider_id))
    provider = result.scalar_one_or_none()
    if not provider:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")

    return {
        "message": "To'lov yaratildi",
        "provider_id": data.provider_id,
        "amount": data.amount,
        "note": data.note,
    }
