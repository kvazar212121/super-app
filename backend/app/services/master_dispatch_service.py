"""Usta chaqirish — yakka usta yoki ustalar brigadasi."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SERVICES = [
    "Mebel yigish",
    "Eshik/oyna tamiri",
    "Devorga osish/biriktirish",
    "Boshqa ta'mirlash",
]
DEFAULT_PRICES = {
    "Mebel yigish": 150000,
    "Eshik/oyna tamiri": 120000,
    "Devorga osish/biriktirish": 80000,
    "Boshqa ta'mirlash": 100000,
}
DEFAULT_TIME_SLOTS = [
    "08:00", "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00",
]


class MasterDispatchService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "usta"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Usta kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def _ensure_not_registered(db: AsyncSession, user_id: int, cat_id: int) -> None:
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user_id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Usta sifatida allaqachon ro'yxatdan o'tgansiz",
            )

    @staticmethod
    def _base_meta(*, role: str, service_area: str, team_size: int | None = None) -> dict:
        meta = {
            "type": "master",
            "master_role": role,
            "specialty": "Usta",
            "service_area": service_area,
            "services": list(DEFAULT_SERVICES),
            "prices": dict(DEFAULT_PRICES),
            "time_slots": list(DEFAULT_TIME_SLOTS),
        }
        if role == "brigade" and team_size:
            meta["team_size"] = team_size
        return meta

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
        cat_id = await MasterDispatchService._category_id(db)
        await MasterDispatchService._ensure_not_registered(db, user.id, cat_id)

        meta = MasterDispatchService._base_meta(role="solo", service_area=service_area)

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
    async def register_brigade(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        address: str,
        service_area: str,
        team_size: int,
        lat: float = 41.2995,
        lng: float = 69.2401,
    ) -> Provider:
        cat_id = await MasterDispatchService._category_id(db)
        await MasterDispatchService._ensure_not_registered(db, user.id, cat_id)

        if team_size < 2:
            raise HTTPException(status_code=400, detail="Brigada kamida 2 kishidan iborat bo'lishi kerak")

        meta = MasterDispatchService._base_meta(
            role="brigade",
            service_area=service_area,
            team_size=team_size,
        )

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address,
            phone=phone or user.phone,
            lat=lat,
            lng=lng,
            metadata_json=meta,
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider
