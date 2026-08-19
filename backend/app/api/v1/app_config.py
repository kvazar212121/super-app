"""Ilova uchun ochiq konfiguratsiya — bo'lim (feature) flaglari.

Mobil ilova bu endpointни o'qib, qaysi bo'limlar yopiqligini biladi va yopiq bo'lsa
foydalanuvchiga "tez orada ishga tushadi" xabarini ko'rsatadi.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.services import settings_service

router = APIRouter(prefix="/config", tags=["config"])


@router.get("/features")
async def get_features():
    """{key: {enabled, message}} — barcha bo'limlar holati (auth talab qilinmaydi)."""
    return {"features": settings_service.features_public()}


@router.get("/legal")
async def get_legal():
    """Huquqiy hujjatlar matni (shartlar/maxfiylik/faq) — ilova va veb uchun."""
    return {"legal": settings_service.all_legal()}


@router.get("/support")
async def get_support():
    """Qo'llab-quvvatlash aloqa kanallari (telefon/email/telegram + AI) — auth talab qilinmaydi."""
    return {"support": settings_service.support_config()}


@router.get("/categories")
async def get_category_flags_public(db: AsyncSession = Depends(get_db)):
    """{cat_key: {enabled, message}} — 26 xizmat holati (auth talab qilinmaydi).

    Kategoriya ro'yxati keshdan olinadi (`categories.load_categories`),
    holat esa har so'rovda yangi o'qiladi — admin o'zgarishi darhol ko'rinadi.
    """
    from app.api.v1.categories import load_categories

    cats = await load_categories(db)
    return {
        "categories": {
            c["key"]: {
                "enabled": settings_service.category_enabled(c["key"]),
                "message": settings_service.category_message(c["key"]),
            }
            for c in cats
        }
    }
