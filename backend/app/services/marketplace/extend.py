"""E'lon muddatini uzaytirish.

Foydalanuvchi qarori: muddat tugagach e'lon o'chmaydi, "Mening
e'lonlarim" da turadi va uzaytiriladi. Premium BEPUL uzaytiradi,
oddiy foydalanuvchi balansidan to'laydi.

To'lov mavjud `Transaction` (balans) tizimi orqali — yangi to'lov
kanali yaratilmaydi, chunki Payme/Click allaqachon balansni
to'ldiradi.
"""
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.marketplace import Listing, ListingStatus
from app.models.transaction import Transaction
from app.models.user import User
from app.services import premium_service

from .limits import _setting_int, expires_at_for, listing_days
from .publisher import own_listing

DEFAULT_EXTEND_PRICE = 5000.0  # so'm


def extend_price() -> float:
    """Uzaytirish narxi (so'm). Adminkadan sozlanadi."""
    return float(_setting_int("market_extend_price", int(DEFAULT_EXTEND_PRICE)))


def price_for(user: User) -> float:
    """Shu foydalanuvchi uchun narx. Premiumga 0."""
    return 0.0 if premium_service.is_active(user) else extend_price()


async def extend_listing(db: AsyncSession, user: User,
                         listing_id: int, lang: str = "uz") -> Listing:
    """E'lon muddatini uzaytiradi. Kerak bo'lsa balansdan yechadi."""
    listing: Listing = await own_listing(db, user.id, listing_id)

    narx = price_for(user)
    if narx > 0:
        if (user.balance or 0) < narx:
            raise HTTPException(
                status_code=402,
                detail=(f"Недостаточно средств: нужно {narx:,.0f} сум."
                        if lang == "ru"
                        else f"Balansda mablag' yetarli emas: "
                             f"{narx:,.0f} so'm kerak.").replace(",", " "),
            )
        user.balance = (user.balance or 0) - narx
        db.add(Transaction(
            user_id=user.id,
            type="expense",
            amount=narx,
            description=f"E'lon muddatini uzaytirish #{listing.id}",
            status="completed",
        ))

    # Muddati tugamagan bo'lsa qolgan kunlar YO'QOLMAYDI — ustiga
    # qo'shiladi. Aks holda erta uzaytirgan odam jarima olardi.
    listing.expires_at = expires_at_for(user, start=listing.expires_at)
    if listing.status == ListingStatus.expired:
        listing.status = ListingStatus.active

    await db.commit()
    await db.refresh(listing)
    return listing


def extend_info(user: User, lang: str = "uz") -> dict:
    """Ilova ko'rsatadigan ma'lumot: narx va necha kunga."""
    narx = price_for(user)
    return {
        "price": narx,
        "days": listing_days(user),
        "free": narx <= 0,
        "message": (
            (f"Premium: bepul, {listing_days(user)} kunga uzaytiriladi"
             if narx <= 0 else
             f"{narx:,.0f} so'm — {listing_days(user)} kunga".replace(",", " "))
            if lang != "ru" else
            (f"Premium: бесплатно, на {listing_days(user)} дней"
             if narx <= 0 else
             f"{narx:,.0f} сум — на {listing_days(user)} дней".replace(",", " "))
        ),
    }
