from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class JobCreate(BaseModel):
    """Mijoz e'lon beradi."""

    category_id: int
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=5)
    # Upload orqali olingan URL'lar ("ish qilinadigan joyni rasmga olib")
    photos: list[str] = Field(default_factory=list)
    address: str = Field(..., min_length=3, max_length=500)
    lat: Optional[float] = None
    lng: Optional[float] = None
    # NULL = "narxni ustalar aytsin"
    budget: Optional[float] = Field(None, ge=0)
    # "qachon qilinish kerakligini yozib"
    needed_at: Optional[datetime] = None
    # Shundan keyin yangi taklif qabul qilinmaydi
    expires_at: Optional[datetime] = None


class JobOut(BaseModel):
    id: int
    user_id: int
    category_id: int
    title: str
    description: str
    photos: list[str] = Field(default_factory=list)
    address: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    budget: Optional[float] = None
    needed_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    status: str
    assigned_provider_id: Optional[int] = None
    assigned_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    offers_count: Optional[int] = None


class OfferCreate(BaseModel):
    """Usta taklif beradi."""

    # Qaysi provayder nomidan (usta bir nechta nuqtaga ega bo'lishi mumkin)
    provider_id: int
    price: float = Field(..., gt=0)
    duration_text: Optional[str] = Field(None, max_length=200)
    message: Optional[str] = None


class OfferOut(BaseModel):
    id: int
    job_id: int
    provider_id: int
    provider_name: Optional[str] = None
    provider_rating: Optional[float] = None
    provider_review_count: Optional[int] = None
    provider_phone: Optional[str] = None
    # Chat ochish uchun: mijoz shu foydalanuvchiga yozadi
    provider_owner_user_id: Optional[int] = None
    price: float
    duration_text: Optional[str] = None
    message: Optional[str] = None
    status: str
    is_seen: bool = False
    created_at: Optional[datetime] = None


class MyOfferOut(OfferOut):
    """Usta o'z takliflarini ko'rganda e'lon ma'lumoti ham keladi."""

    job: Optional[JobOut] = None
