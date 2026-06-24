"""Massaj va hijoma — uyga chiqish va salonda."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_VISIT_MODES = ["at_center"]
DEFAULT_SERVICE_TYPES = ["classic_massage", "hijoma", "sport_massage"]
DEFAULT_SERVICES = [
    "Klassik massaj (60 min)",
    "Hijoma",
    "Sport massaj (60 min)",
]
DEFAULT_PRICES = {
    "Klassik massaj (60 min)": 150000,
    "Hijoma": 120000,
    "Sport massaj (60 min)": 180000,
}
DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00",
]


class MassageService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "massajHijoma"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Massaj kategoriyasi topilmadi")
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
        massage_role: str = "solo",
        visit_modes: list[str] | None = None,
        service_types: list[str] | None = None,
        gender: str = "both",
        concurrent_capacity: int = 1,
    ) -> Provider:
        cat_id = await MassageService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Massaj xizmati sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        role = massage_role if massage_role in ("solo", "salon") else "solo"
        modes = visit_modes or (
            ["at_center"] if role == "salon" else list(DEFAULT_VISIT_MODES)
        )
        if not modes:
            modes = list(DEFAULT_VISIT_MODES)

        stypes = service_types or list(DEFAULT_SERVICE_TYPES)
        services = list(DEFAULT_SERVICES)
        prices = dict(DEFAULT_PRICES)

        meta = {
            "type": "massage",
            "massage_role": role,
            "verification_status": "pending",
            "visit_modes": modes,
            "service_types": stypes,
            "services": services,
            "prices": prices,
            "gender": gender if gender in ("male", "female", "both") else "both",
            "service_area": service_area,
            "concurrent_capacity": concurrent_capacity,
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
