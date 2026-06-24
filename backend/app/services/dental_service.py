"""Stomatologiya — klinikada qabul va vaqt bron."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SERVICES = [
    "Ko'rik va maslahat",
    "Professional tozalash",
    "Plomba",
    "Oqartirish (1 seans)",
    "Tish olib tashlash",
]
DEFAULT_PRICES = {
    "Ko'rik va maslahat": 80000,
    "Professional tozalash": 150000,
    "Plomba": 200000,
    "Oqartirish (1 seans)": 350000,
    "Tish olib tashlash": 120000,
}
DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00",
]
DEFAULT_DENTISTS = [
    {"name": "Dr. Karim", "specialty": "Terapevt"},
    {"name": "Dr. Nilufar", "specialty": "Ortodont"},
]


class DentalService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "stomatologiya"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Stomatologiya kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register_clinic(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        address: str,
        services: list[str] | None = None,
    ) -> Provider:
        cat_id = await DentalService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Stomatologiya kategoriyasi bo'yicha allaqachon ro'yxatdan o'tgansiz",
            )

        svc_list = services or list(DEFAULT_SERVICES)
        prices = {s: DEFAULT_PRICES.get(s, 100000) for s in svc_list}

        meta = {
            "type": "dental_clinic",
            "verification_status": "approved",
            "visit_modes": ["at_center"],
            "services": svc_list,
            "prices": prices,
            "dentists": list(DEFAULT_DENTISTS),
            "time_slots": list(DEFAULT_TIME_SLOTS),
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address,
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
