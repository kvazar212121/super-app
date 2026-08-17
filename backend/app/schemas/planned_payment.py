from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional


# Moliya yozuvlaridagi kabi chegara: manfiy yoki nolinchi rejalashtirilgan
# to'lov mantiqsiz va "qolgan to'lovlar" yig'indisini buzadi.
MAX_AMOUNT = 1_000_000_000_000


class PlannedPaymentBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    amount: float = Field(..., gt=0, le=MAX_AMOUNT)
    category: str = Field(..., min_length=1, max_length=100)
    due_date: datetime
    is_recurring: bool = False


class PlannedPaymentCreate(PlannedPaymentBase):
    pass


class PlannedPaymentUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    amount: Optional[float] = Field(default=None, gt=0, le=MAX_AMOUNT)
    category: Optional[str] = Field(default=None, min_length=1, max_length=100)
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
