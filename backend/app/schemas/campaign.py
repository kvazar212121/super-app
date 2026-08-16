from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class CampaignOut(BaseModel):
    """Aksiya (sezonli reyting musobaqasi)."""

    id: int
    title: str
    description: Optional[str] = None
    category_id: Optional[int] = None
    starts_at: datetime
    ends_at: datetime
    prize: Optional[str] = None
    is_active: bool
    # upcoming | running | finished | disabled — modeldan hisoblanadi
    status: Optional[str] = None
    # Faqat admin ro'yxatida to'ldiriladi
    vote_count: Optional[int] = None

    model_config = {"from_attributes": True}


class CampaignCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: Optional[str] = None
    # NULL = barcha kategoriyalar qatnashadi
    category_id: Optional[int] = None
    starts_at: datetime
    ends_at: datetime
    prize: Optional[str] = None
    is_active: bool = True


class CampaignUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=200)
    description: Optional[str] = None
    category_id: Optional[int] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    prize: Optional[str] = None
    is_active: Optional[bool] = None


class VoteCreate(BaseModel):
    provider_id: int


class VoteOut(BaseModel):
    id: int
    campaign_id: int
    user_id: int
    provider_id: int
    created_at: datetime

    model_config = {"from_attributes": True}


class LeaderboardItem(BaseModel):
    """Reyting qatori: provayder + shu aksiyadagi OVOZ soni."""

    id: int
    name: str
    address: str
    phone: str
    category_id: int
    lat: float
    lng: float
    cover_image: Optional[str] = None
    # Doimiy o'rtacha reyting (ma'lumot uchun, tartibga TA'SIR QILMAYDI)
    rating: float
    review_count: int
    # Aksiya natijasi
    votes: int
    position: int


class MyVoteOut(BaseModel):
    """Foydalanuvchi shu aksiyada ovoz berganmi (UI tugma holati uchun)."""

    has_voted: bool
    provider_id: Optional[int] = None
