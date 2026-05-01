from typing import Optional
from pydantic import BaseModel


class VariantOut(BaseModel):
    id: int
    category_id: int
    label_uz: str
    base_price: float

    model_config = {"from_attributes": True}


class CategoryOut(BaseModel):
    id: int
    key: str
    title_uz: str
    subtitle_uz: Optional[str] = None
    icon: str
    accent_color: str
    variants: list[VariantOut] = []

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    key: str
    title_uz: str
    subtitle_uz: Optional[str] = None
    icon: str
    accent_color: str = "#4285F4"


class VariantCreate(BaseModel):
    label_uz: str
    base_price: float = 0.0