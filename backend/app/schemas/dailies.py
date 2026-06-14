from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

class TodoBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None

class TodoCreate(TodoBase):
    pass

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    is_completed: Optional[bool] = None
    due_date: Optional[datetime] = None

class TodoOut(TodoBase):
    id: int
    user_id: int
    is_completed: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# ── Shopping ────────────────────────────────────────────────────────────────

class ShoppingItemIn(BaseModel):
    name: str
    qty: float = 1.0
    unit: str = "dona"

class ShoppingItemFull(BaseModel):
    name: str
    qty: float = 1.0
    unit: str = "dona"
    estimated_price: float = 0.0
    unit_price: float = 0.0
    actual_price: Optional[float] = None
    is_bought: bool = False

class ShoppingListCreate(BaseModel):
    name: str = "Bozorlik"
    items: List[ShoppingItemIn]

class ShoppingListUpdate(BaseModel):
    name: Optional[str] = None
    items: Optional[List[dict]] = None
    total_estimated_price: Optional[float] = None
    total_actual_price: Optional[float] = None
    is_completed: Optional[bool] = None

class ShoppingItemPriceUpdate(BaseModel):
    item_index: int
    actual_price: Optional[float] = None
    is_bought: Optional[bool] = None

class ShoppingPriceEstimateRequest(BaseModel):
    items: List[ShoppingItemIn]

class ShoppingPriceEstimateResponse(BaseModel):
    items: List[dict]
    total_estimated_price: float

class ShoppingListOut(BaseModel):
    id: int
    user_id: int
    name: str
    items: List[dict]
    total_estimated_price: float
    total_actual_price: float
    is_completed: bool
    is_ordered: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
