from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class PlanBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: datetime


class PlanCreate(PlanBase):
    pass


class PlanUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    is_completed: Optional[bool] = None
    is_notified: Optional[bool] = None


class PlanOut(PlanBase):
    id: int
    user_id: int
    is_completed: bool
    is_notified: bool
    created_at: datetime

    class Config:
        from_attributes = True
