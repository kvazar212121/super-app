"""Hamshira — uyga chiqish (chaqirish)."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_MEDICAL_TYPES = [
    "injection",
    "blood_test",
    "drip",
    "wound_care",
    "elderly_care",
]
DEFAULT_SERVICES = [
    "Ukol (in'ektsiya)",
    "Qon tahlili (uyda)",
    "Tomchilatma (kapelsnitsa)",
    "Yara parvarishi",
    "Keksaga parvarish (3 soat)",
    "Tun bo'yi hamshira (12 soat)",
]
DEFAULT_PRICES = {
    "Ukol (in'ektsiya)": 35000,
    "Qon tahlili (uyda)": 120000,
    "Tomchilatma (kapelsnitsa)": 150000,
    "Yara parvarishi": 80000,
    "Keksaga parvarish (3 soat)": 180000,
    "Tun bo'yi hamshira (12 soat)": 350000,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "20:00",
]


class NurseService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "hamshira"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Hamshira kategoriyasi topilmadi")
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
        medical_types: list[str] | None = None,
        qualifications: str | None = None,
    ) -> Provider:
        cat_id = await NurseService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Hamshira sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        med_types = medical_types or list(DEFAULT_MEDICAL_TYPES)
        meta = {
            "type": "nurse",
            "verification_status": "pending",
            "visit_modes": ["home_visit"],
            "medical_types": med_types,
            "services": list(DEFAULT_SERVICES),
            "prices": dict(DEFAULT_PRICES),
            "service_area": service_area,
            "qualifications": qualifications or "Litsenziyalangan hamshira",
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
