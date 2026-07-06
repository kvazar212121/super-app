"""Ilova uchun ochiq konfiguratsiya — bo'lim (feature) flaglari.

Mobil ilova bu endpointни o'qib, qaysi bo'limlar yopiqligini biladi va yopiq bo'lsa
foydalanuvchiga "tez orada ishga tushadi" xabarini ko'rsatadi.
"""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.category import Category
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


@router.get("/categories")
async def get_category_flags_public(db: AsyncSession = Depends(get_db)):
    """{cat_key: {enabled, message}} — 26 xizmat holati (auth talab qilinmaydi)."""
    cats = (await db.execute(select(Category))).scalars().all()
    return {
        "categories": {
            c.key: {
                "enabled": settings_service.category_enabled(c.key),
                "message": settings_service.category_message(c.key),
            }
            for c in cats
        }
    }
