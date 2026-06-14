from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.models.promo import Promo
from app.schemas.promo import PromoOut

router = APIRouter(prefix="/promos", tags=["promos"])

@router.get("", response_model=list[PromoOut])
async def list_active_promos(db: AsyncSession = Depends(get_db)):
    """Aktiv aksiya va bannerlar ro'yxatini olish (bosh sahifa uchun)."""
    result = await db.execute(
        select(Promo).where(Promo.is_active == True).order_by(Promo.created_at.desc())
    )
    return result.scalars().all()
