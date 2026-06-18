from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class ProductPriceEntryOut(BaseModel):
    id: int
    product_id: int
    source_type: str
    price: float
    created_at: datetime

    class Config:
        from_attributes = True

class ProductCatalogOut(BaseModel):
    id: int
    name: str
    unit: str
    average_price: float
    created_at: datetime
    updated_at: datetime
    price_entries: List[ProductPriceEntryOut] = []

    class Config:
        from_attributes = True

class ProductCatalogCreate(BaseModel):
    name: str
    unit: str
    average_price: float = 0.0

class ProductCatalogUpdate(BaseModel):
    name: Optional[str] = None
    unit: Optional[str] = None
    average_price: Optional[float] = None

class ProductPriceEntryCreate(BaseModel):
    source_type: str
    price: float
