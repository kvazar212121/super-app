"""Premium obunani faollashtirish uchun umumiy yordamchilar.

Balans, Payme, Click — har uch yo'l ham shu yerdagi `activate_premium()` orqali
premium'ni ochadi. Payme/Click webhook'lari to'lov tasdiqlanganda shu funksiyani
chaqiradi — admin aralashuvi shart emas.
"""
from __future__ import annotations

import base64
from datetime import datetime, timezone, timedelta
from urllib.parse import quote

from app.models.user import User
from app.models.premium import PremiumPayment
from app.models.transaction import Transaction


def is_active(user: User) -> bool:
    """Foydalanuvchining premium'i hozir amal qiladimi."""
    if not user.is_premium:
        return False
    if user.premium_until is None:
        return True
    return user.premium_until > datetime.now(timezone.utc)


def activate_premium(user: User, payment: PremiumPayment, days: int, *, method: str) -> None:
    """Premium'ni `days` kunga ochadi (yoki mavjud muddatga qo'shadi).

    Chaqiruvchi (endpoint/webhook) `db.commit()` ni o'zi bajaradi — bu funksiya
    faqat obyektlarni tayyorlaydi, session'ga qo'shadi.
    """
    now = datetime.now(timezone.utc)
    base = user.premium_until if (user.premium_until and user.premium_until > now) else now
    user.is_premium = True
    user.premium_until = base + timedelta(days=days)
    payment.status = "confirmed"
    payment.confirmed_at = now
    payment.method = method


def payme_checkout_url(merchant_id: str, payment_id: int, amount_som: float,
                       account_field: str = "order_id", return_url: str = "") -> str:
    """Payme (Paycom) checkout havolasini yaratadi.

    Format: https://checkout.paycom.uz/base64(m=...;ac.<field>=<id>;a=<tiyin>)
    Summa TIYIN'da (so'm × 100). Faqat merchant_id kerak — maxfiy kalit EMAS.
    """
    amount_tiyin = int(round(amount_som * 100))
    parts = [
        f"m={merchant_id}",
        f"ac.{account_field}={payment_id}",
        f"a={amount_tiyin}",
        "l=ru",
    ]
    if return_url:
        parts.append(f"c={return_url}")
    raw = ";".join(parts)
    encoded = base64.b64encode(raw.encode("utf-8")).decode("ascii")
    return f"https://checkout.paycom.uz/{encoded}"


def click_checkout_url(service_id: str, merchant_id: str, payment_id: int,
                       amount_som: float, return_url: str = "") -> str:
    """Click to'lov havolasini yaratadi.

    Format: https://my.click.uz/services/pay?service_id=..&merchant_id=..&amount=..&transaction_param=<id>
    """
    amount = f"{amount_som:.2f}"
    url = (
        "https://my.click.uz/services/pay"
        f"?service_id={quote(service_id)}"
        f"&merchant_id={quote(merchant_id)}"
        f"&amount={amount}"
        f"&transaction_param={payment_id}"
    )
    if return_url:
        url += f"&return_url={quote(return_url, safe='')}"
    return url
