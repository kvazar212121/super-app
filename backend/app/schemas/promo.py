from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional

class PromoBase(BaseModel):
    title: str = Field(..., max_length=255)
    subtitle: str = Field(..., max_length=500)
    badge: str = Field(..., max_length=50)
    colors: str = Field("#6366F1,#A855F7", max_length=255)
    image_url: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = True

class PromoCreate(PromoBase):
    pass

class PromoOut(PromoBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
