"""Admin: sovrinli sezonli reyting (aksiya) boshqaruvi.

Bu `promos` (chegirma bannerlari) dan FARQLI narsa: bu yerda vaqt bilan
chegaralangan OVOZ BERISH musobaqasi. Foydalanuvchilar sevimli
provayderiga ovoz beradi, eng ko'p ovoz olgani sovrin oladi.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.admin.dependencies import require_admin
from app.db.session import get_db
from app.models.user import User
from app.schemas.campaign import (
    CampaignCreate,
    CampaignOut,
    CampaignUpdate,
    LeaderboardItem,
)
from app.services.campaign_service import CampaignService

router = APIRouter()


@router.get("/campaigns", response_model=list[CampaignOut])
async def admin_list_campaigns(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Barcha aksiyalar (tugaganlari ham) + har birida nechta ovoz borligi."""
    items = await CampaignService.list_campaigns(db, only_active=False)
    out = []
    for c in items:
        d = c.to_dict()
        d["vote_count"] = await CampaignService.vote_count(db, c.id)
        out.append(CampaignOut(**d))
    return out


@router.post("/campaigns", response_model=CampaignOut, status_code=201)
async def admin_create_campaign(
    data: CampaignCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    c = await CampaignService.create(db, data.model_dump())
    return CampaignOut(**c.to_dict())


@router.patch("/campaigns/{campaign_id}", response_model=CampaignOut)
async def admin_update_campaign(
    campaign_id: int,
    data: CampaignUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    c = await CampaignService.update(
        db, campaign_id, data.model_dump(exclude_unset=True)
    )
    return CampaignOut(**c.to_dict())


@router.delete("/campaigns/{campaign_id}", status_code=204)
async def admin_delete_campaign(
    campaign_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Aksiyani o'chirish. Ovozlari ham o'chadi (cascade)."""
    await CampaignService.delete(db, campaign_id)


@router.get(
    "/campaigns/{campaign_id}/leaderboard", response_model=list[LeaderboardItem]
)
async def admin_campaign_leaderboard(
    campaign_id: int,
    limit: int = Query(200, ge=1, le=500),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """G'olibni aniqlash uchun to'liq reyting."""
    return await CampaignService.leaderboard(db, campaign_id, limit)
