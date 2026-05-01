from typing import Optional
from pydantic import BaseModel, Field


class ProviderOut(BaseModel):
    id: int
    category_id: int
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

    model_config = {"from_attributes": True}


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


class ReviewOut(BaseModel):
    id: int
    user_id: int
    provider_id: int
    rating: int
    comment: Optional[str] = None
    created_at: Optional[str] = None
    user_name: Optional[str] = None

    model_config = {"from_attributes": True}


class ReviewCreate(BaseModel):
    provider_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None