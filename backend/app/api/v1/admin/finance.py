from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select

from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.transaction import Transaction
from app.models.setting import PlatformSetting
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class FinanceStatsOut(BaseModel):
    total_revenue: float
    total_commission: float
    total_cashback_given: float
    total_payouts: float
    platform_balance: float
    commission_rate: float
    total_topups: float
    total_refunds: float


class CommissionUpdate(BaseModel):
    rate: float = Field(..., ge=0, le=50)


class ProviderTransactionRequest(BaseModel):
    provider_id: int
    amount: float = Field(..., gt=0)
    type: str # 'topup', 'refund'
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

    total_commission = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.type == "commission_fee",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_topups = float(
        await db.scalar(
            select(func.coalesce(func.sum(Transaction.amount), 0)).where(
                Transaction.type == "topup",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_refunds = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.type == "refund",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_cashback_given = 0.0
    
    setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "commission_rate"))
    commission_rate = float(setting.value) if setting else 15.0

    return FinanceStatsOut(
        total_revenue=total_revenue,
        total_commission=round(total_commission, 2),
        total_cashback_given=total_cashback_given,
        total_payouts=0.0,
        platform_balance=round(total_commission - total_cashback_given, 2),
        commission_rate=commission_rate,
        total_topups=round(total_topups, 2),
        total_refunds=round(total_refunds, 2),
    )


@router.patch("/finance/commission")
async def update_commission_rate(
    data: CommissionUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "commission_rate"))
    if not setting:
        setting = PlatformSetting(key="commission_rate", value=str(data.rate), description="Komissiya foizi (%)")
        db.add(setting)
    else:
        setting.value = str(data.rate)
    await db.commit()
    return {"message": "Komissiya yangilandi", "rate": data.rate}


@router.post("/finance/provider-transaction")
async def create_provider_transaction(
    data: ProviderTransactionRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == data.provider_id))
    provider = result.scalar_one_or_none()
    if not provider:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")

    if data.type not in ["topup", "refund"]:
        raise HTTPException(status_code=400, detail="Noto'g'ri tranzaksiya turi")

    amount = data.amount if data.type == "topup" else -data.amount

    if data.type == "refund" and provider.balance < data.amount:
        # We can allow refunding to negative, or block it. Let's allow it but maybe warn.
        pass

    provider.balance += amount

    transaction = Transaction(
        provider_id=provider.id,
        user_id=provider.owner_user_id,
        type=data.type,
        amount=amount,
        description=data.note or f"Admin: {data.type}",
        status="completed"
    )
    db.add(transaction)
    await db.commit()

    return {
        "message": "Tranzaksiya muvaffaqiyatli amalga oshirildi",
        "provider_id": data.provider_id,
        "new_balance": provider.balance,
        "type": data.type,
        "amount": amount
    }

@router.get("/finance/providers")
async def get_providers_for_finance(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider))
    providers = result.scalars().all()
    return [
        {
            "id": p.id,
            "name": p.name,
            "phone": p.phone,
            "balance": p.balance
        }
        for p in providers
    ]
