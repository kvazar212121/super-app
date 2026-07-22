import json
from typing import Optional, List
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
    total_topup: float
    total_lead_fee: float
    total_premium: float
    total_admin_withdraw: float
    net_profit: float

class TopupRequest(BaseModel):
    provider_id: int
    amount: float = Field(..., gt=0)
    note: Optional[str] = None

class AdminWithdrawRequest(BaseModel):
    amount: float = Field(..., gt=0)
    note: Optional[str] = None

class PremiumPurchaseRequest(BaseModel):
    amount: float = Field(..., gt=0)
    note: Optional[str] = None

class BonusRule(BaseModel):
    min_amount: float
    max_amount: float
    bonus_amount: float

class BonusRulesUpdate(BaseModel):
    rules: List[BonusRule]


@router.get("/finance/stats", response_model=FinanceStatsOut)
async def finance_stats(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    total_topup = float(
        await db.scalar(
            select(func.coalesce(func.sum(Transaction.amount), 0)).where(
                Transaction.type == "topup",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_lead_fee = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.type == "lead_fee",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_premium = float(
        await db.scalar(
            select(func.coalesce(func.sum(Transaction.amount), 0)).where(
                Transaction.type == "premium_subscription",
                Transaction.status == "completed"
            )
        ) or 0
    )

    total_admin_withdraw = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.type == "admin_withdraw",
                Transaction.status == "completed"
            )
        ) or 0
    )

    net_profit = total_lead_fee + total_premium - total_admin_withdraw

    return FinanceStatsOut(
        total_topup=round(total_topup, 2),
        total_lead_fee=round(total_lead_fee, 2),
        total_premium=round(total_premium, 2),
        total_admin_withdraw=round(total_admin_withdraw, 2),
        net_profit=round(net_profit, 2),
    )


@router.get("/finance/bonus-rules")
async def get_bonus_rules(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "topup_bonus_rules"))
    if not setting or not setting.value:
        return []
    try:
        return json.loads(setting.value)
    except (json.JSONDecodeError, TypeError, ValueError):
        return []

@router.post("/finance/bonus-rules")
async def update_bonus_rules(
    data: BonusRulesUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "topup_bonus_rules"))
    rules_json = json.dumps([r.dict() for r in data.rules])
    if not setting:
        setting = PlatformSetting(key="topup_bonus_rules", value=rules_json, description="Top-up bonus rules")
        db.add(setting)
    else:
        setting.value = rules_json
    await db.commit()
    return {"message": "Bonus qoidalari saqlandi"}


@router.post("/finance/topup")
async def topup_provider_balance(
    data: TopupRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    provider = await db.get(Provider, data.provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")

    # B-model: yagona hamyon — provayder egasining user.balance'iga to'ldiriladi
    # (lead fee ham shundan yechiladi). provider.balance ISHLATILMAYDI.
    if not provider.owner_user_id:
        raise HTTPException(status_code=400, detail="Provayderning egasi (foydalanuvchi) yo'q — balans to'ldirib bo'lmaydi")
    owner = await db.get(User, provider.owner_user_id)
    if not owner:
        raise HTTPException(status_code=404, detail="Provayder egasi topilmadi")

    # Add main topup
    owner.balance = (owner.balance or 0.0) + data.amount
    tx = Transaction(
        provider_id=provider.id,
        user_id=owner.id,
        type="topup",
        amount=data.amount,
        description=data.note or "Balans to'ldirildi",
        status="completed"
    )
    db.add(tx)

    # Check for bonuses
    setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "topup_bonus_rules"))
    bonus_amount = 0.0
    if setting and setting.value:
        try:
            rules = json.loads(setting.value)
            for rule in rules:
                if rule["min_amount"] <= data.amount <= rule["max_amount"]:
                    bonus_amount = float(rule["bonus_amount"])
                    break
        except Exception:
            pass

    if bonus_amount > 0:
        owner.balance = (owner.balance or 0.0) + bonus_amount
        bonus_tx = Transaction(
            provider_id=provider.id,
            user_id=owner.id,
            type="topup_bonus",
            amount=bonus_amount,
            description=f"{data.amount} summalik to'ldirish uchun bonus",
            status="completed"
        )
        db.add(bonus_tx)

    await db.commit()

    return {
        "message": "Balans muvaffaqiyatli to'ldirildi",
        "provider_id": provider.id,
        "amount": data.amount,
        "bonus_amount": bonus_amount,
        "new_balance": owner.balance
    }

@router.post("/finance/admin-withdraw")
async def admin_withdraw(
    data: AdminWithdrawRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    tx = Transaction(
        type="admin_withdraw",
        amount=-data.amount,
        description=data.note or "Platformadan xarajat qilingan/yechib olingan summa",
        status="completed"
    )
    db.add(tx)
    await db.commit()
    return {"message": "Muvaffaqiyatli saqlandi"}

@router.post("/finance/premium-purchase")
async def add_premium_purchase(
    data: PremiumPurchaseRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    tx = Transaction(
        type="premium_subscription",
        amount=data.amount,
        description=data.note or "Premium obuna tushumi",
        status="completed"
    )
    db.add(tx)
    await db.commit()
    return {"message": "Muvaffaqiyatli saqlandi"}


@router.get("/finance/providers")
async def get_providers_for_finance(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy.orm import selectinload
    result = await db.execute(select(Provider).options(selectinload(Provider.owner)))
    providers = result.scalars().all()
    # B-model: ko'rsatiladigan balans — provayder egasining user.balance'i
    return [
        {
            "id": p.id,
            "name": p.name,
            "phone": p.phone,
            "balance": (p.owner.balance if p.owner else 0.0),
            "lead_fee": p.lead_fee
        }
        for p in providers
    ]

@router.get("/finance/transactions")
async def get_all_transactions(
    page: int = 1,
    per_page: int = 50,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy.orm import selectinload
    
    count_query = select(func.count(Transaction.id))
    total = (await db.execute(count_query)).scalar() or 0
    
    query = (
        select(Transaction)
        .options(selectinload(Transaction.provider), selectinload(Transaction.user), selectinload(Transaction.order))
        .order_by(Transaction.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    result = await db.execute(query)
    transactions = result.scalars().all()
    
    return {
        "items": [
            {
                "id": t.id,
                "type": t.type,
                "amount": float(t.amount),
                "description": t.description,
                "status": t.status,
                "created_at": t.created_at.isoformat() if t.created_at else None,
                "provider_name": t.provider.name if t.provider else None,
                "user_name": t.user.name if t.user else None,
                "order_id": t.order_id
            }
            for t in transactions
        ],
        "total": total,
        "pages": (total + per_page - 1) // per_page,
        "page": page
    }
