from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.cache import cached_json
from app.db.session import get_db
from app.models.category import Category, CategoryVariant
from app.schemas.category import CategoryOut, CategoryCreate, VariantOut, VariantCreate
from app.services import settings_service

router = APIRouter(prefix="/categories", tags=["categories"])

# Kesh kalitlari. Ma'lumot shakli o'zgarsa versiyani oshiring (v1 -> v2).
CACHE_KEY_ALL = "categories:v1"
CACHE_TTL = 60


async def load_categories(db: AsyncSession) -> list[dict]:
    """Kategoriyalarni keshdan (yoki bazadan) o'qiydi — FAQAT baza qatorlari.

    Diqqat: admin flaglari (`is_enabled`, `coming_soon_message`) BU YERDA
    qo'shilmaydi. Ular `settings_service` dan har so'rovda yangi olinadi,
    shunda admin bo'limni yopganda o'zgarish 60 soniya kutmasdan
    darhol kuchga kiradi. Keshda faqat kamdan-kam o'zgaradigan
    kategoriya qatorlari yotadi.
    """

    async def _from_db() -> list[dict]:
        result = await db.execute(select(Category))
        return [c.to_dict() for c in result.scalars().all()]

    return await cached_json(CACHE_KEY_ALL, CACHE_TTL, _from_db)


def _with_flags(d: dict) -> dict:
    """Keshlangan kategoriyaga joriy admin flaglarini qo'shadi."""
    key = d.get("key")
    return {
        **d,
        "is_enabled": settings_service.category_enabled(key),
        "coming_soon_message": settings_service.category_message(key),
    }


def _category_out(cat: Category) -> dict:
    """Kategoriya + admin flaglari (ochiq/yopiq + 'tez orada' xabari)."""
    return _with_flags(cat.to_dict())


@router.get("", response_model=list[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    return [_with_flags(d) for d in await load_categories(db)]



@router.get("/{category_id}", response_model=CategoryOut)
async def get_category(category_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Category).where(Category.id == category_id)
    )
    cat = result.scalar_one_or_none()
    if not cat:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    return _category_out(cat)


@router.get("/{category_id}/variants", response_model=list[VariantOut])
async def list_variants(category_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CategoryVariant).where(CategoryVariant.category_id == category_id)
    )
    return result.scalars().all()