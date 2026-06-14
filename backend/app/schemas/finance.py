from datetime import datetime
from pydantic import BaseModel
from typing import Optional, List


class FinanceRecordBase(BaseModel):
    type: str  # "income" or "expense"
    amount: float
    category: str
    description: Optional[str] = None
    date: datetime


class FinanceRecordCreate(FinanceRecordBase):
    pass


class FinanceRecordUpdate(BaseModel):
    type: Optional[str] = None
    amount: Optional[float] = None
    category: Optional[str] = None
    description: Optional[str] = None
    date: Optional[datetime] = None


class FinanceRecordOut(FinanceRecordBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class FinanceCategoryStat(BaseModel):
    category: str
    amount: float
    percentage: float


class FinanceStatsOut(BaseModel):
    total_income: float
    total_expense: float
    balance: float
    category_stats: List[FinanceCategoryStat]
    insight: str
