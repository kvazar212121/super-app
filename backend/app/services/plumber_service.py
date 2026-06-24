"""Santexnik — yakka usta, mijoz manziliga chaqiruv."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SERVICES = [
    "Smesitel almashtirish",
    "Toshma/probka tozalash",
    "Quvur ulash",
    "Shoshilinch chaqiruv",
]
DEFAULT_PRICES = {
    "Smesitel almashtirish": 120000,
    "Toshma/probka tozalash": 150000,
    "Quvur ulash": 200000,
    "Shoshilinch chaqiruv": 250000,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00",
]


class PlumberService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "santexnik"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Santexnik kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register_solo(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        address: str | None = None,
    ) -> Provider:
        cat_id = await PlumberService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Santexnik sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        meta = {
            "type": "master",
            "plumber_role": "solo",
            "specialty": "Santexnik",
            "service_area": service_area,
            "services": list(DEFAULT_SERVICES),
            "prices": dict(DEFAULT_PRICES),
            "time_slots": list(DEFAULT_TIME_SLOTS),
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address or service_area,
            phone=phone or user.phone,
            lat=41.2995,
            lng=69.2401,
            metadata_json=meta,
            is_active=True,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider
