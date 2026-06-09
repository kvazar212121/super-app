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

class ShoppingItem(BaseModel):
    name: str
    qty: float
    unit: str
    estimated_price: float = 0.0

class ShoppingListCreate(BaseModel):
    items: List[ShoppingItem]

class ShoppingListOut(BaseModel):
    id: int
    user_id: int
    items: List[dict]
    total_estimated_price: float
    is_ordered: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
