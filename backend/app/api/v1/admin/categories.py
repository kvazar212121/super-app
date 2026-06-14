from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category, CategoryVariant
from app.schemas.category import CategoryCreate, CategoryOut, VariantCreate, VariantOut
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).options(selectinload(Category.variants)))
    return result.scalars().all()


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def create_category(
    data: CategoryCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    cat = Category(**data.model_dump())
    db.add(cat)
    await db.flush()
    await db.refresh(cat)
    return cat


@router.patch("/categories/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    data: CategoryCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")

    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(cat, key, val)

    await db.flush()
    await db.refresh(cat)
    return cat


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    await db.delete(cat)


@router.post("/categories/{category_id}/variants", response_model=VariantOut, status_code=201)
async def create_variant(
    category_id: int,
    data: VariantCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    v = CategoryVariant(category_id=category_id, **data.model_dump())
    db.add(v)
    await db.flush()
    await db.refresh(v)
    return v


@router.patch("/categories/{category_id}/variants/{variant_id}", response_model=VariantOut)
async def update_variant(
    category_id: int,
    variant_id: int,
    data: VariantCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(CategoryVariant).where(
            and_(
                CategoryVariant.id == variant_id,
                CategoryVariant.category_id == category_id,
            )
        )
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Variant topilmadi")

    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(v, key, val)

    await db.flush()
    await db.refresh(v)
    return v


@router.delete("/categories/{category_id}/variants/{variant_id}", status_code=204)
async def delete_variant(
    category_id: int,
    variant_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(CategoryVariant).where(
            and_(
                CategoryVariant.id == variant_id,
                CategoryVariant.category_id == category_id,
            )
        )
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Variant topilmadi")
    await db.delete(v)
