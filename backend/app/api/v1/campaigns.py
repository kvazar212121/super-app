"""Sezonli reyting (aksiya) — ommaviy endpointlar.

Mobil ilova shu yerdan aksiyani, reytingni oladi va ovoz beradi.
Admin CRUD esa /api/v1/admin/campaigns da.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.campaign import (
    CampaignOut,
    LeaderboardItem,
    MyVoteOut,
    VoteCreate,
    VoteOut,
)
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["campaigns"])


def _out(campaign) -> CampaignOut:
    """Model -> sxema (status hisoblanadigan maydon)."""
    return CampaignOut(**campaign.to_dict())


@router.get("", response_model=list[CampaignOut])
async def list_campaigns(
    only_active: bool = Query(True, description="Faqat hozir ketayotganlari"),
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    items = await CampaignService.list_campaigns(db, only_active, category_id)
    return [_out(c) for c in items]


@router.get("/active", response_model=CampaignOut | None)
async def get_active_campaign(db: AsyncSession = Depends(get_db)):
    """Bosh sahifa uchun: hozir ketayotgan aksiya (yo'q bo'lsa null)."""
    c = await CampaignService.get_active(db)
    return _out(c) if c else None


@router.get("/{campaign_id}", response_model=CampaignOut)
async def get_campaign(campaign_id: int, db: AsyncSession = Depends(get_db)):
    return _out(await CampaignService.get_by_id(db, campaign_id))


@router.get("/{campaign_id}/leaderboard", response_model=list[LeaderboardItem])
async def get_leaderboard(
    campaign_id: int,
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    """Aksiya reytingi: eng ko'p OVOZ olganlar (yulduz emas)."""
    return await CampaignService.leaderboard(db, campaign_id, limit)


@router.get("/{campaign_id}/my-vote", response_model=MyVoteOut)
async def get_my_vote(
    campaign_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """UI tugmani o'chirishi uchun: men ovoz berganmi?"""
    await CampaignService.get_by_id(db, campaign_id)
    vote = await CampaignService.my_vote(db, campaign_id, current_user.id)
    return MyVoteOut(
        has_voted=vote is not None,
        provider_id=vote.provider_id if vote else None,
    )


@router.post("/{campaign_id}/vote", response_model=VoteOut, status_code=201)
async def vote(
    campaign_id: int,
    data: VoteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Ovoz berish. Bir foydalanuvchi bitta aksiyada FAQAT BIR MARTA."""
    return await CampaignService.vote(
        db, campaign_id, current_user.id, data.provider_id
    )
