"""Bozorchi — oziq-ovqat va bozorlik yetkazib beruvchi."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

class BozorchiService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "bozorchi"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Bozorchi kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        vehicle_type: str = "car",
    ) -> Provider:
        cat_id = await BozorchiService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Bozorchi sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        meta = {
            "type": "bozorchi",
            "vehicle_type": vehicle_type,
            "service_area": service_area,
            "verification_status": "pending",
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=service_area,
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
