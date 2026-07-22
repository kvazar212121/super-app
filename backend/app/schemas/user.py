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
    is_premium: bool
    reminder_offset_minutes: Optional[int] = 10
    created_at: Optional[datetime] = None
    is_provider: bool = False

    model_config = {"from_attributes": False}

    @classmethod
    def from_user(cls, u) -> "UserOut":
        is_provider = False
        if hasattr(u, "providers") and u.providers:
            is_provider = len(u.providers) > 0
        elif hasattr(u, "is_provider"):
            is_provider = u.is_provider
        return cls(
            id=u.id,
            name=u.name,
            surname=u.surname,
            phone=u.phone,
            avatar_url=u.avatar_url,
            telegram_username=u.telegram_username,
            balance=u.balance,
            is_premium=u.is_premium,
            reminder_offset_minutes=getattr(u, "reminder_offset_minutes", 10),
            created_at=u.created_at,
            is_provider=is_provider,
        )


class UserUpdate(BaseModel):
    name: Optional[str] = None
    surname: Optional[str] = None
    avatar_url: Optional[str] = None
    telegram_username: Optional[str] = None
    reminder_offset_minutes: Optional[int] = None


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