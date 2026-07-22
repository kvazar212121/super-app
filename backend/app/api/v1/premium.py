"""Foydalanuvchi uchun premium obuna API."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.premium import PremiumPayment
from app.models.transaction import Transaction
from app.services import settings_service, premium_service

router = APIRouter(prefix="/premium", tags=["premium"])


def _is_active(user: User) -> bool:
    return premium_service.is_active(user)


@router.get("/status")
async def premium_status(current: User = Depends(get_current_user)):
    cfg = settings_service.premium_config()
    pay = settings_service.payment_config()
    return {
        "is_premium": _is_active(current),
        "premium_until": current.premium_until.isoformat() if current.premium_until else None,
        "price": cfg["price"],
        "duration_days": cfg["duration_days"],
        "balance": current.balance,
        # Qaysi onlayn to'lov usullari sozlangan (mijoz UI'da faqat shularni ko'rsatadi)
        "payme_enabled": bool(pay["payme_merchant_id"]),
        "click_enabled": bool(pay["click_service_id"] and pay["click_merchant_id"]),
    }


class SubscribeIn(BaseModel):
    method: str = "payme"  # payme | click (premium faqat onlayn to'lov bilan)


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

    method = (data.method or "").lower()

    # MUHIM (moliya modeli):
    #  - Premium FAQAT onlayn to'lov (Payme/Click) orqali olinadi va to'lov
    #    provayderining webhook'i uni AVTOMATIK ochadi — admin tasdig'i shart emas.
    #  - Balans (user.balance) — bu provayderning lead-fee (mijoz topish komissiyasi)
    #    hamyoni. Premium uni hech qachon ishlatmaydi ("balance" usuli yo'q).

    # ── Onlayn to'lov (Payme / Click) — pending yozuv + checkout havolasi ──
    # To'lov provayderi (Payme/Click) webhook orqali tasdiqlaydi va premium
    # AVTOMATIK ochiladi. Admin aralashuvi shart emas.
    if method in ("payme", "click"):
        pay = settings_service.payment_config()
        payment = PremiumPayment(
            user_id=current.id, amount=price, duration_days=days,
            status="pending", method=method,
        )
        db.add(payment)
        await db.commit()
        await db.refresh(payment)

        if method == "payme":
            if not pay["payme_merchant_id"]:
                raise HTTPException(status_code=503, detail="Payme hozircha ulanmagan")
            url = premium_service.payme_checkout_url(
                pay["payme_merchant_id"], payment.id, price,
                account_field=pay["payme_account_field"], return_url=pay["return_url"],
            )
        else:  # click
            if not (pay["click_service_id"] and pay["click_merchant_id"]):
                raise HTTPException(status_code=503, detail="Click hozircha ulanmagan")
            url = premium_service.click_checkout_url(
                pay["click_service_id"], pay["click_merchant_id"], payment.id, price,
                return_url=pay["return_url"],
            )

        return {
            "status": "pending",
            "payment_id": payment.id,
            "amount": price,
            "checkout_url": url,
            "message": "To'lov sahifasiga o'ting. To'lov tasdiqlangach premium avtomatik ochiladi.",
        }

    raise HTTPException(status_code=400, detail="Noma'lum to'lov usuli")
