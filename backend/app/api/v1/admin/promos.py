from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.models.user import User
from app.models.promo import Promo
from app.schemas.promo import PromoCreate, PromoOut
from app.schemas.common import UrlResponse
from app.services.upload_service import UploadService
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


@router.post("/promos/upload", response_model=UrlResponse)
async def admin_upload_promo_image(
    file: UploadFile = File(...),
    _admin: User = Depends(require_admin),
):
    """Banner fon rasmini yuklash — URL qaytaradi."""
    url = await UploadService.upload_promo_image(file)
    return UrlResponse(url=url)


@router.get("/promos", response_model=list[PromoOut])
async def admin_list_promos(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Promo).order_by(Promo.created_at.desc()))
    return result.scalars().all()


@router.post("/promos", response_model=PromoOut, status_code=201)
async def admin_create_promo(
    data: PromoCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    promo = Promo(**data.model_dump())
    db.add(promo)
    await db.flush()
    await db.refresh(promo)
    return promo


@router.delete("/promos/{promo_id}", status_code=204)
async def admin_delete_promo(
    promo_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Promo).where(Promo.id == promo_id))
    promo = result.scalar_one_or_none()
    if not promo:
        raise HTTPException(status_code=404, detail="Aksiya topilmadi")
    await db.delete(promo)
