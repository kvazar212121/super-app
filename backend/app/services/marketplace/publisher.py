"""Qoralamani HAQIQIY e'longa aylantirish va e'lonni boshqarish.

Bu yerda barcha yozuv amallari to'plangan — har biri `user_id`
bo'yicha tekshiradi. Begona e'longa tegib bo'lmasligi loyihaning
qat'iy qoidasi va test bilan qo'riqlanadi.
"""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.marketplace import Listing, ListingPhoto, ListingStatus
from app.models.user import User

from .currency import to_uzs, usd_rate
from .draft import ListingDraft
from .limits import check_can_create, expires_at_for
from .photos import check as photos_check, trim
from .validator import ask_text, missing_fields


async def create_listing(db: AsyncSession, user: User,
                         draft: ListingDraft, lang: str = "uz") -> Listing:
    """Qoralamadan e'lon yaratadi.

    Chaqiruvchi TASDIQNI oldindan olgan bo'lishi kerak — bu funksiya
    darhol bazaga yozadi.
    """
    missing = missing_fields(draft)
    if missing:
        raise HTTPException(status_code=400,
                            detail=ask_text(draft, lang) or "Ma'lumot yetarli emas")

    xato = photos_check(draft.photos, user, lang)
    if xato:
        raise HTTPException(status_code=400, detail=xato)

    await check_can_create(db, user, lang)

    if draft.price is not None and draft.price <= 0:
        raise HTTPException(status_code=400, detail="Narx noto'g'ri")

    listing = Listing(
        user_id=user.id,
        category_key=draft.category_key or "boshqa",
        title=(draft.title or "").strip()[:200],
        # Tavsif bo'sh bo'lsa yig'ilgan ma'lumotdan tuziladi: quruq
        # nomli e'lon xaridorga ishonch bermaydi.
        description=((draft.description or "").strip()
                     or draft.auto_description()
                     or (draft.title or "").strip()),
        price=draft.price,
        currency=(draft.currency or "UZS").upper()[:3],
        is_negotiable=bool(draft.is_negotiable or draft.price is None),
        condition=draft.condition,
        attributes=draft.attributes or {},
        address=(draft.address or "").strip()[:500],
        lat=draft.lat,
        lng=draft.lng,
        status=ListingStatus.active,
        expires_at=expires_at_for(user),
    )
    db.add(listing)
    await db.flush()

    for i, url in enumerate(trim(draft.photos, user)):
        db.add(ListingPhoto(listing_id=listing.id, url=url, sort_order=i))

    await db.commit()
    await db.refresh(listing)
    return listing


async def own_listing(db: AsyncSession, user_id: int, listing_id: int) -> Listing:
    """Foydalanuvchining O'Z e'loni. Begonasi bo'lsa 404.

    Ataylab 404 (403 emas): boshqa odamning e'loni bor-yo'qligini
    ham bildirmaydi.
    """
    listing = await db.get(Listing, listing_id)
    if listing is None or listing.user_id != user_id:
        raise HTTPException(status_code=404, detail="E'lon topilmadi")
    return listing


async def mark_sold(db: AsyncSession, user_id: int, listing_id: int) -> Listing:
    listing = await own_listing(db, user_id, listing_id)
    listing.status = ListingStatus.sold
    listing.sold_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(listing)
    return listing


async def close_listing(db: AsyncSession, user_id: int,
                        listing_id: int) -> Listing:
    """E'lonni yashirish (o'chirish o'rniga: qayta e'lon qilish oson)."""
    listing = await own_listing(db, user_id, listing_id)
    listing.status = ListingStatus.hidden
    await db.commit()
    await db.refresh(listing)
    return listing


async def reopen_listing(db: AsyncSession, user: User,
                         listing_id: int) -> Listing:
    """Sotilgan/yashirilgan e'lonni qayta faollashtirish."""
    listing = await own_listing(db, user.id, listing_id)
    await check_can_create(db, user)
    listing.status = ListingStatus.active
    listing.sold_at = None
    listing.expires_at = expires_at_for(user)
    await db.commit()
    await db.refresh(listing)
    return listing


async def my_listings(db: AsyncSession, user_id: int) -> list[Listing]:
    rows = await db.execute(
        select(Listing).where(Listing.user_id == user_id)
        .order_by(Listing.created_at.desc())
    )
    return list(rows.scalars().all())


async def get_public(db: AsyncSession, listing_id: int,
                     *, viewer_id: int | None = None,
                     count_view: bool = True) -> dict:
    """Bitta e'lonning ochiq ko'rinishi (telefon raqamisiz!)."""
    listing = await db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="E'lon topilmadi")
    if count_view and viewer_id != listing.user_id:
        listing.views = (listing.views or 0) + 1
        await db.commit()
        await db.refresh(listing)
    rate = await usd_rate()
    return listing.to_dict(
        price_uzs=to_uzs(listing.price, listing.currency, rate)
    )


async def expire_old(db: AsyncSession) -> int:
    """Muddati tugagan e'lonlarni `expired` qiladi. Scheduler chaqiradi.

    E'lon O'CHIRILMAYDI: egasi "Mening e'lonlarim" dan uzaytiradi.
    """
    now = datetime.now(timezone.utc)
    rows = await db.execute(
        select(Listing).where(
            Listing.status == ListingStatus.active,
            Listing.expires_at.is_not(None),
            Listing.expires_at <= now,
        )
    )
    items = list(rows.scalars().all())
    for item in items:
        item.status = ListingStatus.expired
    if items:
        await db.commit()
    return len(items)
