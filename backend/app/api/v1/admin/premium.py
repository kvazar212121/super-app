"""Admin: premium obuna sozlamalari va to'lovlarni tasdiqlash."""
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.models.premium import PremiumPayment
from app.models.transaction import Transaction
from app.api.v1.admin.dependencies import require_admin
from app.services import settings_service

router = APIRouter(prefix="/premium", tags=["admin premium"])


class PremiumFeatureFlag(BaseModel):
    key: str
    premium: bool


class PremiumConfigUpdate(BaseModel):
    price: Optional[float] = None
    duration_days: Optional[int] = None
    features: Optional[list[PremiumFeatureFlag]] = None


def _config_out() -> dict:
    cfg = settings_service.premium_config()
    return {
        "price": cfg["price"],
        "duration_days": cfg["duration_days"],
        "features": [
            {"key": k, "label": lbl, "premium": settings_service.feature_premium(k)}
            for k, lbl in settings_service.FEATURE_DEFS
        ],
    }


@router.get("/config")
async def get_premium_config(_admin: User = Depends(require_admin)):
    return _config_out()


@router.put("/config")
async def update_premium_config(data: PremiumConfigUpdate, _admin: User = Depends(require_admin)):
    updates: dict[str, str] = {}
    if data.price is not None:
        updates["premium_price"] = str(max(0.0, data.price))
    if data.duration_days is not None:
        updates["premium_duration_days"] = str(max(1, data.duration_days))
    if data.features is not None:
        valid = {k for k, _ in settings_service.FEATURE_DEFS}
        for f in data.features:
            if f.key in valid:
                updates[f"feature_{f.key}_premium"] = "true" if f.premium else "false"
    if updates:
        settings_service.set_many(updates)
    return _config_out()


class PaymentOut(BaseModel):
    id: int
    user_id: int
    user_name: Optional[str] = None
    user_phone: Optional[str] = None
    amount: float
    duration_days: int
    status: str
    method: str
    created_at: Optional[str] = None
    confirmed_at: Optional[str] = None


async def _payment_out(db: AsyncSession, p: PremiumPayment) -> PaymentOut:
    u = await db.get(User, p.user_id)
    return PaymentOut(
        id=p.id, user_id=p.user_id,
        user_name=(f"{u.name} {u.surname}".strip() if u else None),
        user_phone=(u.phone if u else None),
        amount=p.amount, duration_days=p.duration_days, status=p.status, method=p.method,
        created_at=p.created_at.isoformat() if p.created_at else None,
        confirmed_at=p.confirmed_at.isoformat() if p.confirmed_at else None,
    )


@router.get("/payments")
async def list_payments(
    status: Optional[str] = Query(None),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(PremiumPayment).order_by(desc(PremiumPayment.created_at)).limit(200)
    if status:
        stmt = select(PremiumPayment).where(PremiumPayment.status == status).order_by(desc(PremiumPayment.created_at)).limit(200)
    rows = (await db.execute(stmt)).scalars().all()
    return {"payments": [(await _payment_out(db, p)).model_dump() for p in rows]}


async def _activate_premium(db: AsyncSession, user: User, days: int):
    now = datetime.now(timezone.utc)
    base = user.premium_until if (user.premium_until and user.premium_until > now) else now
    user.is_premium = True
    user.premium_until = base + timedelta(days=days)


@router.post("/payments/{payment_id}/confirm")
async def confirm_payment(
    payment_id: int,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    p = await db.get(PremiumPayment, payment_id)
    if not p:
        raise HTTPException(status_code=404, detail="To'lov topilmadi")
    if p.status == "confirmed":
        return {"status": "already_confirmed"}
    if p.status != "pending":
        raise HTTPException(status_code=400, detail="Faqat kutilayotgan to'lovni tasdiqlash mumkin")
    user = await db.get(User, p.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")

    # Eslatma: premium odatda Payme/Click webhook orqali AVTOMATIK ochiladi.
    # Bu qo'l-tasdiq faqat favqulodda holat uchun (masalan webhook kelmay qolsa).
    # Balansga tegmaymiz — premium hech qachon user.balance'дан yechilmaydi.
    await _activate_premium(db, user, p.duration_days)
    p.status = "confirmed"
    p.confirmed_at = datetime.now(timezone.utc)
    p.confirmed_by = admin.id
    # Moliya defteri: premium daromadi (admin hisobotida ko'rinishi uchun)
    db.add(Transaction(
        user_id=user.id, type="premium_subscription", amount=p.amount,
        description="Premium obuna (admin tasdiqladi)", status="completed",
    ))
    await db.commit()
    return {"status": "confirmed", "premium_until": user.premium_until.isoformat() if user.premium_until else None}


@router.post("/payments/{payment_id}/reject")
async def reject_payment(payment_id: int, _admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    p = await db.get(PremiumPayment, payment_id)
    if not p:
        raise HTTPException(status_code=404, detail="To'lov topilmadi")
    if p.status != "pending":
        raise HTTPException(status_code=400, detail="Faqat kutilayotgan to'lovni rad etish mumkin")
    p.status = "rejected"
    await db.commit()
    return {"status": "rejected"}
