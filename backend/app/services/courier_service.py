"""Kuryer — yakka kuryer, A→B yetkazish."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_DELIVERY_TYPES = ["document", "package", "food"]
DEFAULT_PRICES = {
    "Shahar ichi (5km)": 25000,
    "Shahar tashqari": 80000,
    "Express (+50%)": 12500,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00",
]


class CourierService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "kuryerlik"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Kuryerlik kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register_solo(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        vehicle_type: str = "bike",
        address: str | None = None,
    ) -> Provider:
        cat_id = await CourierService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Kuryer sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        meta = {
            "type": "courier",
            "courier_role": "solo",
            "vehicle_type": vehicle_type,
            "service_area": service_area,
            "delivery_types": list(DEFAULT_DELIVERY_TYPES),
            "prices": dict(DEFAULT_PRICES),
            "max_weight": 15,
            "is_express": True,
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
