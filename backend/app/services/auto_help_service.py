"""Mobil avto-yordam — evakuator, joyida ta'mirlash, benzin yetkazish."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SERVICES = [
    "Evakuator",
    "Joyida ta'mirlash",
    "Benzin yetkazish (AI-92, 10L)",
    "Benzin yetkazish (AI-95, 10L)",
    "Akkumulyator quvvatlash",
    "Shinopompa (1 gildirak)",
]
DEFAULT_PRICES = {
    "Evakuator": 250000,
    "Joyida ta'mirlash": 150000,
    "Benzin yetkazish (AI-92, 10L)": 120000,
    "Benzin yetkazish (AI-95, 10L)": 130000,
    "Akkumulyator quvvatlash": 80000,
    "Shinopompa (1 gildirak)": 70000,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00",
]

DEFAULT_WORKSHOP_SERVICES = [
    "Diagnostika",
    "Xodovoy remont",
    "Dvigatel ta'miri",
    "Elektronika ta'miri",
    "Shinopompa / balans",
]
DEFAULT_WORKSHOP_SPECIALIZATIONS = ["Motor", "Xodovoy", "Elektronika"]
DEFAULT_WORKSHOP_PRICES = {
    "Diagnostika": 80000,
    "Xodovoy remont": 200000,
    "Dvigatel ta'miri": 350000,
    "Elektronika ta'miri": 150000,
    "Shinopompa / balans": 120000,
}
WORKSHOP_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00",
]


class AutoHelpService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "avtoYordam"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Avto-yordam kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register_mobile(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        vehicle_type: str = "combo",
        address: str | None = None,
    ) -> Provider:
        cat_id = await AutoHelpService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Avto-yordam sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        meta = {
            "type": "auto_mobile",
            "auto_role": "mobile",
            "vehicle_type": vehicle_type,
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
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider

    @staticmethod
    async def register_workshop(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        address: str,
        specializations: list[str] | None = None,
    ) -> Provider:
        cat_id = await AutoHelpService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Avto-yordam sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        specs = specializations or list(DEFAULT_WORKSHOP_SPECIALIZATIONS)
        meta = {
            "type": "auto_workshop",
            "auto_role": "workshop",
            "specializations": specs,
            "services": list(DEFAULT_WORKSHOP_SERVICES),
            "prices": dict(DEFAULT_WORKSHOP_PRICES),
            "time_slots": list(WORKSHOP_TIME_SLOTS),
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address,
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
