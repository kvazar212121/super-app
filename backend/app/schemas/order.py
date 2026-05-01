from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class OrderCreate(BaseModel):
    category_id: int
    provider_id: int
    variant_id: Optional[int] = None
    service_name: str = Field(..., min_length=2, max_length=300)
    service_icon: Optional[str] = None
    address: str = Field(..., min_length=5, max_length=500)
    notes: Optional[str] = None
    date: datetime
    price: float = Field(..., gt=0)


class OrderOut(BaseModel):
    id: int
    user_id: int
    category_id: int
    provider_id: int
    variant_id: Optional[int] = None
    service_name: str
    service_icon: Optional[str] = None
    address: str
    notes: Optional[str] = None
    date: Optional[str] = None
    price: float
    cashback_earned: float
    status: str
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}


class OrderStatusUpdate(BaseModel):
    status: str = Field(..., pattern=r"^(confirmed|in_progress|completed|cancelled)$")