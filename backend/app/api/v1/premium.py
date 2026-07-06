"""Foydalanuvchi uchun premium obuna API."""
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.premium import PremiumPayment
from app.services import settings_service

router = APIRouter(prefix="/premium", tags=["premium"])


def _is_active(user: User) -> bool:
    if not user.is_premium:
        return False
    if user.premium_until is None:
        return True
    return user.premium_until > datetime.now(timezone.utc)


@router.get("/status")
async def premium_status(current: User = Depends(get_current_user)):
    cfg = settings_service.premium_config()
    return {
        "is_premium": _is_active(current),
        "premium_until": current.premium_until.isoformat() if current.premium_until else None,
        "price": cfg["price"],
        "duration_days": cfg["duration_days"],
        "balance": current.balance,
    }


class SubscribeIn(BaseModel):
    method: str = "manual"  # balance | manual


@router.post("/subscribe")
async def subscribe(
    data: SubscribeIn,
    current: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cfg = settings_service.premium_config()
    price = cfg["price"]
    days = cfg["duration_days"]
    if price <= 0:
        raise HTTPException(status_code=400, detail="Premium hozircha sozlanmagan")

    method = (data.method or "manual").lower()

    if method == "balance":
        if current.balance < price:
            raise HTTPException(
                status_code=400,
                detail=f"Balansда mablag' yetarli emas. Kerak: {int(price)} so'm. Balansni to'ldiring.",
            )
        # Balansdан yechib, darhol ochamiz
        current.balance -= price
        now = datetime.now(timezone.utc)
        base = current.premium_until if (current.premium_until and current.premium_until > now) else now
        current.is_premium = True
        current.premium_until = base + timedelta(days=days)
        db.add(PremiumPayment(
            user_id=current.id, amount=price, duration_days=days,
            status="confirmed", method="balance", confirmed_at=now,
        ))
        await db.commit()
        return {
            "status": "confirmed",
            "premium_until": current.premium_until.isoformat(),
            "message": "Premium ochildi! 🎉",
        }

    # manual — to'lov so'rovi yaratamiz, admin tasdiqlaydi
    payment = PremiumPayment(
        user_id=current.id, amount=price, duration_days=days, status="pending", method="manual",
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return {
        "status": "pending",
        "payment_id": payment.id,
        "amount": price,
        "message": "To'lov so'rovi qabul qilindi. Tasdiqlanganдан keyin premium ochiladi.",
    }
