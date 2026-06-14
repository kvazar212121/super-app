from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class PlannedPaymentBase(BaseModel):
    title: str
    amount: float
    category: str
    due_date: datetime
    is_recurring: bool = False


class PlannedPaymentCreate(PlannedPaymentBase):
    pass


class PlannedPaymentUpdate(BaseModel):
    title: Optional[str] = None
    amount: Optional[float] = None
    category: Optional[str] = None
    due_date: Optional[datetime] = None
    is_recurring: Optional[bool] = None
    is_paid: Optional[bool] = None
    is_notified: Optional[bool] = None


class PlannedPaymentOut(PlannedPaymentBase):
    id: int
    user_id: int
    is_paid: bool
    is_notified: bool
    created_at: datetime

    class Config:
        from_attributes = True
