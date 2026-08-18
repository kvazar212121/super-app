"""E'lon chegaralari: muddat, e'lon soni, rasm soni.

Barcha raqamlar adminkadan sozlanadi (`settings_service`), chunki
foydalanuvchi boshqaruvni admin panelida so'radi. Sozlama o'qilmasa
standart qiymat ishlaydi — savdo bo'limi DB nosozligidan to'xtamasin.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.marketplace import Listing, ListingStatus
from app.models.user import User
from app.services import premium_service

DEFAULT_FREE_DAYS = 7
DEFAULT_PREMIUM_DAYS = 30
DEFAULT_FREE_LIMIT = 5
DEFAULT_PREMIUM_LIMIT = 50
DEFAULT_MIN_PHOTOS = 3
DEFAULT_MAX_PHOTOS = 6
DEFAULT_PREMIUM_MAX_PHOTOS = 10


def _setting_int(key: str, default: int) -> int:
    try:
        from app.services import settings_service
        raw = settings_service.get(key, "")
        return int(raw) if raw else default
    except Exception:
        return default


def free_days() -> int:
    return _setting_int("market_free_days", DEFAULT_FREE_DAYS)


def premium_days() -> int:
    return _setting_int("market_premium_days", DEFAULT_PREMIUM_DAYS)


def free_limit() -> int:
    return _setting_int("market_free_limit", DEFAULT_FREE_LIMIT)


def premium_limit() -> int:
    return _setting_int("market_premium_limit", DEFAULT_PREMIUM_LIMIT)


def min_photos() -> int:
    return _setting_int("market_min_photos", DEFAULT_MIN_PHOTOS)


def max_photos(user: User | None = None) -> int:
    """Rasm chegarasi. Premiumga kengroq (reja: 6 -> 10)."""
    if user is not None and premium_service.is_active(user):
        return _setting_int("market_premium_max_photos",
                            DEFAULT_PREMIUM_MAX_PHOTOS)
    return _setting_int("market_max_photos", DEFAULT_MAX_PHOTOS)


def listing_days(user: User) -> int:
    return premium_days() if premium_service.is_active(user) else free_days()


def listing_limit(user: User) -> int:
    return premium_limit() if premium_service.is_active(user) else free_limit()


def expires_at_for(user: User, *, start: datetime | None = None) -> datetime:
    """E'lon qachon tugaydi. Uzaytirishda `start` mavjud muddat bo'ladi."""
    now = datetime.now(timezone.utc)
    base = start if (start and start > now) else now
    if base.tzinfo is None:
        base = base.replace(tzinfo=timezone.utc)
    return base + timedelta(days=listing_days(user))


def marketplace_enabled() -> bool:
    """Bo'lim adminkada yoqilganmi."""
    try:
        from app.services import settings_service
        return settings_service.feature_enabled("marketplace")
    except Exception:
        return True


def marketplace_requires_premium() -> bool:
    try:
        from app.services import settings_service
        return settings_service.feature_premium("marketplace")
    except Exception:
        return False


def disabled_message() -> str:
    try:
        from app.services import settings_service
        return settings_service.feature_message("marketplace")
    except Exception:
        return "Bu bo'lim vaqtincha ishlamayapti"


async def active_listing_count(db: AsyncSession, user_id: int) -> int:
    """Hozir FAOL turgan e'lonlar soni.

    Sotilgan/muddati tugaganlari sanalmaydi: aks holda faol sotuvchi
    bir marta chegaraga urilib, boshqa e'lon bera olmasdi.
    """
    result = await db.execute(
        select(func.count(Listing.id)).where(
            Listing.user_id == user_id,
            Listing.status == ListingStatus.active,
        )
    )
    return int(result.scalar() or 0)


async def check_can_create(db: AsyncSession, user: User,
                           lang: str = "uz") -> None:
    """E'lon berish mumkinmi. Bo'lmasa TUSHUNARLI sabab bilan xato."""
    if not marketplace_enabled():
        raise HTTPException(status_code=403, detail=disabled_message())

    if marketplace_requires_premium() and not premium_service.is_active(user):
        raise HTTPException(
            status_code=403,
            detail=("Размещение объявлений доступно с Premium."
                    if lang == "ru"
                    else "E'lon berish Premium obuna bilan ishlaydi."),
        )

    limit = listing_limit(user)
    current = await active_listing_count(db, user.id)
    if current >= limit:
        if lang == "ru":
            detail = (f"У вас уже {current} активных объявлений "
                      f"(лимит {limit}). Закройте старое или оформите Premium.")
        else:
            detail = (f"Sizda {current} ta faol e'lon bor (chegara {limit}). "
                      "Eskisini yoping yoki Premium oling.")
        raise HTTPException(status_code=403, detail=detail)
