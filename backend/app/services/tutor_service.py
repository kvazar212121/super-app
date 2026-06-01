"""Repetitor — yakka o'qituvchi (onlayn/uyga) va o'quv markazi."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User

DEFAULT_SUBJECTS = [
    "Matematika",
    "Ingliz tili",
    "Fizika",
    "Rus tili",
    "Kimyo",
    "Test tayyorlov",
]
DEFAULT_LESSON_MODES = ["online", "home_visit"]
DEFAULT_TUTOR_PRICES = {
    "Matematika (1 soat)": 120000,
    "Ingliz tili (1 soat)": 100000,
    "Fizika (1 soat)": 130000,
    "Rus tili (1 soat)": 90000,
    "Kimyo (1 soat)": 110000,
    "Test tayyorlov (1 soat)": 150000,
}
DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00", "14:00",
    "15:00", "16:00", "17:00", "18:00", "19:00", "20:00",
]
DEFAULT_CENTER_COURSES = [
    "Matematika",
    "Ingliz tili",
    "Programmalash",
    "Grafik dizayn",
]
DEFAULT_CENTER_PRICES = {
    "Matematika (guruh)": 200000,
    "Ingliz tili (guruh)": 180000,
    "Individual dars": 150000,
    "Test tayyorlov": 220000,
}


class TutorService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "repetitor"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Repetitor kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def register_solo(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        address: str | None = None,
        subjects: list[str] | None = None,
        lesson_modes: list[str] | None = None,
        experience_years: int = 0,
    ) -> Provider:
        cat_id = await TutorService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Repetitor sifatida allaqachon ro'yxatdan o'tgansiz",
            )

        subs = subjects or list(DEFAULT_SUBJECTS[:4])
        modes = lesson_modes or list(DEFAULT_LESSON_MODES)
        services = [f"{s} (1 soat)" for s in subs]
        prices = {svc: DEFAULT_TUTOR_PRICES.get(svc, 100000) for svc in services}

        meta = {
            "type": "tutor",
            "tutor_role": "solo",
            "verification_status": "pending",
            "specialty": "Repetitor",
            "service_area": service_area,
            "subjects": subs,
            "lesson_modes": modes,
            "experience_years": max(0, experience_years),
            "services": services,
            "prices": prices,
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
    async def register_center(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        address: str,
        courses: list[str] | None = None,
    ) -> Provider:
        cat_id = await TutorService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400,
                detail="Repetitor kategoriyasi bo'yicha allaqachon ro'yxatdan o'tgansiz",
            )

        course_list = courses or list(DEFAULT_CENTER_COURSES)
        services = list(DEFAULT_CENTER_PRICES.keys())
        meta = {
            "type": "education_center",
            "tutor_role": "center",
            "verification_status": "pending",
            "courses": course_list,
            "lesson_modes": ["at_center"],
            "services": services,
            "prices": dict(DEFAULT_CENTER_PRICES),
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
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider
