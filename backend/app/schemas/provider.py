from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ProviderOut(BaseModel):
    id: int
    category_id: int
    category_key: Optional[str] = None
    name: str
    address: str
    phone: str
    lat: float
    lng: float
    rating: float
    review_count: int
    cover_image: Optional[str] = None
    metadata: Optional[dict] = None
    is_active: bool
    is_paused: bool
    owner_user_id: Optional[int] = None
    completed_orders_count: int = 0
    cancelled_orders_count: int = 0

    model_config = {"from_attributes": False}

    @classmethod
    def from_provider(cls, p) -> "ProviderOut":
        return cls(
            id=p.id,
            category_id=p.category_id,
            category_key=p.category.key if getattr(p, "category", None) else None,
            name=p.name,
            address=p.address,
            phone=p.phone,
            lat=p.lat,
            lng=p.lng,
            rating=p.rating,
            review_count=p.review_count,
            cover_image=p.cover_image,
            metadata=p.metadata_json,
            is_active=p.is_active,
            is_paused=p.is_paused,
            owner_user_id=p.owner_user_id,
            completed_orders_count=getattr(p, "completed_orders_count", 0),
            cancelled_orders_count=getattr(p, "cancelled_orders_count", 0),
        )


class ProviderCreate(BaseModel):
    category_id: int
    name: str = Field(..., min_length=2, max_length=300)
    address: str = Field(..., min_length=5, max_length=500)
    phone: str = Field(..., min_length=9, max_length=20)
    lat: float = 41.2995
    lng: float = 69.2401
    cover_image: Optional[str] = None
    metadata_json: Optional[dict] = None


class ProviderUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    cover_image: Optional[str] = None
    metadata_json: Optional[dict] = None
    is_active: Optional[bool] = None
    is_paused: Optional[bool] = None


class ReviewOut(BaseModel):
    id: int
    user_id: int
    provider_id: int
    rating: int
    comment: Optional[str] = None
    created_at: Optional[str] = None
    user_name: Optional[str] = None
    provider_name: Optional[str] = None

    model_config = {"from_attributes": False}

    @classmethod
    def from_review(cls, r) -> "ReviewOut":
        user = getattr(r, "user", None)
        provider = getattr(r, "provider", None)
        created = r.created_at.isoformat() if getattr(r, "created_at", None) else None
        return cls(
            id=r.id,
            user_id=r.user_id,
            provider_id=r.provider_id,
            rating=r.rating,
            comment=r.comment,
            created_at=created,
            user_name=f"{user.name} {user.surname}".strip() if user else None,
            provider_name=provider.name if provider else None,
        )


class ReviewCreate(BaseModel):
    provider_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class ProviderAvailabilityOut(BaseModel):
    date: str
    slots: list[str]
    booked: list[str]

class ProviderBlockedTimeCreate(BaseModel):
    start_time: datetime
    end_time: datetime
    reason: Optional[str] = None

class ProviderBlockedTimeOut(BaseModel):
    id: int
    provider_id: int
    start_time: datetime
    end_time: datetime
    reason: Optional[str] = None

    model_config = {"from_attributes": True}