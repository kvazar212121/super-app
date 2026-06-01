"""Enaga — bola qarovchi, admin tasdiqlash bilan."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SERVICE_TYPES = ["hourly", "half_day", "full_day", "overnight", "weekly", "monthly"]
DEFAULT_SERVICES = [
    "Soatbay (3 soat)",
    "Yarim kun (4-6 soat)",
    "Butun kun",
    "Tungi qarash",
    "Haftalik doimiy",
    "Oylik doimiy",
]
DEFAULT_PRICES = {
    "Soatbay (3 soat)": 80000,
    "Yarim kun (4-6 soat)": 150000,
    "Butun kun": 280000,
    "Tungi qarash": 350000,
    "Haftalik doimiy": 1200000,
    "Oylik doimiy": 4500000,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00",
]
DEFAULT_AGE_GROUPS = ["0-1", "1-3", "3-7", "7-12"]


class NannyService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "enaga"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Enaga kategoriyasi topilmadi")
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
        experience_years: int = 0,
        age_groups: list[str] | None = None,
        languages: list[str] | None = None,
        service_types: list[str] | None = None,
        documents: dict | None = None,
    ) -> Provider:
        cat_id = await NannyService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Enaga sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        doc_meta = {
            "medical_cert": False,
            "criminal_record": False,
            "id_verified": False,
            "medical_cert_url": None,
            "id_url": None,
            "criminal_record_url": None,
        }
        if documents:
            doc_meta.update(documents)

        meta = {
            "type": "nanny",
            "nanny_role": "pending",
            "verification_status": "pending",
            "specialty": "Enaga",
            "service_area": service_area,
            "experience_years": max(0, experience_years),
            "age_groups": age_groups or list(DEFAULT_AGE_GROUPS[:3]),
            "languages": languages or ["uz"],
            "service_types": service_types or list(DEFAULT_SERVICE_TYPES[:4]),
            "documents": doc_meta,
            "services": list(DEFAULT_SERVICES),
            "prices": dict(DEFAULT_PRICES),
            "time_slots": list(DEFAULT_TIME_SLOTS),
            "repeat_families": 0,
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
