"""Dezinfeksiya — uy, ofis, mashina, maktab."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_AREA_TYPES = ["apartment", "office", "vehicle", "school"]
DEFAULT_SERVICES = [
    "Kvartira dezinfeksiyasi",
    "Ofis dezinfeksiyasi",
    "Mashina dezinfeksiyasi",
    "Maktab dezinfeksiyasi",
]
DEFAULT_PRICES = {
    "Kvartira dezinfeksiyasi": 150000,
    "Ofis dezinfeksiyasi": 250000,
    "Mashina dezinfeksiyasi": 100000,
    "Maktab dezinfeksiyasi": 300000,
}
DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00",
]
DEFAULT_CHEMICALS = [
    {"name": "Viritsid", "eco": False},
    {"name": "Eko-dezinfektant", "eco": True},
    {"name": "Chlorheksidin", "eco": False},
]


class DisinfectionService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "dezinfeksiya"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Dezinfeksiya kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        address: str | None = None,
        area_types: list[str] | None = None,
        is_certified: bool = False,
    ) -> Provider:
        cat_id = await DisinfectionService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Dezinfeksiya xizmati sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        areas = area_types or list(DEFAULT_AREA_TYPES)
        services = list(DEFAULT_SERVICES)
        prices = dict(DEFAULT_PRICES)

        meta = {
            "type": "disinfection",
            "verification_status": "pending",
            "service_area": service_area,
            "area_types": areas,
            "services": services,
            "prices": prices,
            "time_slots": list(DEFAULT_TIME_SLOTS),
            "chemicals": list(DEFAULT_CHEMICALS),
            "is_certified": is_certified,
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address or service_area,
            phone=phone or user.phone,
            lat=41.2995,
            lng=69.2401,
            metadata_json=meta,
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider
