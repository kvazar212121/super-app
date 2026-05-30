from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class UserOut(BaseModel):
    id: int
    name: str
    surname: str
    phone: str
    avatar_url: Optional[str] = None
    telegram_username: Optional[str] = None
    balance: float
    cashback: float
    is_premium: bool
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": False}

    @classmethod
    def from_user(cls, u) -> "UserOut":
        return cls(
            id=u.id,
            name=u.name,
            surname=u.surname,
            phone=u.phone,
            avatar_url=u.avatar_url,
            telegram_username=u.telegram_username,
            balance=u.balance,
            cashback=u.cashback,
            is_premium=u.is_premium,
            created_at=u.created_at,
        )


class UserUpdate(BaseModel):
    name: Optional[str] = None
    surname: Optional[str] = None
    avatar_url: Optional[str] = None
    telegram_username: Optional[str] = None


class CardOut(BaseModel):
    id: int
    masked_number: str
    bank: str
    card_type: str
    exp_month: int
    exp_year: int
    is_default: bool

    model_config = {"from_attributes": True}


class CardCreate(BaseModel):
    masked_number: str = Field(..., min_length=16, max_length=19)
    bank: str = Field(..., min_length=2)
    card_type: str = "uzcard"
    exp_month: int = Field(..., ge=1, le=12)
    exp_year: int = Field(..., ge=2024, le=2035)


class TopUpRequest(BaseModel):
    amount: float = Field(..., gt=0)