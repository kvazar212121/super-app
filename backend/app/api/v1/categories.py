from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.models.category import Category, CategoryVariant
from app.schemas.category import CategoryOut, CategoryCreate, VariantOut, VariantCreate

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Category))
    return result.scalars().all()


@router.get("/{category_id}", response_model=CategoryOut)
async def get_category(category_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Category).where(Category.id == category_id)
    )
    cat = result.scalar_one_or_none()
    if not cat:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    return cat


@router.get("/{category_id}/variants", response_model=list[VariantOut])
async def list_variants(category_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CategoryVariant).where(CategoryVariant.category_id == category_id)
    )
    return result.scalars().all()