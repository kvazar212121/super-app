"""E'lon chegaralari: oddiy foydalanuvchi va premium uchun.

Foydalanuvchi qaroriga ko'ra:
    - Bir vaqtda ochiq e'lon: 3 ta (premium: 20 ta)
    - E'lon muddati: 5 kun (premium: cheksiz)
    - Taklif soni: CHEKLANMAYDI

Barcha raqamlar admin panelidan sozlanadi (settings_service), chunki
foydalanuvchi "adminkada shu e'lon bo'yicha premium yoqish/o'chirish
ham bo'lishi kerak" dedi.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.job import JobPost, JobStatus
from app.models.user import User
from app.services import premium_service

# Standart qiymatlar. Admin panelida o'zgartirilishi mumkin.
DEFAULT_FREE_LIMIT = 3
DEFAULT_PREMIUM_LIMIT = 20
DEFAULT_FREE_DAYS = 5


def _setting_int(key: str, default: int) -> int:
    """Admin sozlamasidan butun son. Xato bo'lsa standart qiymat.

    settings_service DB'ga murojaat qiladi va u ishlamay qolsa
    e'lon berish BUTUNLAY to'xtab qolmasligi kerak.
    """
    try:
        from app.services import settings_service
        raw = settings_service.get(key, "")
        return int(raw) if raw else default
    except Exception:
        return default


def free_job_limit() -> int:
    return _setting_int("jobs_free_limit", DEFAULT_FREE_LIMIT)


def premium_job_limit() -> int:
    return _setting_int("jobs_premium_limit", DEFAULT_PREMIUM_LIMIT)


def free_expiry_days() -> int:
    return _setting_int("jobs_free_days", DEFAULT_FREE_DAYS)


def jobs_require_premium() -> bool:
    """Butun e'lon bo'limi premium talab qiladimi (adminkadan yoqiladi)."""
    try:
        from app.services import settings_service
        return settings_service.get_bool("feature_jobs_premium", False)
    except Exception:
        return False


def job_limit_for(user: User) -> int:
    """Shu foydalanuvchi bir vaqtda nechta ochiq e'lon bera oladi."""
    if premium_service.is_active(user):
        return premium_job_limit()
    return free_job_limit()


def job_expiry_days(user: User) -> int | None:
    """E'lon necha kundan keyin avtomatik yopiladi. None = cheksiz.

    Foydalanuvchi: "elon bitim imzolanmaguncha yoki egasi olib
    tashlamaguncha, uzog'i 5 kun ichida. Premium obunachilarga
    cheksiz bo'lishi mumkin."
    """
    if premium_service.is_active(user):
        return None
    return free_expiry_days()


def expires_at_for(user: User) -> datetime | None:
    """E'lon tugash vaqti (premium uchun None)."""
    days = job_expiry_days(user)
    if days is None:
        return None
    return datetime.now(timezone.utc) + timedelta(days=days)


async def open_job_count(db: AsyncSession, user_id: int) -> int:
    """Foydalanuvchining hozir OCHIQ turgan e'lonlari soni.

    Yopilgan/bekor qilingan/bajarilgan e'lonlar sanalmaydi — aks
    holda faol foydalanuvchi bir marta chegaraga urilib, boshqa
    hech qachon e'lon bera olmasdi.
    """
    result = await db.execute(
        select(func.count(JobPost.id)).where(
            JobPost.user_id == user_id,
            JobPost.status == JobStatus.open,
        )
    )
    return int(result.scalar() or 0)


async def check_can_create_job(
    db: AsyncSession, user: User, lang: str = "uz"
) -> None:
    """E'lon berish mumkinmi. Mumkin bo'lmasa TUSHUNARLI xato beradi.

    Shunchaki 400 emas: foydalanuvchi nima qilishni bilishi kerak
    (eskisini yopish yoki premium olish).
    """
    # 1) Butun bo'lim premium talab qilishi mumkin (adminkadan)
    if jobs_require_premium() and not premium_service.is_active(user):
        raise HTTPException(
            status_code=403,
            detail=(
                "E'lon berish Premium obuna bilan ishlaydi."
                if lang != "ru"
                else "Публикация заявок доступна с подпиской Premium."
            ),
        )

    # 2) Ochiq e'lonlar soni chegarasi
    limit = job_limit_for(user)
    current = await open_job_count(db, user.id)
    if current >= limit:
        if lang == "ru":
            detail = (
                f"У вас уже {current} открытых заявок (лимит {limit}). "
                "Закройте старую или оформите Premium."
            )
        else:
            detail = (
                f"Sizda {current} ta ochiq e'lon bor (chegara {limit}). "
                "Eskisini yoping yoki Premium oling."
            )
        raise HTTPException(status_code=403, detail=detail)
