"""Tadbir tashkil etuvchi guruhlar — sahna, ovoz, qishloq va shahar tadbirlari."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_ORGANIZER_TYPES = [
    "stage_setup",
    "sound_light",
    "decor",
    "full_organization",
    "village_events",
]
DEFAULT_EVENT_TYPES = [
    "wedding",
    "birthday",
    "corporate",
    "memorial",
    "engagement",
]
DEFAULT_VENUE_TYPES = [
    "village_yard",
    "open_field",
    "restaurant",
    "garden",
    "hall",
]
DEFAULT_SERVICES = [
    "Sahna va podiyom o'rnatish (qishloq / maydon)",
    "Ovoz va yoritish (kolonka, lyuka)",
    "Dekoratsiya va bezak",
    "To'y — to'liq tashkilot",
    "Tug'ilgan kun dasturi",
    "Korporativ tadbir",
    "Qishloq hovlisida marosim",
]
DEFAULT_PRICES = {
    "Sahna va podiyom o'rnatish (qishloq / maydon)": 2500000,
    "Ovoz va yoritish (kolonka, lyuka)": 1200000,
    "Dekoratsiya va bezak": 800000,
    "To'y — to'liq tashkilot": 15000000,
    "Tug'ilgan kun dasturi": 3500000,
    "Korporativ tadbir": 5000000,
    "Qishloq hovlisida marosim": 4000000,
}
DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00",
]


class EventOrganizerService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "tadbirlar"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Tadbirlar kategoriyasi topilmadi")
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
        team_size: int = 3,
        organizer_types: list[str] | None = None,
        event_types: list[str] | None = None,
        venue_types: list[str] | None = None,
    ) -> Provider:
        cat_id = await EventOrganizerService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Tadbir guruh sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        otypes = organizer_types or list(DEFAULT_ORGANIZER_TYPES)
        etypes = event_types or list(DEFAULT_EVENT_TYPES)
        vtypes = venue_types or list(DEFAULT_VENUE_TYPES)
        team = max(1, min(team_size, 50))

        meta = {
            "type": "event_organizer",
            "verification_status": "approved",
            "organizer_types": otypes,
            "event_types": etypes,
            "venue_types": vtypes,
            "services": list(DEFAULT_SERVICES),
            "prices": dict(DEFAULT_PRICES),
            "service_area": service_area,
            "team_size": team,
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
