from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class SettingsOut(BaseModel):
    commission_rate: float
    cashback_rate: float
    currency: str
    maintenance_mode: bool
    registration_open: bool
    min_withdrawal: float
    support_phone: str
    support_telegram: str


class SettingsUpdate(BaseModel):
    commission_rate: Optional[float] = None
    cashback_rate: Optional[float] = None
    currency: Optional[str] = None
    maintenance_mode: Optional[bool] = None
    registration_open: Optional[bool] = None
    min_withdrawal: Optional[float] = None
    support_phone: Optional[str] = None
    support_telegram: Optional[str] = None


DEFAULT_SETTINGS = SettingsOut(
    commission_rate=15.0,
    cashback_rate=2.0,
    currency="UZS",
    maintenance_mode=False,
    registration_open=True,
    min_withdrawal=50000.0,
    support_phone="+998 71 200 00 00",
    support_telegram="@superapp_support",
)


@router.get("/settings", response_model=SettingsOut)
async def get_settings(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return DEFAULT_SETTINGS


@router.patch("/settings", response_model=SettingsOut)
async def update_settings(
    data: SettingsUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    updated = DEFAULT_SETTINGS.model_copy(update=data.model_dump(exclude_unset=True))
    return updated
